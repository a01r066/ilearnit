import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/instructors/data/models/instructor_model.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';

/// List of instructor profile docs (the public-facing `instructors`
/// collection — separate from the `users` collection's role-based
/// listing on AdminInstructorsPage).
class AdminInstructorProfilesPage extends ConsumerStatefulWidget {
  const AdminInstructorProfilesPage({super.key});

  @override
  ConsumerState<AdminInstructorProfilesPage> createState() =>
      _AdminInstructorProfilesPageState();
}

class _AdminInstructorProfilesPageState
    extends ConsumerState<AdminInstructorProfilesPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final stream =
        ref.watch(adminInstructorProfilesDataSourceProvider).watchAll();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Instructor profiles',
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Public marketing profiles. Separate from user accounts on '
            '"Instructors" page.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Filter by name or instrument',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 200,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New instructor'),
                  onPressed: _create,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<InstructorModel>>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data!;
                final items = _query.isEmpty
                    ? all
                    : all
                        .where((i) =>
                            i.name.toLowerCase().contains(_query) ||
                            (i.primaryInstrument ?? '')
                                .toLowerCase()
                                .contains(_query))
                        .toList();
                if (items.isEmpty) {
                  return _EmptyState(
                    hasFilter: _query.isNotEmpty,
                    onCreate: _create,
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (_, i) => _InstructorRow(
                    instructor: items[i],
                    onEdit: () => context.goNamed(
                      AdminRoutes.instructorProfileEditor,
                      pathParameters: {'id': items[i].id},
                    ),
                    onDelete: () => _confirmDelete(items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    final nameCtrl = TextEditingController(text: 'Unnamed instructor');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create instructor profile'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Name'),
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
    final id = await ref
        .read(adminInstructorProfilesDataSourceProvider)
        .create(
          InstructorModel(id: '', name: nameCtrl.text.trim()),
        );
    if (mounted) {
      context.goNamed(
        AdminRoutes.instructorProfileEditor,
        pathParameters: {'id': id},
      );
    }
  }

  Future<void> _confirmDelete(InstructorModel m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete instructor?'),
        content: Text(
          '"${m.name}" will be permanently removed from the public '
          'instructors directory. Courses authored by them remain '
          'unchanged but their detail page will no longer be reachable.',
        ),
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
    if (ok != true) return;
    await ref
        .read(adminInstructorProfilesDataSourceProvider)
        .delete(m.id);
  }
}

class _InstructorRow extends StatelessWidget {
  const _InstructorRow({
    required this.instructor,
    required this.onEdit,
    required this.onDelete,
  });
  final InstructorModel instructor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: ClipOval(
                  child: instructor.photoUrl.isEmpty
                      ? Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.person_outline),
                        )
                      : Image.network(
                          instructor.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.colorScheme
                                .surfaceContainerHighest,
                            child: const Icon(Icons.person_outline),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(instructor.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    Text(
                      '${instructor.primaryInstrument ?? "—"} · '
                      '${instructor.country ?? "—"} · '
                      '${instructor.studentCount} students',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter, required this.onCreate});
  final bool hasFilter;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (hasFilter) {
      return Center(
        child: Text('No instructors match.',
            style: theme.textTheme.bodyLarge),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline,
              size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No instructor profiles yet',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Seed sample data with `node sample_data/seed_firestore.js`\n'
            'or create a profile manually below.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 220,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create first instructor'),
              onPressed: onCreate,
            ),
          ),
        ],
      ),
    );
  }
}
