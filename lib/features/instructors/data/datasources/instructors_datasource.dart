import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../courses/data/models/course_model.dart';
import '../models/instructor_model.dart';

/// Firestore reader for the `instructors` collection plus the cross-collection
/// "courses by instructor" query the detail page needs.
class InstructorsDataSource {
  InstructorsDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _instructors =>
      _firestore.collection(FirestoreCollections.instructors);

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection(FirestoreCollections.courses);

  Stream<List<InstructorModel>> watchAll({int limit = 60}) => _instructors
      .orderBy('studentCount', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(InstructorModel.fromDoc).toList());

  Stream<InstructorModel?> watchById(String id) =>
      _instructors.doc(id).snapshots().map(
            (doc) => doc.exists ? InstructorModel.fromDoc(doc) : null,
          );

  Future<InstructorModel?> fetchById(String id) async {
    final snap = await _instructors.doc(id).get();
    if (!snap.exists) return null;
    return InstructorModel.fromDoc(snap);
  }

  /// Live list of courses authored by [instructorId]. Used for the
  /// "My courses (N)" section on the detail page.
  Stream<List<CourseModel>> watchCoursesByInstructor(String instructorId) =>
      _courses
          .where('instructorId', isEqualTo: instructorId)
          .snapshots()
          .map((s) => s.docs.map(CourseModel.fromDoc).toList());
}
