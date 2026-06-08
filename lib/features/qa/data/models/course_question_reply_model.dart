import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/course_question_reply.dart';

part 'course_question_reply_model.freezed.dart';
part 'course_question_reply_model.g.dart';

/// Firestore DTO for `…/questions/{qId}/replies/{rid}`.
@freezed
abstract class CourseQuestionReplyModel
    with _$CourseQuestionReplyModel {
  const CourseQuestionReplyModel._();

  const factory CourseQuestionReplyModel({
    required String id,
    @Default('') String userId,
    @Default('') String userName,
    String? userPhotoUrl,
    @Default('') String body,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
    @Default(false) bool isInstructor,
  }) = _CourseQuestionReplyModel;

  factory CourseQuestionReplyModel.fromJson(Map<String, dynamic> json) =>
      _$CourseQuestionReplyModelFromJson(json);

  factory CourseQuestionReplyModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CourseQuestionReplyModel.fromJson({...data, 'id': doc.id});
  }

  CourseQuestionReply toEntity() => CourseQuestionReply(
        id: id,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        body: body,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isInstructor: isInstructor,
      );
}
