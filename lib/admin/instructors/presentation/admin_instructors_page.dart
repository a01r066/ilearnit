import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/data/models/user_model.dart';
import '../../shared/providers/admin_providers.dart';

/// Admin's list of active instructors. Each row exposes: suspend/restore,
/// revoke instructor role (back to student).
class AdminInstructorsPage extends ConsumerWidget {
  const AdminInstructorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream =
        ref.watch(adminCoursesDataSourceProvider).watchInstructors();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Instructors', style: theme.textTheme.headlineMedium),
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
                return Card(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _InstructorRow(user: items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorRow extends ConsumerWidget {
  const _InstructorRow({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text((user.displayName ?? user.email).characters.first
            .toUpperCase()),
      ),
      title: Text(user.displayName ?? user.email),
      subtitle: Text(user.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user.isSuspended)
            Chip(
              label: const Text('Suspended'),
              backgroundColor:
                  theme.colorScheme.errorContainer.withValues(alpha: 0.4),
              visualDensity: VisualDensity.compact,
            ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
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
