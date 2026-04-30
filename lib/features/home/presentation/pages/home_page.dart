import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../courses/domain/entities/instrument_category.dart';
import '../../../courses/presentation/providers/courses_providers.dart';
import '../../../courses/presentation/widgets/course_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final featured = ref.watch(featuredCoursesProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName != null
                        ? 'Hello, ${user!.displayName!.split(' ').first} 👋'
                        : 'Welcome to iLearnIt',
                    style: context.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'What will you practice today?',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Browse by instrument'),
            const SizedBox(height: 12),
            const _CategoriesRow(),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Featured courses',
              actionLabel: 'See all',
              onAction: () => context.goNamed(RouteNames.courses),
            ),
            const SizedBox(height: 12),
            featured.when(
              loading: () => const SizedBox(
                height: 220,
                child: LoadingIndicator(),
              ),
              error: (e, _) => SizedBox(
                height: 220,
                child: Center(child: Text(e.toString())),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: Text('No featured courses yet.')),
                  );
                }
                return SizedBox(
                  height: 280,
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
        ),
      ),
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
