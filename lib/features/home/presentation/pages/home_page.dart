import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/notifications/presentation/widgets/notification_bell.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/domain/entities/instrument_category.dart';
import '../../../courses/presentation/providers/courses_providers.dart';
import '../../../courses/presentation/widgets/course_card.dart';
import '../../../courses/presentation/widgets/course_carousel_skeleton.dart';
import '../../../progress/presentation/widgets/continue_learning_rail.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final featured = ref.watch(featuredCoursesProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Invalidate every provider this screen consumes so a single
            // gesture reloads the full page. Each `ref.refresh` returns
            // the fresh value; we discard them and rely on the consuming
            // widgets to re-render on the next frame.
            ref.invalidate(featuredCoursesProvider);
            for (final c in InstrumentCategory.values) {
              ref.invalidate(popularByInstrumentProvider(c));
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  const Spacer(),
                  IconButton(
                    tooltip: 'Search',
                    icon: const Icon(Icons.search),
                    onPressed: () => context.goNamed(RouteNames.search),
                  ),
                  const NotificationBell(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName != null
                        ? t.homeWelcomeNamed(user!.displayName!.split(' ').first)
                        : t.homeWelcomeAnon,
                    style: context.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.homeWelcomeSubtitle,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Continue learning — appears only if the user has any
            // recently watched courses. Self-hiding when empty.
            const ContinueLearningRail(),
            _SectionHeader(title: t.homeBrowseByInstrument),
            const SizedBox(height: 12),
            const _CategoriesRow(),
            const SizedBox(height: 24),
            _SectionHeader(
              title: t.homeFeaturedCourses,
              actionLabel: t.homeSeeAll,
              onAction: () => context.goNamed(RouteNames.courses),
            ),
            const SizedBox(height: 12),
            featured.when(
              loading: () => const CourseCarouselSkeleton(),
              error: (e, _) => SizedBox(
                height: 220,
                child: Center(child: Text(e.toString())),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SizedBox(
                    height: 220,
                    child: Center(child: Text(t.homeNoFeaturedYet)),
                  );
                }
                return SizedBox(
                  // 280 (card width) ÷ 16*9 ≈ 158 for the thumbnail, plus
                  // ~155 for content/padding/borders. 320 leaves headroom.
                  height: 320,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => SizedBox(
                      width: 280,
                      child: CourseCard(
                        course: items[i],
                        onTap: () => context.goNamed(
                          RouteNames.courseDetail,
                          pathParameters: {'id': items[i].id},
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // ----- One "Popular {Instrument} Courses" section per instrument
            for (final c in InstrumentCategory.values) ...[
              const SizedBox(height: 24),
              _PopularInstrumentSection(category: c),
            ],
          ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal carousel of popular courses for a single [InstrumentCategory].
/// Reuses the same [CourseCard] + 320px height as the Featured carousel for
/// visual consistency.
class _PopularInstrumentSection extends ConsumerWidget {
  const _PopularInstrumentSection({required this.category});
  final InstrumentCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(popularByInstrumentProvider(category));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: t.homePopularInstrument(category.label),
          actionLabel: t.homeSeeAll,
          onAction: () => context.goNamed(RouteNames.courses),
        ),
        const SizedBox(height: 12),
        async.when(
          loading: () => const CourseCarouselSkeleton(),
          error: (e, _) => SizedBox(
            height: 220,
            child: Center(child: Text(e.toString())),
          ),
          data: (List<CourseEntity> items) {
            if (items.isEmpty) {
              return SizedBox(
                height: 220,
                child: Center(child: Text(t.homeNoPopularYet)),
              );
            }
            return SizedBox(
              height: 320,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 280,
                  child: CourseCard(
                    course: items[i],
                    onTap: () => context.goNamed(
                      RouteNames.courseDetail,
                      pathParameters: {'id': items[i].id},
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: context.textTheme.titleLarge),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow();

  Color _color(InstrumentCategory c) {
    switch (c) {
      case InstrumentCategory.guitar:
        return AppColors.guitar;
      case InstrumentCategory.piano:
        return AppColors.piano;
      case InstrumentCategory.violin:
        return AppColors.violin;
    }
  }

  IconData _icon(InstrumentCategory c) {
    switch (c) {
      case InstrumentCategory.guitar:
        return Icons.music_note_rounded;
      case InstrumentCategory.piano:
        return Icons.piano_rounded;
      case InstrumentCategory.violin:
        return Icons.queue_music_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: InstrumentCategory.values.map((c) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => context.goNamed(RouteNames.courses),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _color(c).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(_icon(c), size: 32, color: _color(c)),
                      const SizedBox(height: 8),
                      Text(
                        c.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _color(c),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
