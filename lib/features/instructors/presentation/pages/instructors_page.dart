import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../data/models/instructor_model.dart';
import '../providers/instructor_providers.dart';

/// Lists every instructor / publisher. Tap a row → InstructorDetailPage.
class InstructorsPage extends ConsumerWidget {
  const InstructorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(instructorsListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructors'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => context.goNamed(RouteNames.search),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(instructorsListProvider);
        },
        child: list.when(
          loading: () => const _InstructorListSkeleton(),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('$e',
                  style: TextStyle(color: context.colors.error)),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              // Wrap in ListView so the RefreshIndicator gesture still
              // works when the catalogue is empty.
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_rounded, size: 56),
                        SizedBox(height: 12),
                        Text(
                          'No instructors yet.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _InstructorRow(instructor: items[i]),
            );
          },
        ),
      ),
    );
  }
}

/// Skeleton rows that mirror `_InstructorRow`'s layout — 56×56 avatar +
/// two text lines.
class _InstructorListSkeleton extends StatelessWidget {
  const _InstructorListSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 6,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, __) => const ListTile(
          leading: SkeletonBox(width: 56, height: 56, borderRadius: 4),
          title: Padding(
            padding: EdgeInsets.only(top: 8, right: 80),
            child: SkeletonText(height: 14),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 8, right: 140),
            child: SkeletonText(height: 12),
          ),
        ),
      ),
    );
  }
}

class _InstructorRow extends StatelessWidget {
  const _InstructorRow({required this.instructor});
  final InstructorModel instructor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    return ListTile(
      onTap: () => context.goNamed(
        RouteNames.instructorDetail,
        pathParameters: {'id': instructor.id},
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 56,
          height: 56,
          child: instructor.photoUrl.isEmpty
              ? Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.person_outline),
                )
              : CachedNetworkImage(
                  imageUrl: instructor.photoUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
        ),
      ),
      title: Text(
        instructor.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        [
          if (instructor.primaryInstrument != null)
            instructor.primaryInstrument!,
          '${fmt.format(instructor.studentCount)} students',
        ].join(' · '),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
