import 'package:freezed_annotation/freezed_annotation.dart';

import 'lecture_resource_entity.dart';
import 'lecture_type.dart';

part 'lecture_entity.freezed.dart';

@freezed
abstract class LectureEntity with _$LectureEntity {
  const LectureEntity._();

  const factory LectureEntity({
    required String id,
    required String title,
    required LectureType type,
    required int durationSeconds,
    @Default(0) int order,
    @Default(false) bool isPreview,
    String? mediaUrl, // streamable URL for video/audio, primary URL for documents
    String? thumbnailUrl,
    String? description,
    @Default(<LectureResourceEntity>[]) List<LectureResourceEntity> resources,
    @Default(0) int fileSizeBytes,
  }) = _LectureEntity;

  /// Human-friendly duration like `12:04` or `1:24:30`.
  String get formattedDuration {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  bool get hasResources => resources.isNotEmpty;
}
