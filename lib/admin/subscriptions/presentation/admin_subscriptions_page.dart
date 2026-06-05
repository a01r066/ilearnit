import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/providers/admin_providers.dart';
import '../data/admin_subscriptions_datasource.dart';

/// Admin-only: live list of users with an active Personal Plan
/// subscription. Stats card up top + table below with revoke + extend
/// actions per row.
class AdminSubscriptionsPage extends ConsumerWidget {
  const AdminSubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream =
        ref.watch(adminSubscriptionsDataSourceProvider).watchAll();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Subscriptions', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<SubscriberRow>>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data!;
                final active = all
                    .where((r) =>
                        r.subscription.expiresAt != null &&
                        r.subscription.expiresAt!.isAfter(DateTime.now()))
                    .toList()
                  ..sort((a, b) => b.subscription.expiresAt!
                      .compareTo(a.subscription.expiresAt!));

                final monthly = active
                    .where((r) => r.subscription.planId == 'monthly')
                    .length;
                final yearly = active
                    .where((r) => r.subscription.planId == 'yearly')
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _Stat(
                            label: 'Active total',
                            value: active.length.toString()),
                        const SizedBox(width: 16),
                        _Stat(label: 'Monthly', value: monthly.toString()),
                        const SizedBox(width: 16),
                        _Stat(label: 'Yearly', value: yearly.toString()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: active.isEmpty
                          ? Center(
                              child: Text('No active subscriptions.',
                                  style: theme.textTheme.bodyLarge),
                            )
                          : Card(
                              child: ListView.separated(
                                itemCount: active.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) => _SubscriberRow(
                                  row: active[i],
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.displaySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriberRow extends ConsumerWidget {
  const _SubscriberRow({required this.row});
  final SubscriberRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMMMd();
    final plan = row.subscription.planId ?? '—';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text((row.user.displayName ?? row.user.email)
            .characters
            .first
            .toUpperCase()),
      ),
      title: Text(row.user.displayName ?? row.user.email),
      subtitle: Text([
        plan,
        if (row.subscription.autoRenew) 'auto-renew',
        if (row.subscription.startedAt != null)
          'since ${dateFmt.format(row.subscription.startedAt!)}',
        if (row.subscription.expiresAt != null)
          'expires ${dateFmt.format(row.subscription.expiresAt!)}',
      ].join(' · ')),
      trailing: PopupMenuButton<String>(
        onSelected: (a) => _action(context, ref, a),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'extend7', child: Text('Extend +7 days')),
          PopupMenuItem(value: 'extend30', child: Text('Extend +30 days')),
          PopupMenuItem(value: 'revoke', child: Text('Revoke now')),
        ],
      ),
    );
  }

  Future<void> _action(
      BuildContext context, WidgetRef ref, String action) async {
    final ds = ref.read(adminSubscriptionsDataSourceProvider);
    switch (action) {
      case 'extend7':
        await ds.extendByDays(row.user.id, 7);
        break;
      case 'extend30':
        await ds.extendByDays(row.user.id, 30);
        break;
      case 'revoke':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Revoke subscription?'),
            content: Text(
                '${row.user.displayName ?? row.user.email} will lose access '
                'immediately. The App Store / Play Store subscription is '
                'NOT cancelled — they must do that in OS settings.'),
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
        if (ok == true) await ds.revokeNow(row.user.id);
        break;
    }
  }
}
