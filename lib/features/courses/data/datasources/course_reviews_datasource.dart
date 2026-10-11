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

  /// Insert / update the calling user's review. The course's `rating` +
  /// `reviewCount` are recomputed server-side by the `onCourseReviewWritten`
  /// Cloud Function — clients can't write those fields (firestore.rules),
  /// and the review itself is only accepted from buyers / subscribers.
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
  }

  Future<void> delete({
    required String courseId,
    required String userId,
  }) async {
    await _reviews(courseId).doc(userId).delete();
  }
}
