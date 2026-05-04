import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/instrument_category.dart';
import '../../domain/repositories/courses_repository.dart';
import '../models/course_model.dart';
import '../models/course_section_model.dart';

abstract interface class CoursesRemoteDataSource {
  Future<CoursesPageDto> fetchCourses({
    InstrumentCategory? category,
    CourseLevel? level,
    String? cursor,
    required int limit,
  });

  Future<CourseModel> fetchCourseById(String id);
  Future<List<CourseModel>> fetchFeatured({required int limit});

  Future<List<CourseSectionModel>> fetchSections(String courseId);
}

class CoursesPageDto {
  CoursesPageDto({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });
  final List<CourseModel> items;
  final String? nextCursor;
  final bool hasMore;
}

class CoursesRemoteDataSourceImpl implements CoursesRemoteDataSource {
  CoursesRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection(FirestoreCollections.courses);

  @override
  Future<CoursesPageDto> fetchCourses({
    InstrumentCategory? category,
    CourseLevel? level,
    String? cursor,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> q = _courses;

    if (category != null) q = q.where('category', isEqualTo: category.id);
    if (level != null) q = q.where('level', isEqualTo: level.id);

    q = q.orderBy('publishedAt', descending: true).limit(limit + 1);

    if (cursor != null) {
      final cursorDoc = await _courses.doc(cursor).get();
      if (cursorDoc.exists) q = q.startAfterDocument(cursorDoc);
    }

    try {
      final snap = await q.get();
      final docs = snap.docs;
      final hasMore = docs.length > limit;
      final pageDocs = hasMore ? docs.sublist(0, limit) : docs;

      return CoursesPageDto(
        items: pageDocs.map(CourseModel.fromDoc).toList(),
        nextCursor: hasMore ? pageDocs.last.id : null,
        hasMore: hasMore,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load courses.',
        statusCode: 0,
      );
    }
  }

  @override
  Future<CourseModel> fetchCourseById(String id) async {
    try {
      final doc = await _courses.doc(id).get();
      if (!doc.exists) {
        throw ServerException(message: 'Course not found.', statusCode: 404);
      }
      return CourseModel.fromDoc(doc);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Fetch failed.');
    }
  }

  @override
  Future<List<CourseModel>> fetchFeatured({required int limit}) async {
    try {
      final snap = await _courses
          .where('isFeatured', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(CourseModel.fromDoc).toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Fetch failed.');
    }
  }

  @override
  Future<List<CourseSectionModel>> fetchSections(String courseId) async {
    try {
      final snap = await _courses
          .doc(courseId)
          .collection('sections')
          .orderBy('order')
          .get();
      return snap.docs.map(CourseSectionModel.fromDoc).toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load curriculum.',
      );
    }
  }
}
