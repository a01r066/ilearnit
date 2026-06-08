import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_question.freezed.dart';

/// A student-posted question against a single lecture.
///
/// Persisted at
/// `courses/{cid}/sections/{sid}/lectures/{lid}/questions/{qId}`.
///
/// `replyCount` and `isInstructorAnswered` are denormalized aggregators
/// — the datasource bumps them when a reply is created, so the list
/// view can render filter chips ("Instructor answered" / "Unanswered")
/// without scanning every replies subcollection.
@freezed
abstract class CourseQuestion with _$CourseQuestion {
  const CourseQuestion._();

  const factory CourseQuestion({
    required String id,
    required String userId,
    @Default('') String userName,
    String? userPhotoUrl,
    @Default('') String body,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(0) int replyCount,
    @Default(false) bool isInstructorAnswered,
  }) = _CourseQuestion;
}
