import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../features/moderation/domain/entities/report.dart';
import '../../../features/moderation/domain/entities/report_status.dart';
import '../../../features/moderation/presentation/providers/moderation_providers.dart';
import '../../../shared/providers/firebase_providers.dart';

/// Admin-only triage queue for UGC reports.
///
/// Streams `reports/{id}` where `status == open`, newest first. Each
/// row exposes three actions:
///
///   • **Hide content** — sets the original doc's `hidden: true` field
///     so consumer queries can filter it out. Atomically resolves the
///     report as [ReportStatus.actionTaken].
///   • **Ban author** — flips `users/{authorId}.isSuspended = true`.
///     Resolves the report as [ReportStatus.actionTaken].
///   • **Dismiss** — closes the report as [ReportStatus.dismissed]
///     without touching the original content.
///
/// All three actions are gated by Firestore rules (`isAdmin()`), so a
/// non-admin getting past the route gate still can't mutate.
class AdminReportsPage extends ConsumerWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reports = ref.watch(openReportsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Text('Open reports', style: theme.textTheme.headlineSmall),
              const Spacer(),
              reports.when(
                data: (rs) => Text('${rs.length} pending',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: reports.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Could not load reports: $e',
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
              data: (list) => list.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      // Streams emit `ReportModel`; the card binds to
                      // the entity-shaped `Report` so enum fields are
                      // strongly typed. Map at the call site.
                      itemBuilder: (_, i) =>
                          _ReportCard(report: list[i].toEntity()),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text('No open reports', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Nothing to triage right now. Nice.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      ),
    );
  }
}

// ---------- Report card --------------------------------------------------

class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard({required this.report});
  final Report report;

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  bool _busy = false;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolve(ReportStatus status) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final reviewer = ref.read(currentUserProvider);
      await ref.read(reportsDataSourceProvider).resolve(
            reportId: widget.report.id,
            status: status,
            reviewerId: reviewer?.id ?? '',
            reviewerName: reviewer?.displayName ?? '',
            resolutionNotes: _notesCtrl.text,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resolve failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _hideContent() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final firestore = ref.read(firestoreProvider);
      // Mark the original doc hidden. Consumer queries can filter on
      // `hidden != true`. Merge so we don't clobber other fields.
      await firestore
          .doc(widget.report.contentPath)
          .set({'hidden': true}, SetOptions(merge: true));
      await _resolve(ReportStatus.actionTaken);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hide failed: $e')),
      );
    }
  }

  Future<void> _banAuthor() async {
    if (_busy || widget.report.authorId.isEmpty) return;
    setState(() => _busy = true);
    try {
      final firestore = ref.read(firestoreProvider);
      await firestore
          .collection('users')
          .doc(widget.report.authorId)
          .set({'isSuspended': true}, SetOptions(merge: true));
      await _resolve(ReportStatus.actionTaken);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ban failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.report;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(
                label: r.contentType.label.toUpperCase(),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _Pill(
                label: r.reason.label,
                color: theme.colorScheme.error,
              ),
              const Spacer(),
              if (r.createdAt != null)
                Text(
                  DateFormat.yMd().add_jm().format(r.createdAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Reported content',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 4),
          Text(
            r.contentSnapshot.isEmpty
                ? '(no excerpt captured)'
                : r.contentSnapshot,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Author: ${r.authorName.isEmpty ? r.authorId : r.authorName}  ·  '
            'Reporter: ${r.reporterName.isEmpty ? r.reporterId : r.reporterName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (r.reporterNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Reporter notes',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 4),
            Text(r.reporterNotes, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            enabled: !_busy,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Resolution notes (optional, audit trail)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.visibility_off_outlined),
                label: const Text('Hide content'),
                onPressed: _busy ? null : _hideContent,
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.person_off_outlined),
                label: const Text('Ban author'),
                onPressed: (_busy || r.authorId.isEmpty) ? null : _banAuthor,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Dismiss'),
                onPressed: _busy
                    ? null
                    : () => _resolve(ReportStatus.dismissed),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

