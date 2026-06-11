import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../shared/providers/admin_providers.dart';
import '../domain/entities/instructor_application.dart';

/// Admin queue of pending instructor applications. Admin can approve (which
/// promotes the user to instructor) or reject with an optional reason.
class AdminApplicationsPage extends ConsumerWidget {
  const AdminApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream =
        ref.watch(instructorApplicationDataSourceProvider).watchPending();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pending applications', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<InstructorApplication>>(
              stream: stream,
              builder: (context, snap) {
                // Surface stream errors instead of spinning forever.
                // Most likely culprits: missing composite index
                // (FAILED_PRECONDITION), Firestore rules denial
                // (PERMISSION_DENIED), or a network blip.
                if (snap.hasError) {
                  // ConstrainedBox(maxWidth) is mandatory here — without
                  // it the Center>Column{min}>SelectableText chain throws
                  // "BoxConstraints forces an infinite width" the moment
                  // layout asks for an intrinsic width, because the
                  // multiline Text has no definite maxWidth to wrap at.
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                size: 40,
                                color: theme.colorScheme.error),
                            const SizedBox(height: 12),
                            Text(
                              'Could not load applications.',
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              '${snap.error}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  // Same ConstrainedBox(maxWidth) trap as the error
                  // state above — the body-copy Text needs a definite
                  // wrap width inside Center>Column{min}.
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 40,
                              color:
                                  theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No pending applications.',
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Applicants land here after they sign in '
                              'to the admin portal and fill out the '
                              'apply form.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme
                                    .colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _ApplicationCard(application: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Hand-rolled card — written with the same safe-pattern rules the
/// learning-path / songbooks editors use:
///   • No `Card`. Plain `Container` + `BoxDecoration` for dimensions.
///   • No `Chip` / `CircleAvatar`. Hand-rolled pills + avatar circles
///     (Material widgets without explicit dimensions are the known
///     source of "Cannot hit test a render box with no size" floods).
///   • No `Spacer` next to `FilledButton.icon` / `TextButton.icon`.
///     The action row uses an `Align(Alignment.centerRight)` and
///     SizedBox-wrapped plain buttons (no `.icon` variants).
///   • Every interactive child gets an explicit width so the layout
///     never has to compute an intrinsic width.
class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({required this.application});
  final InstructorApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final initials = application.displayName.isEmpty
        ? '?'
        : application.displayName[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────
          Row(
            children: [
              _AvatarCircle(
                letter: initials,
                color: theme.colorScheme.primaryContainer,
                textColor: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.displayName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      application.email,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (application.years != null) ...[
                const SizedBox(width: 12),
                _Pill(label: '${application.years}y teaching'),
              ],
            ],
          ),

          // ── Instruments (hand-rolled pills, no Chip) ──────────
          if (application.instruments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final i in application.instruments)
                  _Pill(label: i, compact: true),
              ],
            ),
          ],

          // ── Bio ───────────────────────────────────────────────
          const SizedBox(height: 12),
          Text(application.bio, style: theme.textTheme.bodyMedium),

          // ── Portfolio URL (optional) ──────────────────────────
          if (application.portfolioUrl != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              application.portfolioUrl!,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ],

          // ── Action row — Align + SizedBox-wrapped plain buttons.
          //    No Spacer. No `.icon` variants. ────────────────────
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  child: TextButton(
                    onPressed: () => _reject(context, ref),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: FilledButton(
                    onPressed: () => _approve(context, ref),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;
    await ref
        .read(instructorApplicationDataSourceProvider)
        .approve(applicationId: application.id, adminUid: admin.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${application.displayName} approved.')),
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject application'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Shown to the applicant',
          ),
          minLines: 2,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;
    await ref.read(instructorApplicationDataSourceProvider).reject(
          applicationId: application.id,
          adminUid: admin.id,
          reason: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
        );
  }
}

// ───────── Hand-rolled primitives — explicit dimensions, no Material ──────

/// Replacement for `CircleAvatar`. Fixed 40×40 so layout never has to
/// query an intrinsic size from a Material ancestor.
class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.letter,
    required this.color,
    required this.textColor,
  });
  final String letter;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

/// Replacement for `Chip`. Plain `Container` with rounded background.
/// `compact: true` shrinks padding for the instrument tags row.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.compact = false});
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
