import 'package:freezed_annotation/freezed_annotation.dart';

part 'lecture_resource_entity.freezed.dart';

/// An auxiliary download attached to a lecture (slides PDF, sheet music, exercises).
@freezed
abstract class LectureResourceEntity with _$LectureResourceEntity {
  const factory LectureResourceEntity({
    required String name,
    required String url,
    @Default('pdf') String format, // 'pdf' | 'doc' | 'docx' | 'mp3' | …
    @Default(0) int sizeBytes,
  }) = _LectureResourceEntity;
}
