import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../features/auth/data/models/user_model.dart';
import '../../../features/courses/data/models/course_model.dart';
import '../../../features/courses/data/models/course_section_model.dart';
import '../../../features/courses/data/models/lecture_model.dart';
import 'cloudflare_upload_service.dart';

/// Admin/instructor side of the courses data layer.
///
/// Reuses [CourseModel] / [CourseSectionModel] / [LectureModel] so the wire
/// format is identical to what the consumer mobile app reads. The only
/// difference: this datasource exposes mutations the mobile app doesn't
/// need (create/update/delete) and admin-scoped queries (list all, list
/// by instructor).
class AdminCoursesDataSource {
  AdminCoursesDataSource({
    required FirebaseFirestore firestore,
    FirebaseStorage? storage,
    CloudflareUploadService? cloudflare,
  })  : _firestore = firestore,
        _storage = storage ?? FirebaseStorage.instance,
        _cloudflare = cloudflare ?? CloudflareUploadService();

  final FirebaseFirestore _firestore;
  // Optional deps for the cascade-cleanup that `deleteLecture` runs.
  // Injected so a unit test can verify the cleanup sequence without
  // hitting real Storage / Cloud Functions.
  final FirebaseStorage _storage;
  final CloudflareUploadService _cloudflare;

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection(FirestoreCollections.courses);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> _sections(String courseId) =>
      _courses.doc(courseId).collection(FirestoreCollections.sections);

  CollectionReference<Map<String, dynamic>> _lectures(
    String courseId,
    String sectionId,
  ) =>
      _sections(courseId)
          .doc(sectionId)
          .collection(FirestoreCollections.lectures);

  // ---------- Course queries ----------------------------------------------

