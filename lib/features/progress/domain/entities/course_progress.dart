import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_progress.freezed.dart';

/// Per-course rollup persisted at `users/{uid}/courseProgress/{courseId}`.
///
/// We denormalize a handful of course fields (`title`, `thumbnailUrl`) so
/// the Home "Continue learning" rail can render without an N+1 round-trip
/// to `courses/{id}` for every in-progress course.
@freezed
abstract class CourseProgress with _$CourseProgress {
  const CourseProgress._();

  const factory CourseProgress({
    required String courseId,

    /// Denormalized course title — populated by the client on every write.
    @Default('') String title,

    /// Denormalized cover image.
    String? thumbnailUrl,

    /// Last lecture the user touched. Drives the "Resume" CTA.
    String? lastWatchedLectureId,

    /// Last lecture's section id — so the Resume CTA can deep-link to the
    /// player route without a curriculum scan.
    String? lastWatchedSectionId,

    /// Server-side timestamp updated on every write. Drives the sort on the
    /// Continue learning rail.
    DateTime? lastWatchedAt,

    /// Number of lectures the user has finished (≥95 % watched).
    @Default(0) int completedCount,

    /// Snapshot of the course's lecture count at the time of the last write.
    /// Used as the denominator for `fractionComplete`.
    @Default(0) int totalLectures,
  }) = _CourseProgress;

  /// 0..1 — drives the LinearProgressIndicator on the course detail page
  /// and on the Continue learning cards.
  double get fractionComplete {
    if (totalLectures <= 0) return 0;
    return (completedCount / totalLectures).clamp(0.0, 1.0);
  }

  bool get hasStarted => lastWatchedAt != null || completedCount > 0;

  bool get isFinished => totalLectures > 0 && completedCount >= totalLectures;
}
