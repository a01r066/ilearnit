import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/course_section_entity.dart';
import 'lecture_model.dart';

part 'course_section_model.freezed.dart';
part 'course_section_model.g.dart';

@freezed
abstract class CourseSectionModel with _$CourseSectionModel {
  const CourseSectionModel._();

  const factory CourseSectionModel({
    required String id,
    required String title,
    @Default(0) int order,
    @Default(<LectureModel>[]) List<LectureModel> lectures,
  }) = _CourseSectionModel;

  factory CourseSectionModel.fromJson(Map<String, dynamic> json) =>
      _$CourseSectionModelFromJson(json);

  factory CourseSectionModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CourseSectionModel.fromJson({...data, 'id': doc.id});
  }

  CourseSectionEntity toEntity() => CourseSectionEntity(
        id: id,
        title: title,
        order: order,
        lectures: lectures.map((l) => l.toEntity()).toList(),
      );
}
