import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/course_review.dart';

part 'course_review_model.freezed.dart';
part 'course_review_model.g.dart';

/// Firestore DTO for `courses/{courseId}/reviews/{userId}`.
@freezed
abstract class CourseReviewModel with _$CourseReviewModel {
  const CourseReviewModel._();

  const factory CourseReviewModel({
    required String id,
    @Default('') String courseId,
    @Default('') String userId,
    @Default('') String userName,
    String? userPhotoUrl,
    @Default(0) int rating,
    @Default('') String body,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _CourseReviewModel;

  factory CourseReviewModel.fromJson(Map<String, dynamic> json) =>
      _$CourseReviewModelFromJson(json);

  factory CourseReviewModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CourseReviewModel.fromJson({...data, 'id': doc.id});
  }

  CourseReview toEntity() => CourseReview(
        id: id,
        courseId: courseId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        rating: rating,
        body: body,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
