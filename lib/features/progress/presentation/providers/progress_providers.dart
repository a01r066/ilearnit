import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../app_rating/presentation/providers/app_rating_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/lecture_progress_datasource.dart';
import '../../data/models/course_progress_model.dart';
import '../../data/models/lecture_progress_model.dart';
import 'lecture_progress_notifier.dart';
import 'lecture_progress_state.dart';

/// Singleton datasource.
final lectureProgressDataSourceProvider =
    Provider<LectureProgressDataSource>(
  (ref) => LectureProgressDataSource(ref.watch(firestoreProvider)),
);

/// Stream the per-course rollup so the course detail page can show a
/// LinearProgressIndicator + Resume CTA.
///
/// Family argument: courseId. Auto-disposed because we only need it while
/// the detail page is mounted.
final courseProgressSummaryProvider = StreamProvider.autoDispose
    .family<CourseProgressModel?, String>((ref, courseId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref
      .watch(lectureProgressDataSourceProvider)
      .watchCourseSummary(userId: user.id, courseId: courseId);
});

/// Stream the per-lecture progress rows so the curriculum can render
/// completion checkmarks + per-lecture position.
final lectureProgressByCourseProvider = StreamProvider.autoDispose
    .family<List<LectureProgressModel>, String>((ref, courseId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref
      .watch(lectureProgressDataSourceProvider)
      .watchCourseLectureProgress(userId: user.id, courseId: courseId);
});

/// Stream the N most recently watched courses for the Home "Continue
/// learning" rail.
final continueLearningProvider = StreamProvider.autoDispose
    .family<List<CourseProgressModel>, int>((ref, limit) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref
      .watch(lectureProgressDataSourceProvider)
      .watchInProgressCourses(userId: user.id, limit: limit);
});

/// Compound argument for the per-(course, lecture) writer notifier.
class LectureProgressKey {
  const LectureProgressKey({
    required this.courseId,
    required this.lectureId,
  });
  final String courseId;
  final String lectureId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LectureProgressKey &&
          other.courseId == courseId &&
          other.lectureId == lectureId);

  @override
  int get hashCode => Object.hash(courseId, lectureId);
}

/// A registry that lets the LecturePlayerPage hand the notifier a fresh
/// `CourseMetaSnapshot` on every flush without exposing a mutable provider.
///
/// The page writes to this map in `initState` (and on curriculum reload)
/// so the notifier always sees the latest title / cover / totalLectures
/// when it constructs the rollup payload.
class _MetaRegistry {
  final Map<String, CourseMetaSnapshot> _byCourseId = {};

  void put(String courseId, CourseMetaSnapshot meta) {
    _byCourseId[courseId] = meta;
  }

  CourseMetaSnapshot get(String courseId) {
    return _byCourseId[courseId] ??
        const CourseMetaSnapshot(title: '', totalLectures: 0);
  }
}

final progressMetaRegistryProvider =
    Provider<_MetaRegistry>((_) => _MetaRegistry());

/// The notifier that actually drives Firestore writes during playback.
///
/// AutoDispose: we want it torn down when the player route is popped, so
/// the final `dispose()` flush is the last write.
final lectureProgressNotifierProvider = StateNotifierProvider.autoDispose
    .family<LectureProgressNotifier, LectureProgressState, LectureProgressKey>(
  (ref, key) {
    final user = ref.watch(currentUserProvider);
    final registry = ref.watch(progressMetaRegistryProvider);
    final rating = ref.watch(appRatingNotifierProvider);

    // "Natural moment" hook: bump the rating counter + maybe prompt.
    // Done as a fire-and-forget; the rating service handles all the
    // gating internally so we don't need to add another conditional
    // here.
    void onCompleted() {
      // ignore: discarded_futures — fire-and-forget by design.
      rating.recordCompletedLecture();
    }

    // A guest user shouldn't reach the player at all (gated upstream),
    // but defensively return a no-op notifier so we don't NPE.
    if (user == null) {
      return LectureProgressNotifier(
        datasource: ref.watch(lectureProgressDataSourceProvider),
        userId: '',
        courseId: key.courseId,
        lectureId: key.lectureId,
        metaProvider: () => registry.get(key.courseId),
      );
    }
    return LectureProgressNotifier(
      datasource: ref.watch(lectureProgressDataSourceProvider),
      userId: user.id,
      courseId: key.courseId,
      lectureId: key.lectureId,
      metaProvider: () => registry.get(key.courseId),
      onLectureCompleted: onCompleted,
    );
  },
);
