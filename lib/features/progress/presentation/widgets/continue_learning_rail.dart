import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/course_progress_model.dart';
import '../providers/progress_providers.dart';

/// Home tab rail showing the user's 3 most recently watched courses, sorted
/// by `lastWatchedAt desc`. Self-hides when there is nothing to show so the
/// rail doesn't reserve dead vertical space for first-time users.
class ContinueLearningRail extends ConsumerWidget {
  const ContinueLearningRail({super.key, this.limit = 3});

  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(continueLearningProvider(limit));
    final items = async.value ?? const <CourseProgressModel>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t.continueLearningTitle,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ContinueCard(
              progress: items[i],
              onTap: () => _resume(context, items[i]),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Routes to the saved lecture if there is one; otherwise opens the
  /// course detail page so the user can pick.
  void _resume(BuildContext context, CourseProgressModel p) {
    final lectureId = p.lastWatchedLectureId;
    if (lectureId != null) {
      context.pushNamed(
        RouteNames.lecturePlayer,
        pathParameters: {'id': p.id, 'lectureId': lectureId},
      );
    } else {
      context.goNamed(
        RouteNames.courseDetail,
        pathParameters: {'id': p.id},
      );
    }
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.progress, required this.onTap});

  final CourseProgressModel progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final fraction = progress.totalLectures == 0
        ? 0.0
        : (progress.completedCount / progress.totalLectures)
            .clamp(0.0, 1.0);

    return SizedBox(
      width: 240,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: (progress.thumbnailUrl == null ||
                          progress.thumbnailUrl!.isEmpty)
                      ? Container(color: AppColors.primary)
                      : CachedNetworkImage(
                          imageUrl: progress.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.primary),
                        ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.title.isEmpty
                          ? t.courseProgressUntitled
                          : progress.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 6,
                        backgroundColor: context.colors.outlineVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(fraction * 100).round()}%',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
