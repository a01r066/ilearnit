import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/entities/revenue_summary.dart';
import '../providers/revenue_providers.dart';
import '../utils/csv_export.dart';

/// /my-revenue — instructor's own KPI cards + recent transactions.
///
/// Safe-widget patterns per the learning-path / songbooks docs:
///   • No Card. Plain Container + BoxDecoration with explicit border.
///   • No Chip. Plain Container "pill" for status badges.
///   • No FilledButton.icon adjacent to Expanded / Spacer. Plain
///     buttons wrapped in fixed-width SizedBoxes when they live in a
///     Row with flex children.
class InstructorRevenuePage extends ConsumerWidget {
  const InstructorRevenuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Center(child: Text('Sign in required.'));
    }
    final theme = Theme.of(context);

    final summaryAsync =
        ref.watch(instructorRevenueSummaryProvider(user.id));
    final txnsAsync =
        ref.watch(instructorTransactionsStreamProvider(user.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My revenue',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Earnings, transactions, and per-course breakdown '
                      'for your courses. Refunds are excluded from totals.',
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
                  onPressed: () => _exportCsv(txnsAsync.value),
                  child: const Text('Export CSV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── KPI cards ────────────────────────────────────────
          summaryAsync.when(
            data: (s) => _KpiRow(summary: s),
            loading: () => const _KpiSkeleton(),
            error: (e, _) => _ErrorBlock(message: '$e'),
          ),
          const SizedBox(height: 24),

          // ── By-course list ───────────────────────────────────
          summaryAsync.maybeWhen(
            data: (s) => _ByCourseCard(summary: s),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // ── Recent transactions ──────────────────────────────
          _SectionTitle(
            title: 'Recent transactions',
            subtitle:
                'Live stream of purchases on your courses. Refunds '
                'flagged inline.',
          ),
          const SizedBox(height: 12),
          txnsAsync.when(
            data: (list) => _TransactionsList(items: list),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorBlock(message: '$e'),
          ),
        ],
      ),
    );
  }

  void _exportCsv(List<TransactionModel>? items) {
    if (items == null || items.isEmpty) return;
    final csv = buildCsv(
      header: const [
        'Date',
        'Course',
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
    triggerCsvDownload(csv: csv, filename: 'my_revenue_$stamp.csv');
  }
}

// ── KPI cards ────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.summary});
  final RevenueSummary summary;

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.simpleCurrency(locale: 'en_US', name: 'USD');
    return Row(
      children: [
        Expanded(
          child: _Kpi(
            label: 'Revenue (lifetime)',
            value: f.format(summary.totalRevenueUsd),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _Kpi(
            label: 'Revenue (this month)',
            value: f.format(summary.monthRevenueUsd),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _Kpi(
            label: 'Students',
            value: '${summary.totalStudents}',
            sub: '${summary.totalEnrollments} enrollments',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _Kpi(
            label: 'Refunds',
            value: '${summary.refundCount}',
          ),
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, this.sub});
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 6),
          Text(value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ],
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Row(
        children: List.generate(
          4,
          (_) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── By-course breakdown ─────────────────────────────────────────────

class _ByCourseCard extends StatelessWidget {
  const _ByCourseCard({required this.summary});
  final RevenueSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.byCourse.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final f = NumberFormat.simpleCurrency(locale: 'en_US', name: 'USD');
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
          Text('Revenue by course',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (var i = 0; i < summary.byCourse.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.byCourse[i].courseTitle.isEmpty
                            ? '(untitled)'
                            : summary.byCourse[i].courseTitle,
                        style: theme.textTheme.bodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${summary.byCourse[i].enrollments} enrollments',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  f.format(summary.byCourse[i].revenueUsd),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (i < summary.byCourse.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Transactions list ───────────────────────────────────────────────

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({required this.items});
  final List<TransactionModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Center(child: Text('No transactions yet.')),
      );
    }
    final shown = items.take(50).toList();
    return Column(
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          _TransactionRow(t: shown[i]),
          if (i < shown.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.t});
  final TransactionModel t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = NumberFormat.simpleCurrency(locale: 'en_US', name: 'USD');
    final df = DateFormat.yMMMd().add_jm();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              _StatusPill(status: t.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = switch (status) {
      'paid' => (theme.colorScheme.primary, theme.colorScheme.onPrimary),
      'refunded' => (theme.colorScheme.error, theme.colorScheme.onError),
      _ => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: colors.$2,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (subtitle != null)
          Text(subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
      ],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SelectableText(message,
          style: TextStyle(color: theme.colorScheme.onErrorContainer)),
    );
  }
}
