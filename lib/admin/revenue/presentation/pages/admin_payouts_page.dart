import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/payout_model.dart';
import '../providers/revenue_providers.dart';
import '../utils/csv_export.dart';

/// /admin/payouts — every payout record. v1 is bookkeeping-only;
/// admin marks a payout as paid AFTER processing the actual transfer
/// out-of-band (bank wire, Stripe Connect, Wise).
class AdminPayoutsPage extends ConsumerWidget {
  const AdminPayoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(adminAllPayoutsStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payouts', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Periodic per-instructor payouts. Bookkeeping only — '
                      'process the actual bank transfer out-of-band, then '
                      'click Mark paid here to close the loop.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 180,
                child: OutlinedButton(
                  onPressed: () => _exportCsv(async.value),
                  child: const Text('Export CSV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          async.when(
            data: (items) => items.isEmpty
                ? const _Empty(
                    text:
                        'No payouts yet. Create one from the instructor row '
                        'on /admin/instructors or via the createPayout API.',
                  )
                : Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        _PayoutRow(p: items[i]),
                        if (i < items.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  void _exportCsv(List<PayoutModel>? items) {
    if (items == null || items.isEmpty) return;
    final csv = buildCsv(
      header: const [
        'Instructor',
        'Period start',
        'Period end',
        'Gross USD',
        'Platform fee',
        'Net USD',
        'Status',
        'Paid at',
        'Method',
        'Txn count',
      ],
      rows: items
          .map((p) => [
                p.instructorName,
                p.periodStart?.toIso8601String() ?? '',
                p.periodEnd?.toIso8601String() ?? '',
                p.grossUsd.toStringAsFixed(2),
                p.platformFee.toStringAsFixed(2),
                p.netUsd.toStringAsFixed(2),
                p.status,
                p.paidAt?.toIso8601String() ?? '',
                p.payoutMethod ?? '',
                p.txnIds.length.toString(),
              ])
          .toList(),
    );
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    triggerCsvDownload(csv: csv, filename: 'payouts_$stamp.csv');
  }
}

class _PayoutRow extends ConsumerWidget {
  const _PayoutRow({required this.p});
  final PayoutModel p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final f = NumberFormat.simpleCurrency(locale: 'en_US', name: 'USD');
    final df = DateFormat.yMMMd();
    final period = p.periodStart != null && p.periodEnd != null
        ? '${df.format(p.periodStart!)} → ${df.format(p.periodEnd!)}'
        : '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.instructorName,
                    style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(period,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                Text('${p.txnIds.length} transactions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Net ${f.format(p.netUsd)}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'Gross ${f.format(p.grossUsd)} − fee '
                '${f.format(p.platformFee)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: p.isPaid
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('PAID',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          )),
                      if (p.paidAt != null)
                        Text(df.format(p.paidAt!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                    ],
                  )
                : FilledButton(
                    onPressed: () => _markPaid(context, ref),
                    child: const Text('Mark paid'),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _markPaid(BuildContext context, WidgetRef ref) async {
    final methodCtrl = TextEditingController(text: 'bank');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark payout paid'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: methodCtrl,
                decoration: const InputDecoration(
                  labelText: 'Method',
                  hintText: 'bank / stripe / wise / …',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Records that the actual transfer has been processed '
                'out-of-band. The status flips to "paid" and the '
                'timestamp is captured server-side.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark paid'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminRevenueDataSourceProvider)
          .markPayoutPaid(payoutId: p.id, method: methodCtrl.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${p.instructorName} payout marked paid.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mark paid failed: $e')),
        );
      }
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(text, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
