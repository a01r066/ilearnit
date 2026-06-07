import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/learning_path_model.dart';
import '../providers/learning_paths_providers.dart';
import 'learning_path_card.dart';

/// Home tab horizontal carousel of curated learning paths.
///
/// Self-hides when empty so first-time users (or VN-only catalogues
/// where the editorial team hasn't shipped a path yet) don't see dead
/// space.
class LearningPathsRail extends ConsumerWidget {
  const LearningPathsRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(learningPathsStreamProvider);
    final items = async.value ?? const <LearningPathModel>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            t.learningPathsTitle,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 280,
              child: LearningPathCard(
                path: items[i],
                onTap: () => context.pushNamed(
                  RouteNames.learningPathDetail,
                  pathParameters: {'id': items[i].id},
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
