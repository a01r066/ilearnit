import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/learning_paths/data/models/learning_path_model.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';

/// Minimal "Learning paths" list — mirrors My Courses + Songbooks
/// list. No `DataTable`, no `Card`, no `Material` wrapper without
/// explicit dimensions, no `FilledButton.icon` in an unconstrained
/// Row.
class AdminLearningPathsPage extends ConsumerStatefulWidget {
  const AdminLearningPathsPage({super.key});

  @override
  ConsumerState<AdminLearningPathsPage> createState() =>
      _AdminLearningPathsPageState();
}

class _AdminLearningPathsPageState
    extends ConsumerState<AdminLearningPathsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(adminLearningPathsDataSourceProvider).watchAll();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title (own row).
          Text('Learning paths', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          // Filter + button row — bounded SizedBoxes on the right side.
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Filter by title',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New path'),
                  onPressed: () => _createDraft(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List body.
          Expanded(
            child: StreamBuilder<List<LearningPathModel>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      '${snap.error}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }
                final all = snap.data ?? const <LearningPathModel>[];
                final filtered = _query.isEmpty
                    ? all
                    : all
                        .where((p) => p.title
                            .toLowerCase()
                            .contains(_query.toLowerCase()))
                        .toList();
                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No learning paths yet.'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _LearningPathRow(
                    path: filtered[i],
                    onEdit: () => context.goNamed(
                      AdminRoutes.learningPathEditor,
                      pathParameters: {'id': filtered[i].id},
                    ),
                    onDelete: () => _delete(context, filtered[i].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createDraft(BuildContext context) async {
    final id = await ref.read(adminLearningPathsDataSourceProvider).create(
          title: 'Untitled path',
          summary: '',
          courseIds: const <String>[],
          totalHours: 0,
          isPublished: false,
        );
    if (!context.mounted) return;
    context.goNamed(
      AdminRoutes.learningPathEditor,
      pathParameters: {'id': id},
    );
  }

  Future<void> _delete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete learning path?'),
        content: const Text(
          'This removes the path from the catalogue. The component '
          'courses are not affected.',
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
    await ref.read(adminLearningPathsDataSourceProvider).delete(id);
  }
}

/// Hand-rolled row — same Material+InkWell+Container shape as the
/// other admin list pages. Status uses a chip-style Container, actions
/// are plain IconButtons.
class _LearningPathRow extends StatelessWidget {
  const _LearningPathRow({
    required this.path,
    required this.onEdit,
    required this.onDelete,
  });

  final LearningPathModel path;
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
              const SizedBox(width: 4),
              CircleAvatar(
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.timeline_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path.title.isEmpty ? '(untitled)' : path.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${path.instrument ?? "Mixed"} · '
                      '${path.courseIds.length} courses · '
                      '${path.totalHours.toStringAsFixed(0)}h',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: (path.isPublished
                          ? Colors.green
                          : Colors.amber)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  path.isPublished ? 'Published' : 'Draft',
                  style: const TextStyle(fontSize: 12),
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
