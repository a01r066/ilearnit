import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/learning_paths/data/models/learning_path_model.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';

/// Admin-only: every learning path (draft + published). Mirrors the
/// AdminSongbooksPage structure — filter + list + actions.
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Learning paths',
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Filter by title',
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New path'),
                onPressed: () => _createDraft(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                return _Table(
                  items: filtered,
                  onEdit: (id) => context.goNamed(
                    AdminRoutes.learningPathEditor,
                    pathParameters: {'id': id},
                  ),
                  onDelete: (id) async {
                    final ok = await _confirmDelete(context);
                    if (!ok) return;
                    await ref
                        .read(adminLearningPathsDataSourceProvider)
                        .delete(id);
                  },
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

  Future<bool> _confirmDelete(BuildContext context) async {
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
    return ok ?? false;
  }
}

class _Table extends StatelessWidget {
  const _Table({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<LearningPathModel> items;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Instrument')),
            DataColumn(label: Text('Courses'), numeric: true),
            DataColumn(label: Text('Hours'), numeric: true),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('')),
          ],
          rows: [
            for (final p in items)
              DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 320,
                      child: Text(
                        p.title.isEmpty ? '(untitled)' : p.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(p.instrument ?? '—')),
                  DataCell(Text('${p.courseIds.length}')),
                  DataCell(Text(p.totalHours.toStringAsFixed(0))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (p.isPublished ? Colors.green : Colors.amber)
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(p.isPublished ? 'Published' : 'Draft'),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onEdit(p.id),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => onDelete(p.id),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
