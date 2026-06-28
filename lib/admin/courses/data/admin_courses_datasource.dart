import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../features/auth/data/models/user_model.dart';
import '../../../features/courses/data/models/course_model.dart';
import '../../../features/courses/data/models/course_section_model.dart';
import '../../../features/courses/data/models/lecture_model.dart';

/// Admin/instructor side of the courses data layer.
///
/// Reuses [CourseModel] / [CourseSectionModel] / [LectureModel] so the wire
/// format is identical to what the consumer mobile app reads. The only
/// difference: this datasource exposes mutations the mobile app doesn't
/// need (create/update/delete) and admin-scoped queries (list all, list
/// by instructor).
class AdminCoursesDataSource {
  AdminCoursesDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

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

  Future<void> deleteSection({
    required String courseId,
    required String sectionId,
  }) async {
    final lecturesSnap = await _lectures(courseId, sectionId).get();
    for (final l in lecturesSnap.docs) {
      await l.reference.delete();
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

  Future<void> deleteLecture({
    required String courseId,
    required String sectionId,
    required String lectureId,
  }) =>
      _lectures(courseId, sectionId).doc(lectureId).delete();

  /// Atomically swap the `order` field between two lectures in the
  /// same section. Used by the up/down reorder buttons in the
  /// curriculum editor — one batch write, one Firestore round-trip,
  /// no intermediate state where two lectures share the same order
  /// value (which would otherwise scramble the `.orderBy('order')`
  /// stream listeners during the in-between frame).
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
