import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/course_progress_model.dart';
import '../models/lecture_progress_model.dart';

/// Snapshot of a course write that the lecture-progress notifier sends with
/// every upsert. The denormalized fields are written onto the rollup doc so
/// the Home "Continue learning" rail can render with no N+1 join.
class CourseMetaSnapshot {
  const CourseMetaSnapshot({
    required this.title,
    required this.totalLectures,
    this.thumbnailUrl,
    this.sectionId,
  });

  final String title;
  final int totalLectures;
  final String? thumbnailUrl;
  final String? sectionId;
}

/// Persistence for `users/{uid}/courseProgress/{courseId}` and its
/// `/lectures/{lectureId}` subcollection.
class LectureProgressDataSource {
  LectureProgressDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _courseProgressCol(String userId) =>
      _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection('courseProgress');

  DocumentReference<Map<String, dynamic>> _courseDoc(
    String userId,
    String courseId,
  ) =>
      _courseProgressCol(userId).doc(courseId);

  CollectionReference<Map<String, dynamic>> _lecturesCol(
    String userId,
    String courseId,
  ) =>
      _courseDoc(userId, courseId).collection('lectures');

  /// Upsert one lecture's progress + the parent rollup in a single batch.
  ///
  /// Idempotent: callers may invoke this every 10 seconds during playback
  /// without risk of double-incrementing `completedCount`. Completion is
  /// transitioned exactly once by comparing the previous `completed` value
  /// before the write.
  Future<void> upsertLectureProgress({
    required String userId,
    required String courseId,
    required String lectureId,
    required int positionSec,
    required int durationSec,
    required bool completed,
    required CourseMetaSnapshot meta,
  }) async {
    final lectureRef = _lecturesCol(userId, courseId).doc(lectureId);
    final courseRef = _courseDoc(userId, courseId);

    // Read the existing lecture doc so we can transition `completed`
    // exactly once. Without this we'd risk decrementing on a regression
    // (player rewinds to 0).
    final prev = await lectureRef.get();
    final wasCompleted = (prev.data()?['completed'] as bool?) ?? false;
    final transitioningToCompleted = !wasCompleted && completed;

    final batch = _firestore.batch();

    // Per-lecture row.
    batch.set(
      lectureRef,
      {
        'positionSec': positionSec,
        'durationSec': durationSec,
        'completed': completed,
        'lastWatchedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Parent rollup. We use field-level merges + FieldValue.increment so we
    // don't have to read-then-write the parent on every tick.
    final rollupPayload = <String, dynamic>{
      'courseId': courseId,
      'title': meta.title,
      'thumbnailUrl': meta.thumbnailUrl,
      'lastWatchedLectureId': lectureId,
      'lastWatchedSectionId': meta.sectionId,
      'lastWatchedAt': FieldValue.serverTimestamp(),
      'totalLectures': meta.totalLectures,
    };
    if (transitioningToCompleted) {
      rollupPayload['completedCount'] = FieldValue.increment(1);
    }
    batch.set(courseRef, rollupPayload, SetOptions(merge: true));

    await batch.commit();
  }

  /// Mark a single lecture as completed without changing the play-head.
  /// Used by the "Mark complete" overflow action.
  Future<void> markLectureCompleted({
    required String userId,
    required String courseId,
    required String lectureId,
    required CourseMetaSnapshot meta,
  }) async {
    await upsertLectureProgress(
      userId: userId,
      courseId: courseId,
      lectureId: lectureId,
      positionSec: 0,
      durationSec: 0,
      completed: true,
      meta: meta,
    );
  }

  /// Live stream of every lecture-progress row for a single course. Used by
  /// the course-detail curriculum to render per-lecture checkmarks.
  Stream<List<LectureProgressModel>> watchCourseLectureProgress({
    required String userId,
    required String courseId,
  }) =>
      _lecturesCol(userId, courseId).snapshots().map(
            (snap) =>
                snap.docs.map(LectureProgressModel.fromDoc).toList(),
          );

  /// Live stream of the rollup. Course detail uses this for the progress
  /// bar + "Resume" CTA.
  Stream<CourseProgressModel?> watchCourseSummary({
    required String userId,
    required String courseId,
  }) =>
      _courseDoc(userId, courseId).snapshots().map(
            (snap) =>
                snap.exists ? CourseProgressModel.fromDoc(snap) : null,
          );

  /// Live stream of the N most recently watched courses for the Home rail.
  Stream<List<CourseProgressModel>> watchInProgressCourses({
    required String userId,
    int limit = 5,
  }) =>
      _courseProgressCol(userId)
          .orderBy('lastWatchedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map(CourseProgressModel.fromDoc).toList(),
          );

  /// One-shot read of the current rollup. Used by `markLectureCompleted`
  /// callers + by integration tests.
  Future<CourseProgressModel?> readCourseSummary({
    required String userId,
    required String courseId,
  }) async {
    final snap = await _courseDoc(userId, courseId).get();
    if (!snap.exists) return null;
    return CourseProgressModel.fromDoc(snap);
  }
}
