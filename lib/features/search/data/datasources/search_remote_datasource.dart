import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../courses/domain/entities/instrument_category.dart';
import '../../domain/entities/search_filter.dart';

/// Reads the `courses` collection and performs substring matching for the
/// search experience.
///
/// Firestore doesn't support full-text search natively. For a small/medium
/// catalogue this brute-forces it in memory: pull the full active course
/// list once, then filter / score by query string client-side. For a larger
/// catalogue, swap this for Algolia, Typesense, or Firestore's
/// "search_terms" array-contains pattern.
class SearchRemoteDataSource {
  SearchRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection(FirestoreCollections.courses);

  /// Pull the full catalogue (capped). The notifier filters / sorts in
  /// memory — fast enough for hundreds of courses.
  Future<List<CourseModel>> fetchAllCourses({int limit = 200}) async {
    final snap = await _courses
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(CourseModel.fromDoc).toList();
  }

  /// In-memory search + filter. The notifier debounces; this just scores.
  ///
  /// Scoring:
  ///   +5  title exact-prefix match
  ///   +3  title substring match
  ///   +2  tag substring match
  ///   +1  instructorName substring match
  ///   +1  summary substring match
  ///
  /// Ties broken by enrollmentCount descending.
  List<CourseModel> rankAndFilter({
    required List<CourseModel> all,
    required String query,
    required SearchFilter filter,
  }) {
    final q = query.trim().toLowerCase();
    final withScore = <_Scored>[];

    for (final c in all) {
      // Apply filter facets first — they short-circuit before scoring.
      if (filter.categories.isNotEmpty &&
          !filter.categories
              .any((cat) => cat.id == c.category)) {
        continue;
      }
      if (filter.levels.isNotEmpty &&
          !filter.levels.any((lvl) => lvl.id == c.level)) {
        continue;
      }
      if (filter.minRating > 0 && c.rating < filter.minRating) continue;
      // priceTier maps to VND fallback via PriceTier — apply a coarse cap.
      if (filter.maxPriceVnd != null) {
        final vnd = _vndForTier(c.priceTier);
        if (vnd > filter.maxPriceVnd!) continue;
      }

      // Empty query → no scoring, just inclusion.
      if (q.isEmpty) {
        withScore.add(_Scored(c, 0));
        continue;
      }

      var score = 0;
      final title = c.title.toLowerCase();
      if (title.startsWith(q)) {
        score += 5;
      } else if (title.contains(q)) {
        score += 3;
      }
      for (final tag in c.tags) {
        if (tag.toLowerCase().contains(q)) {
          score += 2;
          break;
        }
      }
      if (c.instructorName.toLowerCase().contains(q)) score += 1;
      if (c.summary.toLowerCase().contains(q)) score += 1;

      if (score > 0) withScore.add(_Scored(c, score));
    }

    withScore.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.course.enrollmentCount.compareTo(a.course.enrollmentCount);
    });

    return withScore.map((s) => s.course).toList();
  }

  /// Coarse VND mapping for the price-cap filter. Mirrors the labels used
  /// elsewhere (see `PriceTier.rawFallbackPrice`).
  int _vndForTier(String tierId) {
    switch (tierId) {
      case 'basic':
        return 199000;
      case 'standard':
        return 399000;
      case 'premium':
        return 799000;
      default:
        return 0;
    }
  }
}

class _Scored {
  const _Scored(this.course, this.score);
  final CourseModel course;
  final int score;
}

/// Static catalogue of common search keywords used as a backbone for
/// suggestions before the user has any search history. Live courses from
/// the catalogue are layered on top in the notifier.
class StaticSearchKeywords {
  const StaticSearchKeywords._();

  static const List<String> all = [
    'fingerstyle guitar',
    'acoustic guitar fingerstyle',
    'fingerstyle',
    'ukulele fingerstyle',
    'classical guitar',
    'piano for beginners',
    'jazz piano',
    'violin lessons',
    'music theory',
    'sight reading',
    'ear training',
    'sheet music',
  ];

  /// Return keywords containing [query] (case-insensitive), in declared
  /// order, capped at [limit].
  static List<String> matching(String query, {int limit = 4}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all.take(limit).toList();
    return all
        .where((k) => k.toLowerCase().contains(q))
        .take(limit)
        .toList();
  }

  /// Domain helper — convert an [InstrumentCategory] into its default
  /// keyword (e.g. guitar → "guitar lessons").
  static String forCategory(InstrumentCategory c) {
    switch (c) {
      case InstrumentCategory.guitar:
        return 'guitar lessons';
      case InstrumentCategory.piano:
        return 'piano lessons';
      case InstrumentCategory.violin:
        return 'violin lessons';
    }
  }
}