  /// Stream every course in the system. Admin-only.
  Stream<List<CourseModel>> watchAllCourses() => _courses
      .orderBy('publishedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(CourseModel.fromDoc).toList());

  /// Stream the courses owned by [instructorId]. Used by the instructor's
  /// "My Courses" page.
  Stream<List<CourseModel>> watchMyCourses(String instructorId) => _courses
      .where('instructorId', isEqualTo: instructorId)
      .snapshots()
      .map((s) => s.docs.map(CourseModel.fromDoc).toList());

  /// Stream a single course doc.
  Stream<CourseModel?> watchCourse(String courseId) =>
      _courses.doc(courseId).snapshots().map(
            (doc) => doc.exists ? CourseModel.fromDoc(doc) : null,
          );

  // ---------- Course mutations --------------------------------------------

  /// Create a new course. Returns the generated id. The caller is responsible
  /// for setting `instructorId` / `instructorName` correctly.
  Future<String> createCourse(CourseModel model) async {
    final doc = _courses.doc();
    final withId = model.copyWith(id: doc.id);
    final json = withId.toJson();
    // Don't persist the id inside the doc body — it's already the doc id.
    json.remove('id');
    json['createdAt'] = FieldValue.serverTimestamp();
    await doc.set(json);
    return doc.id;
  }

  Future<void> updateCourse(CourseModel model) async {
    final json = model.toJson();
    json.remove('id');
    json['updatedAt'] = FieldValue.serverTimestamp();
    await _courses.doc(model.id).update(json);
  }

  /// Hard-delete a course and all of its sections / lectures. Admin-only —
  /// instructors should soft-delete or unpublish in production.
  Future<void> deleteCourse(String courseId) async {
    final sectionsSnap = await _sections(courseId).get();
    for (final section in sectionsSnap.docs) {
      final lecturesSnap = await _lectures(courseId, section.id).get();
      for (final lecture in lecturesSnap.docs) {
        await lecture.reference.delete();
      }
      await section.reference.delete();
    }
    await _courses.doc(courseId).delete();
  }

  Future<void> setFeatured(String courseId, bool featured) =>
      _courses.doc(courseId).update({'isFeatured': featured});

  // ---------- Sections ----------------------------------------------------

  Stream<List<CourseSectionModel>> watchSections(String courseId) =>
      _sections(courseId).orderBy('order').snapshots().map(
            (s) => s.docs.map(CourseSectionModel.fromDoc).toList(),
          );

  Future<String> createSection({
    required String courseId,
    required String title,
    required int order,
  }) async {
    final doc = _sections(courseId).doc();
    await doc.set({
      'title': title,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateSection({
    required String courseId,
    required String sectionId,
    required String title,
    required int order,
  }) =>
      _sections(courseId).doc(sectionId).update({
        'title': title,
        'order': order,
      });

  /// Thrown by [deleteSection] when the target section still owns one
  /// or more lectures. The admin UI catches this and surfaces it as a
  /// friendly "delete the lectures first" message instead of a stack
  /// trace.
  static const sectionNotEmptyError =
      'Section is not empty. Delete each lecture first so the per-'
      'lecture cleanup (Cloudflare video, Storage files, Q&A, notes, '
      'reports) runs against each one. Then re-try the section delete.';

  /// Delete an empty section. Refuses to delete a section that still
  /// owns lectures — the previous behaviour quietly iterated `delete()`
  /// over every lecture doc, which bypassed the full cascade
  /// (`deleteLecture` runs Cloudflare, Storage, Q&A, and triggers
  /// `onLectureDeleted` for the per-user cleanup). Orphaned Cloudflare
  /// videos + Storage files were the actual cost. Forcing the admin
  /// to delete lectures one-by-one routes every one through the
  /// proper teardown.
  ///
  /// Uses the cheap `count()` aggregation instead of fetching every
  /// lecture doc — costs ~1 read regardless of section size.
  Future<void> deleteSection({
    required String courseId,
    required String sectionId,
  }) async {
    final agg = await _lectures(courseId, sectionId).count().get();
    final count = agg.count ?? 0;
    if (count > 0) {
      throw StateError(sectionNotEmptyError);
    }
    await _sections(courseId).doc(sectionId).delete();
  }

  // ---------- Lectures ----------------------------------------------------

  Stream<List<LectureModel>> watchLectures({
    required String courseId,
    required String sectionId,
  }) =>
      _lectures(courseId, sectionId).orderBy('order').snapshots().map(
            (s) => s.docs.map((d) {
              final data = d.data();
              return LectureModel.fromJson({...data, 'id': d.id});
            }).toList(),
          );

  Future<String> createLecture({
    required String courseId,
    required String sectionId,
    required LectureModel lecture,
  }) async {
    final doc = _lectures(courseId, sectionId).doc();
    final json = lecture.toJson();
    json.remove('id');
    json['createdAt'] = FieldValue.serverTimestamp();
    await doc.set(json);
    return doc.id;
  }

  Future<void> updateLecture({
    required String courseId,
    required String sectionId,
    required LectureModel lecture,
  }) async {
    final json = lecture.toJson();
    json.remove('id');
    await _lectures(courseId, sectionId).doc(lecture.id).update(json);
  }

  /// Delete a lecture AND cascade-clean its associated media:
  ///
  ///   1. Read the doc first so we have `cloudflareVideoId`,
  ///      `mediaUrl`, and `resources[*].url`.
  ///   2. Delete the Cloudflare Stream video (if any). Idempotent —
  ///      the server treats 404 as success.
  ///   3. Delete the legacy Firebase Storage media (if any).
  ///   4. Delete each Firebase Storage resource URL.
  ///   5. Delete the Firestore doc last.
  ///
  /// Steps 2–4 are **best-effort**. A single failed Storage delete
  /// (e.g. the file was already removed manually, the URL is malformed
  /// from legacy data) MUST NOT block the Firestore delete — otherwise
  /// the admin gets stuck with a row that can't be removed. Failures
  /// are logged via the cloud-functions/print path and the doc delete
  /// proceeds anyway.
  ///
  /// **What doesn't get cleaned up** — sub-collections under the
  /// lecture (progress rollups, etc.) and any aggregated counters on
  /// the parent course/section docs. Those are out of scope for this
  /// method and would warrant a Cloud Function trigger if needed.
  Future<void> deleteLecture({
    required String courseId,
    required String sectionId,
    required String lectureId,
  }) async {
    final docRef = _lectures(courseId, sectionId).doc(lectureId);

    // Step 1 — read first. If the doc is gone already, there's nothing
    // to cascade-clean; bail out early without surfacing an error.
    final snap = await docRef.get();
    if (!snap.exists) return;
    LectureModel? lecture;
    try {
      final data = snap.data() ?? <String, dynamic>{};
      lecture = LectureModel.fromJson({...data, 'id': snap.id});
    } catch (e) {
      // Corrupt doc — we can still delete it. Just skip the cascade.
      // ignore: avoid_print
      print('deleteLecture: could not parse lecture $lectureId: $e');
    }

    if (lecture != null) {
      // Step 2 — Cloudflare. `deleteVideo` swallows-and-logs on
      // failure, so a Cloudflare API hiccup doesn't surface here.
      final cfId = lecture.cloudflareVideoId;
      if (cfId != null && cfId.isNotEmpty) {
        await _cloudflare.deleteVideo(cfId);
      }

      // Step 3 — legacy Storage media file. Fire-and-forget pattern:
      // collect the futures + await them in a single `Future.wait`
      // with `eagerError: false` so one failure doesn't cancel the
      // others.
      final cleanupFutures = <Future<void>>[];
      final media = lecture.mediaUrl;
      if (media != null && media.isNotEmpty) {
        cleanupFutures.add(_safeDeleteStorageUrl(media));
      }

      // Step 4 — every supplementary resource.
      for (final r in lecture.resources) {
        if (r.url.isNotEmpty) {
          cleanupFutures.add(_safeDeleteStorageUrl(r.url));
        }
      }

      if (cleanupFutures.isNotEmpty) {
        await Future.wait(cleanupFutures, eagerError: false);
      }
    }

    // Step 5 — Q&A subcollection cascade (questions + their nested
    // replies). Best-effort; failures are logged + we keep going.
    // The `onLectureDeleted` Cloud Function trigger runs the same
    // cascade with Admin SDK privileges as a backstop, so anything
    // we miss here gets caught server-side within seconds.
    await _safeDeleteQa(courseId, sectionId, lectureId);

    // Step 6 — final Firestore delete.
    await docRef.delete();
  }

  /// Recursively delete `…/lectures/{lid}/questions/{qid}` and every
  /// `replies/{rid}` underneath. Batched in chunks of 500 (Firestore's
  /// per-batch write ceiling). Each failure is caught + logged so the
  /// rest of the cascade continues.
  ///
  /// **Why client-side AND Cloud-Function-side.** The trigger is the
  /// authoritative pass (Admin SDK, no rules, idempotent on already-
  /// empty subcollections), but doing it here gives the admin an
  /// immediate visual "questions are gone" while the trigger settles.
  Future<void> _safeDeleteQa(
    String courseId,
    String sectionId,
    String lectureId,
  ) async {
    try {
      final questionsRef = _lectures(courseId, sectionId)
          .doc(lectureId)
          .collection('questions');

      // First fetch all question docs. For typical lecture sizes
      // (dozens of questions, not thousands) this is one round-trip.
      final qSnap = await questionsRef.get();
      if (qSnap.docs.isEmpty) return;

      for (final q in qSnap.docs) {
        // Each question's replies are also a subcollection. Page
        // through them in chunks of 500 so an enormous reply thread
        // doesn't exceed Firestore's batch limit.
        final repliesRef = q.reference.collection('replies');
        await _deleteCollectionInBatches(repliesRef);

        // Finally delete the question doc itself.
        try {
          await q.reference.delete();
        } catch (e) {
          // ignore: avoid_print
          print('deleteLecture: question delete failed (${q.id}): $e');
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('deleteLecture: Q&A cascade failed for $lectureId: $e');
    }
  }

  /// Pages through every doc in [col] and deletes them via batched
  /// commits. Each batch is at most 500 ops (the Firestore ceiling).
  /// Stops when a page returns fewer than [pageSize] docs, indicating
  /// we've drained the collection.
  Future<void> _deleteCollectionInBatches(
    CollectionReference<Map<String, dynamic>> col, {
    int pageSize = 200,
  }) async {
    while (true) {
      final QuerySnapshot<Map<String, dynamic>> snap =
          await col.limit(pageSize).get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      try {
        await batch.commit();
      } catch (e) {
        // ignore: avoid_print
        print(
            'deleteLecture: batch delete in ${col.path} failed: $e — stopping.');
        return;
      }
      // Less than pageSize → collection drained.
      if (snap.docs.length < pageSize) return;
    }
  }

  /// Best-effort `FirebaseStorage.refFromURL(url).delete()`. Swallows
  /// any exception so a single bad URL doesn't fail the cascade.
  /// `refFromURL` is the canonical way to map an https
  /// `firebasestorage.googleapis.com/...?alt=media&token=...` URL
  /// back to a `Reference` we can call `.delete()` on.
  Future<void> _safeDeleteStorageUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      // Common causes: file was already deleted manually, URL was
      // synthetic / generated outside Storage (legacy data), or the
      // bucket name in the URL doesn't match the current FirebaseApp.
      // Log + move on so other deletes still run.
      // ignore: avoid_print
      print('deleteLecture: storage delete failed for $url: $e');
    }
  }

  /// Atomically swap the `order` field between two lectures in the
  /// same section. Used by the up/down reorder buttons in the
  /// curriculum editor — one batch write, one Firestore round-trip,
  /// no intermediate state where two lectures share the same order
  /// value (which would otherwise scramble the `.orderBy('order')`
  /// stream listeners during the in-between frame).
  // ---------- Status workflow ---------------------------------------------

  /// Mutates a course's `status` field. Side effects on specific
  /// transitions:
  ///   • `→ published`   stamps `publishedAt` if it isn't set yet
  ///                     (idempotent — re-publishing keeps the
  ///                     original go-live date).
  ///   • `→ archived`    stamps `archivedAt` with `now`.
  ///   • `→ draft`       clears `archivedAt` so resurrected courses
  ///                     don't read as still-archived.
  ///
  /// Caller is responsible for confirming the transition is legal —
  /// see `CourseStatus.allowedNextStates(role)`. We don't re-check
  /// here because admin/instructor calls funnel through different UI
  /// surfaces that already gate on role.
  Future<void> updateCourseStatus({
    required String courseId,
    required String status,
  }) async {
    final patch = <String, dynamic>{'status': status};
    if (status == 'published') {
      patch['publishedAt'] = FieldValue.serverTimestamp();
    } else if (status == 'archived') {
      patch['archivedAt'] = FieldValue.serverTimestamp();
    } else if (status == 'draft') {
      patch['archivedAt'] = FieldValue.delete();
    }
    await _courses.doc(courseId).set(patch, SetOptions(merge: true));
  }

  Future<void> swapLectureOrder({
    required String courseId,
    required String sectionId,
    required String aId,
    required int aOrder,
    required String bId,
    required int bOrder,
  }) async {
    if (aId == bId || aOrder == bOrder) return;
    final batch = _firestore.batch();
    batch.update(
      _lectures(courseId, sectionId).doc(aId),
      {'order': bOrder},
    );
    batch.update(
      _lectures(courseId, sectionId).doc(bId),
      {'order': aOrder},
    );
    await batch.commit();
  }

  // ---------- User / instructor queries (admin-only) ----------------------

  /// Stream every user with role `instructor`. Admin uses this to manage
  /// active instructors.
  Stream<List<UserModel>> watchInstructors() => _users
      .where('role', isEqualTo: 'instructor')
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromDoc).toList());

  /// Set the suspension flag on a user. Suspended instructors lose write
  /// access (enforced by Firestore rules; the rule snippets are in
  /// `docs/admin_portal.md`).
  Future<void> setUserSuspended({
    required String userId,
    required bool suspended,
  }) =>
      _users.doc(userId).update({'isSuspended': suspended});

  /// Force-revoke instructor role (sends the user back to `student`).
  Future<void> revokeInstructorRole(String userId) =>
      _users.doc(userId).update({'role': 'student'});

  /// Look up a single user by uid.
  Future<UserModel?> fetchUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromDoc(snap);
  }

  Stream<UserModel?> watchUser(String uid) =>
      _users.doc(uid).snapshots().map(
            (doc) => doc.exists ? UserModel.fromDoc(doc) : null,
          );
}
