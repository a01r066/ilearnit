import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/courses/data/models/course_model.dart';
import '../../../features/courses/domain/entities/course_status.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';
import 'widgets/course_status_chip.dart';

/// Admin-only: every course in the system. Admin can edit metadata
/// (by opening the same course editor instructors use), feature/unfeature,
/// or hard-delete.
class AdminCoursesPage extends ConsumerStatefulWidget {
  const AdminCoursesPage({super.key});

  @override
  ConsumerState<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends ConsumerState<AdminCoursesPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final stream =
        ref.watch(adminCoursesDataSourceProvider).watchAllCourses();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('All courses',
                    style: theme.textTheme.headlineMedium),
              ),
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Filter by title or instructor',
                  ),
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<CourseModel>>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data!;
                final items = _query.isEmpty
                    ? all
                    : all.where((c) {
                        return c.title.toLowerCase().contains(_query) ||
                            c.instructorName.toLowerCase().contains(_query);
                      }).toList();
                if (items.isEmpty) {
                  return Center(
                    child: Text('No courses match.',
                        style: theme.textTheme.bodyLarge),
                  );
                }
                return Card(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _CourseRow(course: items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseRow extends ConsumerWidget {
  const _CourseRow({required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      leading: SizedBox(
        width: 60,
        height: 40,
        child: course.thumbnailUrl.isEmpty
            ? Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_outlined),
              )
            : Image.network(course.thumbnailUrl, fit: BoxFit.cover),
      ),
      title: Text(course.title),
      subtitle: Text(
        '${course.category} · ${course.level} · ${course.instructorName}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Workflow status pill.
          CourseStatusChip(
            status: CourseStatus.fromId(course.status),
            dense: true,
          ),
          const SizedBox(width: 8),
          if (course.isFeatured)
            Chip(
              label: const Text('Featured'),
              visualDensity: VisualDensity.compact,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.10),
            ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (a) => _action(context, ref, a),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'open', child: Text('Open editor')),
              PopupMenuItem(
                value: 'feature',
                child: Text(course.isFeatured ? 'Unfeature' : 'Feature'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      onTap: () => context.goNamed(
        AdminRoutes.courseEditor,
        pathParameters: {'id': course.id},
      ),
    );
  }

  Future<void> _action(
      BuildContext context, WidgetRef ref, String action) async {
    final ds = ref.read(adminCoursesDataSourceProvider);
    switch (action) {
      case 'open':
        context.goNamed(AdminRoutes.courseEditor,
            pathParameters: {'id': course.id});
        break;
      case 'feature':
        await ds.setFeatured(course.id, !course.isFeatured);
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete course?'),
            content: Text(
                '"${course.title}" and all of its sections, lectures, and '
                'media references will be permanently deleted from Firestore. '
                'Media files in Storage remain — clean those up separately.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (ok == true) await ds.deleteCourse(course.id);
        break;
    }
  }
}
