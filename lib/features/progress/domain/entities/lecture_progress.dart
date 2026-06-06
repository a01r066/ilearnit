import 'package:freezed_annotation/freezed_annotation.dart';

part 'lecture_progress.freezed.dart';

/// One row of viewing progress for a single lecture inside a course.
///
/// Persisted at
/// `users/{uid}/courseProgress/{courseId}/lectures/{lectureId}`.
///
/// `positionSec` is the last play-head position. `durationSec` is captured
/// from the player so the per-row "completed" computation doesn't depend
/// on a stale lecture metadata fetch (a course author could re-edit the
/// duration after the user watched).
@freezed
abstract class LectureProgress with _$LectureProgress {
  const LectureProgress._();

  const factory LectureProgress({
    required String lectureId,
    @Default(0) int positionSec,
    @Default(0) int durationSec,
    @Default(false) bool completed,
    DateTime? lastWatchedAt,
  }) = _LectureProgress;

  /// 0..1. Capped at 1 in case the player overshoots `durationSec`.
  double get fraction {
    if (durationSec <= 0) return 0;
    final f = positionSec / durationSec;
    if (f.isNaN || f.isNegative) return 0;
    return f.clamp(0.0, 1.0);
  }

  bool get hasStarted => positionSec > 0 || completed;
}
