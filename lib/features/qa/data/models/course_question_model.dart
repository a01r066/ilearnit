import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/course_question.dart';

part 'course_question_model.freezed.dart';
part 'course_question_model.g.dart';

/// Firestore DTO for
/// `courses/{cid}/sections/{sid}/lectures/{lid}/questions/{qId}`.
@freezed
abstract class CourseQuestionModel with _$CourseQuestionModel {
  const CourseQuestionModel._();

  const factory CourseQuestionModel({
    required String id,
    @Default('') String userId,
    @Default('') String userName,
    String? userPhotoUrl,
    @Default('') String body,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
    @Default(0) int replyCount,
    @Default(false) bool isInstructorAnswered,
  }) = _CourseQuestionModel;

  factory CourseQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$CourseQuestionModelFromJson(json);

  factory CourseQuestionModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CourseQuestionModel.fromJson({...data, 'id': doc.id});
  }

  CourseQuestion toEntity() => CourseQuestion(
        id: id,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        body: body,
        createdAt: createdAt,
        updatedAt: updatedAt,
        replyCount: replyCount,
        isInstructorAnswered: isInstructorAnswered,
      );
}
