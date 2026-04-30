import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/instrument_category.dart';

part 'course_model.freezed.dart';
part 'course_model.g.dart';

@freezed
class CourseModel with _$CourseModel {
  const CourseModel._();

  const factory CourseModel({
    required String id,
    required String title,
    required String summary,
    required String thumbnailUrl,
    required String category,
    required String level,
    required String instructorId,
    required String instructorName,
    @Default(0) int lessonCount,
    @Default(0) int enrollmentCount,
    @Default(0.0) double rating,
    @Default(0) int durationMinutes,
    @Default(false) bool isFeatured,
    @Default(<String>[]) List<String> tags,
    @TimestampConverter() DateTime? publishedAt,
  }) = _CourseModel;

  factory CourseModel.fromJson(Map<String, dynamic> json) =>
      _$CourseModelFromJson(json);

  factory CourseModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CourseModel.fromJson({...data, 'id': doc.id});
  }

  CourseEntity toEntity() => CourseEntity(
        id: id,
        title: title,
        summary: summary,
        thumbnailUrl: thumbnailUrl,
        category: InstrumentCategory.fromId(category),
        level: CourseLevel.fromId(level),
        instructorId: instructorId,
        instructorName: instructorName,
        lessonCount: lessonCount,
        enrollmentCount: enrollmentCount,
        rating: rating,
        durationMinutes: durationMinutes,
        isFeatured: isFeatured,
        tags: tags,
        publishedAt: publishedAt,
      );
}
