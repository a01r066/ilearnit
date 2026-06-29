import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../features/courses/data/models/course_model.dart';
import '../../../features/courses/domain/entities/course_status.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';
import 'widgets/course_status_chip.dart';

/// Minimal "My courses" — flat page, no Card / no FilledButton inside a
/// flexed Row / no Image.network without a sized error fallback.
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
                child: Text('My courses',
                    style: theme.textTheme.headlineMedium),
              ),
              SizedBox(
                width: 180,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New course'),
                  onPressed: () => _createCourse(context, ref, user.id,
                      user.displayName ?? user.email),
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

/// Hand-rolled row — InkWell over a Container instead of `Card +
/// ListTile`. `Image.network` always has explicit width/height + an
/// `errorBuilder`, so a failed thumbnail can't collapse to zero size
/// and trigger the hover hit-test assert.
class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course, required this.onOpen});
  final CourseModel course;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 40,
                child: course.thumbnailUrl.isEmpty
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_outlined),
                      )
                    : Image.network(
                        course.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child:
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    Text(
                      '${course.category} · ${course.level} · '
                      '${course.lessonCount} lessons',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Workflow status pill — colored badge matching the
              // CourseStatus enum so instructors can see at a glance
              // which courses are draft / submitted / under review /
              // changes-requested / approved / published.
              CourseStatusChip(
                status: CourseStatus.fromId(course.status),
                dense: true,
              ),
              const SizedBox(width: 8),
              if (course.isFeatured)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Featured',
                      style: TextStyle(fontSize: 12)),
                ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
