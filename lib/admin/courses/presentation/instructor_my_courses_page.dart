import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../features/courses/data/models/course_model.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';

/// Lists courses owned by the signed-in instructor + a button to create a
/// new one.
class InstructorMyCoursesPage extends ConsumerWidget {
  const InstructorMyCoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final stream =
        ref.watch(adminCoursesDataSourceProvider).watchMyCourses(user.id);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('My courses', style: theme.textTheme.headlineMedium),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New course'),
                onPressed: () => _createCourse(context, ref, user.id,
                    user.displayName ?? user.email),
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
                final items = snap.data!;
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No courses yet — create your first one.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _CourseRow(
                    course: items[i],
                    onOpen: () => context.goNamed(
                      AdminRoutes.courseEditor,
                      pathParameters: {'id': items[i].id},
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createCourse(
    BuildContext context,
    WidgetRef ref,
    String instructorId,
    String instructorName,
  ) async {
    final titleCtrl = TextEditingController(text: 'Untitled course');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create course'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final id = await ref.read(adminCoursesDataSourceProvider).createCourse(
          CourseModel(
            id: '', // populated by datasource
            title: titleCtrl.text.trim(),
            summary: '',
            thumbnailUrl: '',
            category: 'guitar',
            level: 'beginner',
            instructorId: instructorId,
            instructorName: instructorName,
          ),
        );
    if (context.mounted) {
      context.goNamed(AdminRoutes.courseEditor, pathParameters: {'id': id});
    }
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course, required this.onOpen});
  final CourseModel course;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
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
          '${course.category} · ${course.level} · '
          '${course.lessonCount} lessons',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (course.isFeatured)
              Chip(
                label: const Text('Featured'),
                visualDensity: VisualDensity.compact,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.10),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }
}
