import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/lecture_entity.dart';
import '../providers/course_detail_state.dart';
import '../providers/courses_providers.dart';
import '../providers/curriculum_state.dart';
import '../widgets/section_tile.dart';

class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courseDetailNotifierProvider(courseId));
    final notifier = ref.read(courseDetailNotifierProvider(courseId).notifier);

    return Scaffold(
      body: state.when(
        loading: () => const LoadingIndicator(),
        error: (failure) => ErrorView(
          message: failure.displayMessage,
          onRetry: notifier.load,
        ),
        loaded: (course) => _Loaded(course: course),
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({required this.course});
  final CourseEntity course;

  void _openLecture(BuildContext context, LectureEntity lecture) {
    // pushNamed (not goNamed) so the player stacks on top of detail and the
    // back button returns to the curriculum.
    context.pushNamed(
      RouteNames.lecturePlayer,
      pathParameters: {'id': course.id, 'lectureId': lecture.id},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(enrollment): replace `false` with real `isEnrolled` from a provider
    // once enrollment is implemented.
    const isEnrolled = false;

    final curriculum = ref.watch(curriculumNotifierProvider(course.id));
    final curriculumNotifier =
        ref.read(curriculumNotifierProvider(course.id).notifier);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              course.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            background: course.thumbnailUrl.isEmpty
                ? Container(color: AppColors.primary)
                : CachedNetworkImage(
                    imageUrl: course.thumbnailUrl,
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
                Row(
                  children: [
                    _Pill(text: course.category.label),
                    const SizedBox(width: 8),
                    _Pill(text: course.level.label),
                    const Spacer(),
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    Text(' ${course.rating.toStringAsFixed(1)}'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  course.title,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Taught by ${course.instructorName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
                const SizedBox(height: 16),
                _StatsRow(course: course),
                const SizedBox(height: 24),
                Text(
                  'About this course',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  course.summary,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    // TODO(courses): start enrollment flow.
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start course'),
                ),
                const SizedBox(height: 24),
                _CurriculumHeader(state: curriculum),
              ],
            ),
          ),
        ),
        ..._curriculumSlivers(
          curriculum: curriculum,
          isEnrolled: isEnrolled,
          onRetry: curriculumNotifier.load,
          onLectureTap: (l) => _openLecture(context, l),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

List<Widget> _curriculumSlivers({
  required CurriculumState curriculum,
  required bool isEnrolled,
  required VoidCallback onRetry,
  required void Function(LectureEntity) onLectureTap,
}) {
  return curriculum.map(
    loading: (_) => [
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: LoadingIndicator(),
        ),
      ),
    ],
    error: (s) => [
      SliverToBoxAdapter(
        child: ErrorView(
          message: s.failure.displayMessage,
          onRetry: onRetry,
        ),
      ),
    ],
    loaded: (s) {
      if (s.sections.isEmpty) {
        return const [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Curriculum coming soon.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ];
      }
      return [
        SliverList.builder(
          itemCount: s.sections.length,
          itemBuilder: (_, i) => SectionTile(
            index: i,
            section: s.sections[i],
            isEnrolled: isEnrolled,
            initiallyExpanded: i == 0,
            onLectureTap: onLectureTap,
          ),
        ),
      ];
    },
  );
}

class _CurriculumHeader extends StatelessWidget {
  const _CurriculumHeader({required this.state});
  final CurriculumState state;

  @override
  Widget build(BuildContext context) {
    final summary = state.maybeMap(
      loaded: (s) {
        final lectureCount = s.sections.fold<int>(
          0,
          (n, sec) => n + sec.lectures.length,
        );
        final totalSec = s.sections.fold<int>(
          0,
          (n, sec) => n + sec.totalDurationSeconds,
        );
        final h = totalSec ~/ 3600;
        final m = (totalSec % 3600) ~/ 60;
        final dur = h > 0 ? '${h}h ${m}min' : '${m}min';
        return '${s.sections.length} sections • $lectureCount lectures • $dur';
      },
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Curriculum', style: Theme.of(context).textTheme.titleLarge),
        if (summary != null) ...[
          const SizedBox(height: 4),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.course});
  final CourseEntity course;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(
          icon: Icons.video_library_outlined,
          label: '${course.lessonCount} lessons',
        ),
        const SizedBox(width: 16),
        _Stat(
          icon: Icons.timer_outlined,
          label: '${course.durationMinutes} min',
        ),
        const SizedBox(width: 16),
        _Stat(
          icon: Icons.people_outline,
          label: '${course.enrollmentCount} enrolled',
        ),
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
      children: [
        Icon(icon, size: 18, color: Theme.of(context).hintColor),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

