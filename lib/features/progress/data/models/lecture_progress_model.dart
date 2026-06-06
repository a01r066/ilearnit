import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/lecture_progress.dart';

part 'lecture_progress_model.freezed.dart';
part 'lecture_progress_model.g.dart';

/// Firestore DTO for
/// `users/{uid}/courseProgress/{courseId}/lectures/{lectureId}`.
@freezed
abstract class LectureProgressModel with _$LectureProgressModel {
  const LectureProgressModel._();

  const factory LectureProgressModel({
    required String id, // == lectureId
    @Default(0) int positionSec,
    @Default(0) int durationSec,
    @Default(false) bool completed,
    @TimestampConverter() DateTime? lastWatchedAt,
  }) = _LectureProgressModel;

  factory LectureProgressModel.fromJson(Map<String, dynamic> json) =>
      _$LectureProgressModelFromJson(json);

  factory LectureProgressModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return LectureProgressModel.fromJson({...data, 'id': doc.id});
  }

  LectureProgress toEntity() => LectureProgress(
        lectureId: id,
        positionSec: positionSec,
        durationSec: durationSec,
        completed: completed,
        lastWatchedAt: lastWatchedAt,
      );
}
