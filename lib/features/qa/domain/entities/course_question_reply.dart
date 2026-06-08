import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_question_reply.freezed.dart';

/// Reply to a [CourseQuestion]. Persisted at
/// `…/questions/{qId}/replies/{rid}`.
///
/// `isInstructor` is denormalized on write so the "verified instructor"
/// badge survives instructor role changes (the alternative — comparing
/// `reply.userId == course.instructorId` at render time — would lose the
/// badge if the course later gets reassigned).
@freezed
abstract class CourseQuestionReply with _$CourseQuestionReply {
  const CourseQuestionReply._();

  const factory CourseQuestionReply({
    required String id,
    required String userId,
    @Default('') String userName,
    String? userPhotoUrl,
    @Default('') String body,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isInstructor,
  }) = _CourseQuestionReply;
}
