import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/instructors/data/models/instructor_model.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';
import '../data/instructor_backfill_report.dart';

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
  bool _backfilling = false;

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
              // Legacy migration — copy pre-2026-06 auto-id profile
              // docs into `instructors/{uid}` slots and delete the
              // originals. See `migrateLegacyProfiles` in
              // admin_instructor_profiles_datasource.dart for the
              // resolution rules. One-shot; idempotent.
              SizedBox(
                width: 220,
                child: OutlinedButton.icon(
                  icon: _backfilling
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.swap_horiz),
                  label: Text(
                      _backfilling ? 'Migrating…' : 'Migrate legacy profiles'),
                  onPressed: _backfilling ? null : _confirmBackfill,
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

  // ----- Backfill flow ---------------------------------------------------

  Future<void> _confirmBackfill() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Migrate legacy profiles?'),
        content: const SingleChildScrollView(
          child: Text(
            'Copies every pre-2026-06 instructor profile (auto-generated '
            "doc id) into the canonical `instructors/{uid}` slot and "
            "deletes the original.\n\n"
            'Resolution order per legacy doc:\n'
            '  1. The legacy `userId` field, if set.\n'
            '  2. Email match against the users collection.\n'
            '  3. Strict displayName match.\n\n'
            "Already-canonical profiles (doc id is a known uid) are "
            "skipped. Ambiguous matches are skipped and surfaced in "
            "the report so you can resolve them manually.\n\n"
            'Safe to re-run.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Migrate'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _backfilling = true);
    try {
      final report = await ref
          .read(adminInstructorProfilesDataSourceProvider)
          .migrateLegacyProfiles();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _BackfillResultDialog(report: report),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backfill failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _backfilling = false);
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

// ----- Backfill result dialog ---------------------------------------------

/// Summary dialog shown after a backfill run. Headline metrics across
/// the top, then a scrollable list of per-row outcomes. Rendered after
/// the action completes so the admin can audit what happened.
class _BackfillResultDialog extends StatelessWidget {
  const _BackfillResultDialog({required this.report});
  final InstructorBackfillReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Show problematic rows first (ambiguous / errored / no-match) so
    // the admin's eye lands on the things they need to act on.
    final rows = [...report.rows]
      ..sort((a, b) => _orderFor(a.outcome).compareTo(_orderFor(b.outcome)));

    return AlertDialog(
      title: const Text('Backfill complete'),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                    label: 'Scanned',
                    value: report.scanned,
                    color: theme.colorScheme.primary),
                _MetricChip(
                    label: 'Newly linked',
                    value: report.matched,
                    color: Colors.green),
                _MetricChip(
                    label: 'Already linked',
                    value: report.alreadyLinked,
                    color: theme.colorScheme.onSurfaceVariant),
                _MetricChip(
                    label: 'Ambiguous',
                    value: report.ambiguous,
                    color: Colors.orange),
                _MetricChip(
                    label: 'No match',
                    value: report.noMatch,
                    color: theme.colorScheme.error),
                if (report.errored > 0)
                  _MetricChip(
                      label: 'Errored',
                      value: report.errored,
                      color: theme.colorScheme.error),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _BackfillRowTile(row: rows[i]),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  int _orderFor(InstructorBackfillOutcome o) {
    switch (o) {
      case InstructorBackfillOutcome.errored:
        return 0;
      case InstructorBackfillOutcome.ambiguous:
        return 1;
      case InstructorBackfillOutcome.noMatch:
        return 2;
      case InstructorBackfillOutcome.matchedByEmail:
        return 3;
      case InstructorBackfillOutcome.matchedByName:
        return 4;
      case InstructorBackfillOutcome.alreadyLinked:
        return 5;
    }
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BackfillRowTile extends StatelessWidget {
  const _BackfillRowTile({required this.row});
  final InstructorBackfillRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, label) = _badgeFor(row.outcome, theme);
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(
        row.instructorName.isEmpty
            ? '(no name) · ${row.instructorId}'
            : row.instructorName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        row.notes.isEmpty ? label : '$label — ${row.notes}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: row.linkedUserId == null
          ? null
          : SelectableText(
              row.linkedUserId!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }

  (IconData, Color, String) _badgeFor(
    InstructorBackfillOutcome o,
    ThemeData theme,
  ) {
    switch (o) {
      case InstructorBackfillOutcome.matchedByEmail:
        return (Icons.check_circle, Colors.green, 'Linked by email');
      case InstructorBackfillOutcome.matchedByName:
        return (Icons.check_circle_outline, Colors.green, 'Linked by name');
      case InstructorBackfillOutcome.alreadyLinked:
        return (
          Icons.link,
          theme.colorScheme.onSurfaceVariant,
          'Already linked',
        );
      case InstructorBackfillOutcome.ambiguous:
        return (Icons.warning_amber, Colors.orange, 'Ambiguous');
      case InstructorBackfillOutcome.noMatch:
        return (Icons.help_outline, theme.colorScheme.error, 'No match');
      case InstructorBackfillOutcome.errored:
        return (Icons.error_outline, theme.colorScheme.error, 'Errored');
    }
  }
}
