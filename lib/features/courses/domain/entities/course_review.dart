import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_review.freezed.dart';

/// One user's review of one course. Stored at
/// `courses/{courseId}/reviews/{userId}` so we get the "one review per
/// user per course" invariant for free (the doc id IS the user id).
@freezed
abstract class CourseReview with _$CourseReview {
  const factory CourseReview({
    /// Same value as [userId] (Firestore doc id == authoring user uid).
    required String id,
    required String courseId,
    required String userId,
    required String userName,
    String? userPhotoUrl,

    /// 1..5 inclusive.
    required int rating,
    required String body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CourseReview;
}
