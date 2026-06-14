import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/report_model.dart';
import '../../domain/entities/report.dart';
import '../../domain/entities/report_status.dart';
import '../providers/moderation_providers.dart';

/// In-app moderation surface, opened at `/moderator`.
///
/// **Scope.**
///   • An [UserRole.admin] sees every open report (same query the
///     admin portal uses).
///   • A non-admin [UserRole.moderator] sees only reports tied to
///     courses they own. The page resolves their course list, then
///     scopes the report query with `where('courseId', whereIn:)`.
///
/// **Why this exists alongside the admin portal.** Admins are usually
/// at desks; moderators are usually on phones. The in-app surface lets
/// trusted community moderators triage without needing portal access,
/// and naturally scopes their permissions to their own courses.
class ModeratorReportsPage extends ConsumerWidget {
  const ModeratorReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final role = UserRole.fromId(user?.role.id);

    // Defensive gate — route-level redirect already blocks non-mods,
    // but the page itself should also refuse to render any data if
    // somehow reached without role.
    if (user == null || !role.isModerator) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moderation')),
        body: const Center(child: Text('You do not have access.')),
      );
    }

    final asyncReports = role.isAdmin
        ? ref.watch(openReportsProvider)
        : ref.watch(_moderatorReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderation queue'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            asyncReports.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (rs) => Text(
                '${rs.length} open',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: asyncReports.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Could not load: $e',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
                data: (list) => list.isEmpty
                    ? _Empty(isAdmin: role.isAdmin)
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        // The streams emit `ReportModel` (the Firestore
                        // DTO); the card binds to the entity-shaped
                        // `Report` so its UI uses the strongly-typed
                        // enum fields (contentType.label, etc.). Map
                        // here at the call site.
                        itemBuilder: (_, i) =>
                            _ModReportCard(report: list[i].toEntity()),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.isAdmin});
  final bool isAdmin;
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
          Text(
            isAdmin ? 'No open reports' : 'Nothing to triage',
            style: theme.textTheme.titleMedium,
          ),
          if (!isAdmin) ...[
            const SizedBox(height: 4),
            Text(
              'Reports tied to your courses will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------- Reports scoped to a moderator's courses ----------------------

/// Resolves the signed-in moderator's owned courses, then streams open
/// reports whose `courseId` is in that list. Admin gets the unscoped
/// [openReportsProvider] instead.
///
/// Calls the datasource directly rather than composing
/// [openReportsForCoursesProvider] — `StreamProvider.stream` was
/// removed in Riverpod 2.5+, and nesting two stream providers via
/// `ref.watch(...).when` would lose the family-key uniqueness that
/// makes the cache work.
final _moderatorReportsProvider =
    StreamProvider.autoDispose<List<ReportModel>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield const [];
    return;
  }
  final firestore = ref.watch(firestoreProvider);
  final courses = await firestore
      .collection('courses')
      .where('instructorId', isEqualTo: user.id)
      .get();
  final courseIds = courses.docs.map((d) => d.id).toList();
  if (courseIds.isEmpty) {
    yield const [];
    return;
  }
  yield* ref
      .watch(reportsDataSourceProvider)
      .watchOpenForCourses(courseIds);
});

// ---------- Mobile-shaped report card -----------------------------------

class _ModReportCard extends ConsumerStatefulWidget {
  const _ModReportCard({required this.report});
  final Report report;

  @override
  ConsumerState<_ModReportCard> createState() => _ModReportCardState();
}

class _ModReportCardState extends ConsumerState<_ModReportCard> {
  bool _busy = false;

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
      await ref.read(firestoreProvider).doc(widget.report.contentPath).set(
            {'hidden': true},
            SetOptions(merge: true),
          );
      await _resolve(ReportStatus.actionTaken);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hide failed: $e')),
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
              _Pill(label: r.contentType.label.toUpperCase()),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.reason.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (r.createdAt != null)
                Text(
                  DateFormat.MMMd().add_jm().format(r.createdAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(r.contentSnapshot, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            'by ${r.authorName.isEmpty ? r.authorId : r.authorName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (r.reporterNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer
                    .withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.reporterNotes,
                  style: theme.textTheme.bodyMedium),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: const Text('Hide'),
                  onPressed: _busy ? null : _hideContent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Dismiss'),
                  onPressed: _busy
                      ? null
                      : () => _resolve(ReportStatus.dismissed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
