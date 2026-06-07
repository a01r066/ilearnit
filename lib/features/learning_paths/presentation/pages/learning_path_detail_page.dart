import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/presentation/providers/courses_providers.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../data/models/learning_path_model.dart';
import '../providers/learning_paths_providers.dart';

/// Detail page for a single learning path.
///
/// Layout: cover hero + title + summary + stat strip, then an ordered
/// list of courses with a per-row progress indicator. The first
/// not-completed course is highlighted as "next up" — that's the
/// course the "Start path" CTA jumps to.
class LearningPathDetailPage extends ConsumerWidget {
  const LearningPathDetailPage({super.key, required this.pathId});

  final String pathId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final asyncPath = ref.watch(learningPathByIdProvider(pathId));

    return Scaffold(
      body: asyncPath.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e',
                style: TextStyle(color: context.colors.error)),
          ),
        ),
        data: (path) {
          if (path == null) {
            return Center(child: Text(t.learningPathNotFound));
          }
          return _Loaded(path: path);
        },
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({required this.path});
  final LearningPathModel path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              path.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            background: (path.coverUrl == null || path.coverUrl!.isEmpty)
                ? Container(color: AppColors.primary)
                : CachedNetworkImage(
                    imageUrl: path.coverUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.primary),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatStrip(path: path),
                const SizedBox(height: 16),
                Text(
                  path.summary,
                  style: context.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),
                Text(
                  t.learningPathCurriculumHeader,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: path.courseIds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _PathCourseRow(
              index: i + 1,
              courseId: path.courseIds[i],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ---------- Stat strip ----------------------------------------------------

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.path});
  final LearningPathModel path;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      children: [
        _Stat(
          icon: Icons.menu_book_outlined,
          label: t.learningPathCourseCount(path.courseIds.length),
        ),
        const SizedBox(width: 16),
        _Stat(
          icon: Icons.schedule_outlined,
          label: t.learningPathTotalHours(
            path.totalHours.toStringAsFixed(
              path.totalHours.truncate() == path.totalHours ? 0 : 1,
            ),
          ),
        ),
        if (path.instrument != null) ...[
          const SizedBox(width: 16),
          _Stat(
            icon: Icons.music_note_outlined,
            label: path.instrument ?? '',
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ---------- One row in the curriculum -----------------------------------

class _PathCourseRow extends ConsumerWidget {
  const _PathCourseRow({required this.index, required this.courseId});
  final int index;
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCourse = ref.watch(courseByIdProvider(courseId));
    final asyncProgress =
        ref.watch(courseProgressSummaryProvider(courseId));

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.pushNamed(
        RouteNames.courseDetail,
        pathParameters: {'id': courseId},
      ),
      child: asyncCourse.when(
        loading: () => const _Shell(child: SizedBox(height: 80)),
        error: (e, _) => _Shell(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Error: $e',
                style: TextStyle(color: context.colors.error)),
          ),
        ),
        data: (course) {
          if (course == null) {
            return _Shell(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  AppLocalizations.of(context).learningPathCourseMissing,
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
              ),
            );
          }
          final progress = asyncProgress.value;
          return _Shell(
            child: _Body(
              index: index,
              course: course,
              fractionComplete: progress?.fractionComplete ?? 0,
              isFinished: progress?.isFinished ?? false,
            ),
          );
        },
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.index,
    required this.course,
    required this.fractionComplete,
    required this.isFinished,
  });

  final int index;
  final CourseEntity course;
  final double fractionComplete;
  final bool isFinished;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Sequence badge
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFinished
                  ? AppColors.success
                  : AppColors.primary.withValues(alpha: 0.10),
            ),
            child: isFinished
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 18)
                : Text(
                    '$index',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  course.instructorName,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fractionComplete,
                    minHeight: 6,
                    backgroundColor: context.colors.outlineVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
