import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../data/models/course_progress_model.dart';
import '../providers/progress_providers.dart';

/// "My learning" — every course the user has any progress on, newest
/// activity first. Reuses the existing `users/{uid}/courseProgress`
/// rollup data that powers the Home "Continue learning" rail; this
/// page just renders the full list instead of the top 3.
///
/// Tap a row → resume at the last-watched lecture (if known) or open
/// the course detail page.
class MyLearningPage extends ConsumerWidget {
  const MyLearningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 100 covers any realistic active library; older items naturally
    // fall off the bottom. If a power user crosses that threshold we
    // can swap to a paginated query — the rollup docs are small.
    final async = ref.watch(continueLearningProvider(100));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My learning'),
        // Right-aligned actions match the screenshot reference: search
        // is wired here as a TODO (deep-link into /search filtered to
        // the user's own courses would be the natural next step).
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed(RouteNames.search),
          ),
          IconButton(
            tooltip: 'Filter',
            icon: const Icon(Icons.tune),
            onPressed: () {/* future: in-progress / completed filter */},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Empty(
          title: 'Could not load your library.',
          subtitle: '$e',
          icon: Icons.error_outline,
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _Empty(
              title: 'Nothing in your library yet.',
              subtitle:
                  'Start any lecture and it will show up here so you can '
                  'pick up where you left off.',
              icon: Icons.school_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(continueLearningProvider(100));
              await ref.read(continueLearningProvider(100).future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _LearningRow(progress: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _LearningRow extends StatelessWidget {
  const _LearningRow({required this.progress});
  final CourseProgressModel progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // `fractionComplete` (model name) maps to the entity's
    // `progressFraction`. The model duplicates the getter so the UI
    // can read it without round-tripping through `.toEntity()`.
    final fraction = progress.fractionComplete;
    final percent = (fraction * 100).round();
    final isFinished = progress.isFinished;

    return InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 64,
                height: 64,
                child: (progress.thumbnailUrl != null &&
                        progress.thumbnailUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: progress.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color:
                              theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined,
                              size: 24),
                        ),
                      )
                    : Container(
                        color:
                            theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.school_outlined, size: 24),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Title + instructor + progress bar ────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.title.isEmpty ? '(untitled)' : progress.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Instructor name isn't on the rollup doc — we omit it
                  // here rather than do an N+1 read against courses/{id}.
                  // Filed for the "denormalize instructorName on the
                  // rollup" follow-up.
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 4,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isFinished
                        ? 'Completed'
                        : '$percent% complete',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isFinished
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isFinished
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    // If we know the last lecture, jump straight into the player —
    // matches the "Resume" CTA on the course detail page. Otherwise
    // open course detail and let the user pick.
    //
    // `progress.id` IS the courseId — the rollup doc lives at
    // `users/{uid}/courseProgress/{courseId}`, and the model stores
    // the doc id under `id` (with the inline comment in the model
    // saying `id == courseId`).
    final courseId = progress.id;
    final lid = progress.lastWatchedLectureId;
    if (lid != null && lid.isNotEmpty) {
      context.pushNamed(
        RouteNames.lecturePlayer,
        pathParameters: {
          'id': courseId,
          'lectureId': lid,
        },
      );
    } else {
      context.pushNamed(
        RouteNames.courseDetail,
        pathParameters: {'id': courseId},
      );
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(title,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
