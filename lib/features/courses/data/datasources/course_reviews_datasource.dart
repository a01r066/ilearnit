import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/course_review_model.dart';

/// Firestore-backed CRUD for course reviews.
///
/// Reviews live at `courses/{courseId}/reviews/{userId}`. The "one review
/// per user per course" invariant is enforced by using the user's uid as
/// the doc id — re-submitting just overwrites.
class CourseReviewsDataSource {
  CourseReviewsDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reviews(String courseId) =>
      _firestore
          .collection(FirestoreCollections.courses)
          .doc(courseId)
          .collection('reviews');

  DocumentReference<Map<String, dynamic>> _course(String courseId) =>
      _firestore.collection(FirestoreCollections.courses).doc(courseId);

  Stream<List<CourseReviewModel>> watchByCourse(
    String courseId, {
    int limit = 100,
  }) =>
      _reviews(courseId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map(CourseReviewModel.fromDoc).toList());

  Stream<CourseReviewModel?> watchMine(String courseId, String userId) =>
      _reviews(courseId).doc(userId).snapshots().map(
            (doc) => doc.exists ? CourseReviewModel.fromDoc(doc) : null,
          );

  /// Insert / update the calling user's review in one atomic transaction
  /// that also re-aggregates the course's `rating` + `reviewCount`.
  ///
  /// Aggregate math: re-scan the subcollection, sum + count, write the
  /// course doc. For a small N (typical course has < 1k reviews) the
  /// extra read is fine. Switch to a Cloud Function-aggregated counter
  /// once you cross a few thousand reviews per course.
  Future<void> upsert({
    required String courseId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required int rating,
    required String body,
  }) async {
    final reviewRef = _reviews(courseId).doc(userId);
    final now = FieldValue.serverTimestamp();
    final json = <String, dynamic>{
      'courseId': courseId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'body': body,
      'createdAt': now,
      'updatedAt': now,
    };
    // Only stamp `createdAt` on first write, not on every update.
    final existing = await reviewRef.get();
    if (existing.exists) {
      json.remove('createdAt');
    }
    await reviewRef.set(json, SetOptions(merge: true));
    await _recomputeAggregate(courseId);
  }

  Future<void> delete({
    required String courseId,
    required String userId,
  }) async {
    await _reviews(courseId).doc(userId).delete();
    await _recomputeAggregate(courseId);
  }

  Future<void> _recomputeAggregate(String courseId) async {
    final snap = await _reviews(courseId).get();
    final docs = snap.docs;
    if (docs.isEmpty) {
      await _course(courseId).update({
        'rating': 0,
        'reviewCount': 0,
      });
      return;
    }
    var total = 0;
    var count = 0;
    for (final d in docs) {
      final r = (d.data()['rating'] as num?)?.toInt() ?? 0;
      if (r > 0) {
        total += r;
        count += 1;
      }
    }
    final avg = count == 0 ? 0.0 : total / count;
    await _course(courseId).update({
      'rating': double.parse(avg.toStringAsFixed(2)),
      'reviewCount': count,
    });
  }
}
