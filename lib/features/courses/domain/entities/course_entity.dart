import 'package:freezed_annotation/freezed_annotation.dart';

import 'instrument_category.dart';

part 'course_entity.freezed.dart';

@freezed
class CourseEntity with _$CourseEntity {
  const factory CourseEntity({
    required String id,
    required String title,
    required String summary,
    required String thumbnailUrl,
    required InstrumentCategory category,
    required CourseLevel level,
    required String instructorId,
    required String instructorName,
    @Default(0) int lessonCount,
    @Default(0) int enrollmentCount,
    @Default(0.0) double rating,
    @Default(0) int durationMinutes,
    @Default(false) bool isFeatured,
    @Default(<String>[]) List<String> tags,
    DateTime? publishedAt,
  }) = _CourseEntity;
}
