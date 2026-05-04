import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/lecture_resource_entity.dart';

part 'lecture_resource_model.freezed.dart';
part 'lecture_resource_model.g.dart';

@freezed
abstract class LectureResourceModel with _$LectureResourceModel {
  const LectureResourceModel._();

  const factory LectureResourceModel({
    required String name,
    required String url,
    @Default('pdf') String format,
    @Default(0) int sizeBytes,
  }) = _LectureResourceModel;

  factory LectureResourceModel.fromJson(Map<String, dynamic> json) =>
      _$LectureResourceModelFromJson(json);

  LectureResourceEntity toEntity() => LectureResourceEntity(
        name: name,
        url: url,
        format: format,
        sizeBytes: sizeBytes,
      );
}
