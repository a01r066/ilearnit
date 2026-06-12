import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction_model.dart';
import '../providers/revenue_providers.dart';
import '../utils/csv_export.dart';

/// /admin/transactions — every transaction across the platform.
/// Filter by status, refund per row.
class AdminTransactionsPage extends ConsumerStatefulWidget {
  const AdminTransactionsPage({super.key});

  @override
  ConsumerState<AdminTransactionsPage> createState() =>
      _AdminTransactionsPageState();
}

class _AdminTransactionsPageState
    extends ConsumerState<AdminTransactionsPage> {
  String? _statusFilter; // null = all

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(adminAllTransactionsStreamProvider(_statusFilter));

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
                    Text('All transactions',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Every purchase across every instructor + course. '
                      'Refunding marks the transaction and cancels the '
                      'related enrollment.',
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
          // ── Status filter as plain ChoiceChip-style buttons ──
          Wrap(
            spacing: 8,
            children: [
              _filterButton(label: 'All', value: null),
              _filterButton(label: 'Paid', value: 'paid'),
              _filterButton(label: 'Refunded', value: 'refunded'),
              _filterButton(label: 'Pending', value: 'pending'),
            ],
          ),
          const SizedBox(height: 20),
          async.when(
            data: (items) => items.isEmpty
                ? const _Empty(text: 'No transactions match the filter.')
                : Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        _AdminTransactionRow(t: items[i]),
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

  Widget _filterButton({required String label, required String? value}) {
    final selected = _statusFilter == value;
    return SizedBox(
      width: 110,
      child: selected
          ? FilledButton(
              onPressed: () => setState(() => _statusFilter = value),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: () => setState(() => _statusFilter = value),
              child: Text(label),
            ),
    );
  }

  void _exportCsv(List<TransactionModel>? items) {
    if (items == null || items.isEmpty) return;
    final csv = buildCsv(
      header: const [
        'Date',
        'Course',
        'Instructor',
        'Student',
        'Email',
        'Amount USD',
        'Status',
        'Platform',
        'Last4',
        'Transaction ID',
      ],
      rows: items
          .map((t) => [
                t.createdAt?.toIso8601String() ?? '',
                t.courseTitle,
                t.instructorName,
                t.studentName,
                t.studentEmail,
                t.amountUsd.toStringAsFixed(2),
                t.status,
                t.platform,
                t.last4 ?? '',
                t.id,
              ])
          .toList(),
    );
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    triggerCsvDownload(csv: csv, filename: 'admin_transactions_$stamp.csv');
  }
}

class _AdminTransactionRow extends ConsumerWidget {
  const _AdminTransactionRow({required this.t});
  final TransactionModel t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final f = NumberFormat.simpleCurrency(locale: 'en_US', name: 'USD');
    final df = DateFormat.yMMMd().add_jm();

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
                Text(
                  t.courseTitle.isEmpty ? '(untitled)' : t.courseTitle,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Instructor: ${t.instructorName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${t.studentName} · ${t.studentEmail} · ${t.platform}'
                  '${t.last4 != null ? ' · •••• ${t.last4}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  t.createdAt == null ? '' : df.format(t.createdAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                f.format(t.amountUsd),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  decoration: t.isRefunded
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              _Pill(
                label: t.status.toUpperCase(),
                bg: t.isRefunded
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                fg: t.isRefunded
                    ? theme.colorScheme.onError
                    : theme.colorScheme.onPrimary,
              ),
            ],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: t.isRefunded
                ? Text('Refunded',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ))
                : OutlinedButton(
                    onPressed: () => _refund(context, ref, t),
                    child: const Text('Refund'),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _refund(
      BuildContext context, WidgetRef ref, TransactionModel t) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refund transaction'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${t.studentName} · ${t.courseTitle} · \$'
                '${t.amountUsd.toStringAsFixed(2)}',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Visible in the student\'s refund email.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Marks the transaction refunded and cancels the matching '
                'enrollment. No actual money is moved — process the '
                'storefront refund out-of-band.',
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
            child: const Text('Refund'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRevenueDataSourceProvider).refundTransaction(
            transactionId: t.id,
            reason: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refund processed for ${t.courseTitle}.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refund failed: $e')),
        );
      }
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(text)),
    );
  }
}
