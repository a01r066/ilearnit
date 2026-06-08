import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../models/course_question_model.dart';
import '../models/course_question_reply_model.dart';

/// Coordinates Firestore reads + writes for the Q&A subtree on a
/// lecture: `courses/{cid}/sections/{sid}/lectures/{lid}/questions/{qid}`
/// and its nested `replies/` subcollection.
///
/// Aggregator strategy:
/// - `replyCount` is bumped via `FieldValue.increment(1)` on every reply
///   create (and `-1` on delete). Idempotent under retries because we
///   pair the increment with the reply write in a single batch.
/// - `isInstructorAnswered` is set to `true` the moment an instructor
///   replies, never reset to `false`. (A student deleting an instructor
///   reply doesn't un-flag the question — questionable behaviour but
///   simpler, and surfaces in moderation rather than auto-revert.)
class CourseQADataSource {
  CourseQADataSource(this._firestore);

  final FirebaseFirestore _firestore;

  // ---------- Path helpers ------------------------------------------------

  DocumentReference<Map<String, dynamic>> _lecture({
    required String courseId,
    required String sectionId,
    required String lectureId,
  }) =>
      _firestore
          .collection(FirestoreCollections.courses)
          .doc(courseId)
          .collection(FirestoreCollections.sections)
          .doc(sectionId)
          .collection(FirestoreCollections.lectures)
          .doc(lectureId);

  CollectionReference<Map<String, dynamic>> _questions({
    required String courseId,
    required String sectionId,
    required String lectureId,
  }) =>
      _lecture(
        courseId: courseId,
        sectionId: sectionId,
        lectureId: lectureId,
      ).collection('questions');

  CollectionReference<Map<String, dynamic>> _replies({
    required String courseId,
    required String sectionId,
    required String lectureId,
    required String questionId,
  }) =>
      _questions(
        courseId: courseId,
        sectionId: sectionId,
        lectureId: lectureId,
      ).doc(questionId).collection('replies');

  // ---------- Reads -------------------------------------------------------

