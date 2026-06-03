import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/extensions.dart';
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
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e',
                style: TextStyle(color: context.colors.error)),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
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
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _InstructorRow(instructor: items[i]),
          );
        },
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
