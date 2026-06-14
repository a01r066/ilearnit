import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/data/models/user_model.dart';
import '../../../features/instructors/data/models/instructor_model.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';
import '../data/instructor_backfill_report.dart';

/// Admin's list of active instructors. Each row exposes: suspend/restore,
/// revoke instructor role (back to student), and a "Create profile" /
/// "Edit profile" affordance bridging this user to a public-facing
/// `instructors/{id}` doc.
///
/// **Layout note.** Hand-rolled primitives (Container + Row + ClipOval)
/// rather than `Card` + `ListTile` + `Chip` + `.icon` button variants.
/// The Material 3 versions of those classes triggered "BoxConstraints
/// forces an infinite width" and "Cannot hit test a render box with no
/// size" errors when nested with several flex children in the trailing
/// slot — same trap that bit `AdminApplicationsPage`. Hand-rolled
/// layout sidesteps it entirely.
class AdminInstructorsPage extends ConsumerStatefulWidget {
  const AdminInstructorsPage({super.key});

  @override
  ConsumerState<AdminInstructorsPage> createState() =>
      _AdminInstructorsPageState();
}

class _AdminInstructorsPageState extends ConsumerState<AdminInstructorsPage> {
  bool _syncing = false;

  Future<void> _confirmSyncAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync profiles for all instructors?'),
        content: const SingleChildScrollView(
          child: Text(
            'For every user with role=instructor, ensures an `instructors/{id}` '
            "profile exists with `userId` set. Instructors that already have a "
            "profile are skipped.\n\n"
            "This is the bulk version of the per-row 'Create profile' button — "
            "use it to bring every instructor in line with the same flow at "
            "once. Safe to re-run.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sync'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _syncing = true);
    try {
      final report = await ref
          .read(adminInstructorProfilesDataSourceProvider)
          .syncProfilesForAllInstructors();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _SyncResultDialog(report: report),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream =
        ref.watch(adminCoursesDataSourceProvider).watchInstructors();
    final profilesStream =
        ref.watch(adminInstructorProfilesDataSourceProvider).watchAll();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text('Instructors',
                    style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(width: 12),
              _MiniButton.tonal(
                label: _syncing ? 'Syncing…' : 'Sync all profiles',
                onTap: _syncing ? null : _confirmSyncAll,
                showSpinner: _syncing,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return Center(
                    child: Text('No instructors yet.',
                        style: theme.textTheme.bodyLarge),
                  );
                }
                return StreamBuilder<List<InstructorModel>>(
                  stream: profilesStream,
                  builder: (context, profSnap) {
                    // Doc id IS the uid under the post-2026-06
                    // schema. Build a Set of which uids already have a
                    // profile so each row can render "Create" vs
                    // "Edit" without an extra Firestore read.
                    final profileUids = <String>{
                      for (final p
                          in profSnap.data ?? const <InstructorModel>[])
                        p.id,
                    };
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: theme.dividerColor),
                        itemBuilder: (_, i) => _InstructorRow(
                          user: items[i],
                          // Under the new schema doc-id is the uid,
                          // so the row's "profile id" === the user's
                          // uid when present.
                          profileId: profileUids.contains(items[i].id)
                              ? items[i].id
                              : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorRow extends ConsumerStatefulWidget {
  const _InstructorRow({required this.user, this.profileId});
  final UserModel user;
  final String? profileId;

  @override
  ConsumerState<_InstructorRow> createState() => _InstructorRowState();
}

class _InstructorRowState extends ConsumerState<_InstructorRow> {
  bool _creating = false;

  Future<void> _createProfile() async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final id = await ref
          .read(adminInstructorProfilesDataSourceProvider)
          .createFromUser(
            uid: widget.user.id,
            displayName: widget.user.displayName,
            email: widget.user.email,
            photoUrl: widget.user.photoUrl,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile created — opening editor.'),
          duration: Duration(seconds: 2),
        ),
      );
      context.goNamed(
        AdminRoutes.instructorProfileEditor,
        pathParameters: {'id': id},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create profile failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _openProfile() {
    final id = widget.profileId;
    if (id == null) return;
    context.goNamed(
      AdminRoutes.instructorProfileEditor,
      pathParameters: {'id': id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.user;
    final displayName =
        (user.displayName?.isNotEmpty ?? false) ? user.displayName! : user.email;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar — hand-rolled ClipOval over a fixed-size Container.
          // Avoids CircleAvatar's intrinsic-size dance which is one of
          // the things the M3 ListTile gets wrong.
          _AvatarCircle(label: displayName, theme: theme),
          const SizedBox(width: 12),
          // Identity column. `Expanded` here so the right-side actions
          // shrink to fit instead of pushing the layout to infinite
          // width — that's the exact failure mode of the previous
          // ListTile-trailing-with-multiple-children setup.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Suspended pill — hand-rolled, not Chip.
          if (user.isSuspended) ...[
            _Pill(
              text: 'Suspended',
              fg: theme.colorScheme.error,
              bg: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 12),
          ],
          // Profile state — hand-rolled buttons. Even plain FilledButton
          // / TextButton trip the M3 layout bug here (ConstrainedBox
          // inside FilledButton asks for infinite width when the
          // parent Row gives unbounded loose constraints). InkWell +
          // Container with explicit padding sidesteps the whole
          // negotiation.
          if (widget.profileId != null)
            _MiniButton.text(
              label: 'Edit profile',
              onTap: _openProfile,
            )
          else
            _MiniButton.tonal(
              label: _creating ? 'Creating…' : 'Create profile',
              onTap: _creating ? null : _createProfile,
              showSpinner: _creating,
            ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: 'Actions',
            onSelected: (a) => _action(context, ref, a),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle',
                child: Text(user.isSuspended ? 'Restore' : 'Suspend'),
              ),
              const PopupMenuItem(
                value: 'revoke',
                child: Text('Revoke instructor role'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _action(
      BuildContext context, WidgetRef ref, String action) async {
    final ds = ref.read(adminCoursesDataSourceProvider);
    final user = widget.user;
    if (action == 'toggle') {
      await ds.setUserSuspended(
        userId: user.id,
        suspended: !user.isSuspended,
      );
    } else if (action == 'revoke') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Revoke instructor role?'),
          content: Text(
              '${user.displayName ?? user.email} will become a regular '
              'student. Their existing courses stay in Firestore but they '
              'can no longer edit them.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Revoke'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await ds.revokeInstructorRole(user.id);
    }
  }
}

// ---------- Hand-rolled primitives ---------------------------------------

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.label, required this.theme});
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final letter =
        label.isEmpty ? '?' : label.characters.first.toUpperCase();
    return ClipOval(
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        color: theme.colorScheme.primaryContainer,
        child: Text(
          letter,
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.fg, required this.bg});
  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ---------- Sync result dialog -------------------------------------------

class _SyncResultDialog extends StatelessWidget {
  const _SyncResultDialog({required this.report});
  final InstructorBackfillReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Sync complete'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SyncChip(
                  label: 'Scanned',
                  value: report.scanned,
                  color: theme.colorScheme.primary,
                ),
                _SyncChip(
                  label: 'Created',
                  // Reuses `matched` since the bulk action only fills
                  // the matchedByEmail bucket — see
                  // `syncProfilesForAllInstructors`.
                  value: report.matched,
                  color: Colors.green,
                ),
                _SyncChip(
                  label: 'Already had one',
                  value: report.alreadyLinked,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                if (report.errored > 0)
                  _SyncChip(
                    label: 'Errored',
                    value: report.errored,
                    color: theme.colorScheme.error,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.matched > 0
                  ? 'New profiles are live. Tapping the instructor name '
                      'on a course detail page on mobile will now resolve.'
                  : 'Every instructor already had a profile — nothing to do.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
}

class _SyncChip extends StatelessWidget {
  const _SyncChip({
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
              fontSize: 15,
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

/// Compact hand-rolled button used inside the row.
///
/// Replacement for `FilledButton.tonal` / `TextButton` next to
/// flex children. Material 3's M3 buttons internally use a
/// `ConstrainedBox` with `maxWidth: Infinity` that misbehaves when
/// the parent gives loose unbounded constraints — we sidestep that
/// by drawing the button ourselves with `InkWell` over a sized
/// `Container`.
enum _MiniButtonStyle { tonal, text }

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.onTap,
    required this.style,
    this.showSpinner = false,
  });

  const _MiniButton.tonal({
    required this.label,
    required this.onTap,
    this.showSpinner = false,
  }) : style = _MiniButtonStyle.tonal;

  const _MiniButton.text({
    required this.label,
    required this.onTap,
  })  : style = _MiniButtonStyle.text,
        showSpinner = false;

  final String label;
  final VoidCallback? onTap;
  final _MiniButtonStyle style;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    final Color bg;
    final Color fg;
    switch (style) {
      case _MiniButtonStyle.tonal:
        bg = theme.colorScheme.secondaryContainer
            .withValues(alpha: enabled ? 1.0 : 0.4);
        fg = theme.colorScheme.onSecondaryContainer
            .withValues(alpha: enabled ? 1.0 : 0.5);
      case _MiniButtonStyle.text:
        bg = Colors.transparent;
        fg = theme.colorScheme.primary
            .withValues(alpha: enabled ? 1.0 : 0.5);
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          // Row(mainAxisSize: min) — the explicit `min` is what tells
          // the parent "size me to my children", which fixes the
          // unbounded-width chain that crashes FilledButton.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpinner) ...[
                SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
