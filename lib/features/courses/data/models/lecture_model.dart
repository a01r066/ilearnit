import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/lecture_entity.dart';
import '../../domain/entities/lecture_type.dart';
import 'lecture_resource_model.dart';

part 'lecture_model.freezed.dart';
part 'lecture_model.g.dart';

@freezed
abstract class LectureModel with _$LectureModel {
  const LectureModel._();

  const factory LectureModel({
    required String id,
    required String title,
    required String type, // 'video' | 'audio' | 'pdf' | 'doc'
    required int durationSeconds,
    @Default(0) int order,
    @Default(false) bool isPreview,
    String? mediaUrl,
    /// Cloudflare Stream video UID (e.g. `bf53017eb20e5db311c21d30ffb5a075`).
    /// When set, takes precedence over [mediaUrl] — the player resolves
    /// the UID through the `resolveStreamPlayback` Cloud Function to
    /// get a fresh HLS URL on demand. [mediaUrl] is kept as a fallback
    /// for legacy lectures still hosted on Firebase Storage.
    String? cloudflareVideoId,
    String? thumbnailUrl,
    String? description,
    @Default(<LectureResourceModel>[]) List<LectureResourceModel> resources,
    @Default(0) int fileSizeBytes,
  }) = _LectureModel;

  factory LectureModel.fromJson(Map<String, dynamic> json) =>
      _$LectureModelFromJson(json);

  LectureEntity toEntity() => LectureEntity(
        id: id,
        title: title,
        type: LectureType.fromId(type),
        durationSeconds: durationSeconds,
        order: order,
        isPreview: isPreview,
        mediaUrl: mediaUrl,
        cloudflareVideoId: cloudflareVideoId,
        thumbnailUrl: thumbnailUrl,
        description: description,
        resources: resources.map((r) => r.toEntity()).toList(),
        fileSizeBytes: fileSizeBytes,
      );
}
