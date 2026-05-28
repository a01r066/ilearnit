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
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return Center(
                    child: Text('No pending applications.',
                        style: theme.textTheme.bodyLarge),
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

class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({required this.application});
  final InstructorApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primaryContainer,
                  child: Text(application.displayName.isEmpty
                      ? '?'
                      : application.displayName[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(application.displayName,
                          style: theme.textTheme.titleMedium),
                      Text(application.email,
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (application.years != null)
                  Chip(label: Text('${application.years}y teaching')),
              ],
            ),
            const SizedBox(height: 12),
            if (application.instruments.isNotEmpty)
              Wrap(
                spacing: 6,
                children: [
                  for (final i in application.instruments)
                    Chip(label: Text(i),
                        visualDensity: VisualDensity.compact),
                ],
              ),
            const SizedBox(height: 12),
            Text(application.bio, style: theme.textTheme.bodyMedium),
            if (application.portfolioUrl != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                application.portfolioUrl!,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  onPressed: () => _reject(context, ref),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  onPressed: () => _approve(context, ref),
                ),
              ],
            ),
          ],
        ),
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
