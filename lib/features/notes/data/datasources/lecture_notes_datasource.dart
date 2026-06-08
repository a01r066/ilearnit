import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lecture_note_model.dart';

/// Coordinates Firestore reads + writes for the private notes tree:
/// `users/{uid}/notes/{noteId}`.
///
/// Notes are owner-only — they do not appear in any global query. We
/// chose `users/{uid}/notes` over `courses/{cid}/.../notes` because:
///
///   1. The "My notes" page on the profile tab needs a single
///      cross-course query, which the lectures subtree wouldn't allow
///      without a collectionGroup query (and a composite index).
///   2. Account deletion only has to nuke one subcollection.
///   3. Firestore rules are trivial — owner only, period.
///
/// The trade-off is that we denormalize course / lecture metadata
/// (`courseTitle`, `courseThumbnailUrl`, `lectureTitle`) on every
/// write. A course rename won't propagate to existing notes. We
/// consider that acceptable: notes are personal mnemonics, not search
/// indexes.
class LectureNotesDataSource {
  LectureNotesDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  // ---------- Path helpers ------------------------------------------------

  CollectionReference<Map<String, dynamic>> _notes(String userId) =>
      _firestore.collection('users').doc(userId).collection('notes');

  // ---------- Reads -------------------------------------------------------

  /// Live notes for a single lecture, newest first. The Q&A section
  /// and the "Notes" panel in the lecture body both consume this.
  Stream<List<LectureNoteModel>> watchByLecture({
    required String userId,
    required String courseId,
    required String lectureId,
  }) =>
      _notes(userId)
          .where('courseId', isEqualTo: courseId)
          .where('lectureId', isEqualTo: lectureId)
          .orderBy('timestampSec')
          // Mixing nulls + ints in the same orderBy is fine; Firestore
          // places nulls first which surfaces "general" (no-timestamp)
          // notes above timestamped ones — reasonable default.
          .snapshots()
          .map((snap) => snap.docs.map(LectureNoteModel.fromDoc).toList());

  /// Live notes across every course the user has touched. Backs the
  /// standalone "My notes" page on the profile tab. Newest first.
  Stream<List<LectureNoteModel>> watchAll({
    required String userId,
    int limit = 200,
  }) =>
      _notes(userId)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs.map(LectureNoteModel.fromDoc).toList());

  // ---------- Writes ------------------------------------------------------

  /// Create a new note. Returns the new doc id.
  Future<String> create({
    required String userId,
    required String courseId,
    required String courseTitle,
    String? courseThumbnailUrl,
    required String sectionId,
    required String lectureId,
    required String lectureTitle,
    required String body,
    int? timestampSec,
  }) async {
    final ref = _notes(userId).doc();
    await ref.set({
      'userId': userId,
      'courseId': courseId,
      'courseTitle': courseTitle,
      if (courseThumbnailUrl != null)
        'courseThumbnailUrl': courseThumbnailUrl,
      'sectionId': sectionId,
      'lectureId': lectureId,
      'lectureTitle': lectureTitle,
      'body': body.trim(),
      'timestampSec': timestampSec,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Edit an existing note's body and/or timestamp.
  Future<void> update({
    required String userId,
    required String noteId,
    String? body,
    int? timestampSec,
    bool clearTimestamp = false,
  }) {
    final patch = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (body != null) patch['body'] = body.trim();
    if (clearTimestamp) {
      patch['timestampSec'] = null;
    } else if (timestampSec != null) {
      patch['timestampSec'] = timestampSec;
    }
    return _notes(userId).doc(noteId).set(patch, SetOptions(merge: true));
  }

  Future<void> delete({
    required String userId,
    required String noteId,
  }) =>
      _notes(userId).doc(noteId).delete();
}
