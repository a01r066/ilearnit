import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/progress_providers.dart';

/// Compact progress card rendered under the course detail header.
///
/// Visible only when the user has any saved progress on the course:
/// shows a `LinearProgressIndicator`, "X of Y lectures completed" copy,
/// and a "Resume" CTA that jumps the player back to the last lecture
/// they touched.
class CourseProgressCard extends ConsumerWidget {
  const CourseProgressCard({
    super.key,
    required this.courseId,
    required this.onResume,
  });

  final String courseId;

  /// Invoked with the `lectureId` to resume on.
  final ValueChanged<String> onResume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final asyncSummary = ref.watch(courseProgressSummaryProvider(courseId));
    final summary = asyncSummary.value;
    // Don't render anything while loading or when there is no progress
    // doc yet — the BuyCourseButton already provides a "Start course" CTA.
    if (summary == null || !summary.hasStarted) {
      return const SizedBox.shrink();
    }

    final lastLecture = summary.lastWatchedLectureId;
    final fraction = summary.fractionComplete;
    final isFinished = summary.isFinished;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFinished
                    ? Icons.verified_rounded
                    : Icons.play_circle_outline_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFinished
                      ? t.courseProgressFinished
                      : t.courseProgressInProgress(
                          summary.completedCount,
                          summary.totalLectures,
                        ),
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(fraction * 100).round()}%',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (!isFinished && lastLecture != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(t.courseProgressResume),
                onPressed: () => onResume(lastLecture),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