  /// Live questions list, newest first. Capped — moderators can fan out
  /// to a paginated list if a popular lecture crosses 200 questions.
  Stream<List<CourseQuestionModel>> watchQuestions({
    required String courseId,
    required String sectionId,
    required String lectureId,
    int limit = 100,
  }) =>
      _questions(
        courseId: courseId,
        sectionId: sectionId,
        lectureId: lectureId,
      )
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) =>
              snap.docs.map(CourseQuestionModel.fromDoc).toList());

  /// One-shot fetch — used by the thread page on first paint where a
  /// stream would over-fetch.
  Future<CourseQuestionModel?> fetchQuestion({
    required String courseId,
    required String sectionId,
    required String lectureId,
    required String questionId,
  }) async {
    final snap = await _questions(
      courseId: courseId,
      sectionId: sectionId,
      lectureId: lectureId,
    ).doc(questionId).get();
    if (!snap.exists) return null;
    return CourseQuestionModel.fromDoc(snap);
  }

  /// Live single question for the thread page header (reflects badge /
  /// reply-count edits in real time).
  Stream<CourseQuestionModel?> watchQuestion({
    required String courseId,
    required String sectionId,
    required String lectureId,
    required String questionId,
  }) =>
      _questions(
        courseId: courseId,
        sectionId: sectionId,
        lectureId: lectureId,
      ).doc(questionId).snapshots().map(
            (snap) =>
                snap.exists ? CourseQuestionModel.fromDoc(snap) : null,
          );

  /// Replies in chronological order (oldest first) so a thread reads
  /// like a chat log.
  Stream<List<CourseQuestionReplyModel>> watchReplies({
    required String courseId,
    required String sectionId,
    required String lectureId,
    required String questionId,
  }) =>
      _replies(
        courseId: courseId,
        sectionId: sectionId,
        lectureId: lectureId,
        questionId: questionId,
      )
          .orderBy('createdAt')
          .snapshots()
          .map((snap) =>
              snap.docs.map(CourseQuestionReplyModel.fromDoc).toList());

  // ---------- Writes ------------------------------------------------------

  /// Submit a new question. Returns the freshly-created doc id so the
  /// caller can route to it.
  Future<String> submitQuestion({
    required String courseId,
    required String sectionId,
    required String lectureId,
    required UserEntity user,
    required String body,
  }) async {
    final ref = _questions(
      courseId: courseId,
      sectionId: sectionId,
      lectureId: lectureId,
    ).doc();
    await ref.set({
      'userId': user.id,
      'userName': user.displayName ?? user.email,
      'userPhotoUrl': user.photoUrl,
      'body': body.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'replyCount': 0,
      'isInstructorAnswered': false,
    });
    return ref.id;
  }

  Future<void> editQuestion({
    required String courseId,
    required String sectionId,
    required String lectureId,
    required String questionId,
    required String body,
  }) =>
      _questions(
        courseId: courseId,
        sectionId: sectionId,
        lectureId: lectureId,
      ).doc(questionId).set(
        {
          'body': body.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  /// Hard-delete a question + nuke its replies. Author-initiated; admin
  /// moderation is a separate path.
  Future<void> deleteQuestion({
    required String courseId,
    required String sectionId,
    required String lectureId,
    required String questionId,
  }) async {
    final repliesCol = _replies(
      courseId: courseId,
      sectionId: sectionId,
      lectureId: lectureId,
      questionId: questionId,
    );
    final snap = await repliesCol.limit(200).get();
    final batch = _firestore.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_questions(
      courseId: courseId,
      sectionId: sectionId,
      lectureId: lectureId,
    ).doc(questionId));
    await batch.commit();
  }

  /// Submit a reply.
  ///
  /// `isInstructor` should be set by the caller after checking
  /// `course.instructorId == user.id` (or the user's `role == admin`).
  /// The flag drives both the verified badge AND the
  /// `isInstructorAnswered` aggregator on the parent question.
  Future<String> submitReply({
    required String courseId,
    required String sectionId,
    required String lectureId,
    required String questionId,
    required UserEntity user,
    required bool isInstructor,
    required String body,
  }) async {
    final questionRef = _questions(
      courseId: courseId,
      sectionId: sectionId,
      lectureId: lectureId,
    ).doc(questionId);
    final replyRef = questionRef.collection('replies').doc();

    final batch = _firestore.batch();
    batch.set(replyRef, {
      'userId': user.id,
      'userName': user.displayName ?? user.email,
      'userPhotoUrl': user.photoUrl,
      'body': body.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isInstructor': isInstructor,
    });

    final questionUpdate = <String, dynamic>{
      'replyCount': FieldValue.increment(1),
    };
    if (isInstructor) {
      questionUpdate['isInstructorAnswered'] = true;
    }
    batch.set(questionRef, questionUpdate, SetOptions(merge: true));

    await batch.commit();
    return replyRef.id;
  }

  Future<void> editReply({
    required String courseId,
    required String sectionId,
    required String lectureId,
    required String questionId,
    required String replyId,
    required String body,
  }) =>
      _replies(
        courseId: courseId,
        sectionId: sectionId,
        lectureId: lectureId,
        questionId: questionId,
      ).doc(replyId).set(
        {
          'body': body.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  /// Hard-delete a reply + decrement the parent's `replyCount`. We
  /// deliberately do NOT reset `isInstructorAnswered` even when the
  /// last instructor reply is removed — the badge survives the delete
  /// to deter score-chasing manipulation.
  Future<void> deleteReply({
    required String courseId,
    required String sectionId,
    required String lectureId,
    required String questionId,
    required String replyId,
  }) async {
    final questionRef = _questions(
      courseId: courseId,
      sectionId: sectionId,
      lectureId: lectureId,
    ).doc(questionId);
    final replyRef =
        questionRef.collection('replies').doc(replyId);

    final batch = _firestore.batch();
    batch.delete(replyRef);
    batch.set(
      questionRef,
      {'replyCount': FieldValue.increment(-1)},
      SetOptions(merge: true),
    );
    await batch.commit();
  }
}
