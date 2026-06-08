import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/analytics_snapshot.dart';
import '../../domain/entities/revenue_point.dart';
import '../providers/analytics_providers.dart';
import '../providers/analytics_state.dart';
import '../widgets/cohort_heatmap.dart';
import '../widgets/funnel_strip.dart';
import '../widgets/plan_breakdown_chart.dart';
import '../widgets/revenue_line_chart.dart';

/// Admin-only revenue + cohort dashboard. Reachable from the side-nav
/// "Analytics" item and the dashboard stat tile.
class AdminAnalyticsPage extends ConsumerWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(analyticsNotifierProvider);
    final notifier = ref.read(analyticsNotifierProvider.notifier);
    final snapshotAsync = ref.watch(analyticsSnapshotProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue + cohorts',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Recognised revenue and retention by signup '
                      'cohort. Data is computed live — hit Refresh '
                      'for the latest.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _RangeChooser(
                value: state.range,
                onChanged: notifier.setRange,
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: 'Refresh',
                onPressed: snapshotAsync.isLoading
                    ? null
                    : () => ref.invalidate(analyticsSnapshotProvider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 24),
          snapshotAsync.when(
            loading: () => const SizedBox(
              height: 320,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorCard(error: e.toString()),
            data: (snap) => _Body(snapshot: snap),
          ),
        ],
      ),
    );
  }
}

class _RangeChooser extends StatelessWidget {
  const _RangeChooser({required this.value, required this.onChanged});
  final AnalyticsRange value;
  final ValueChanged<AnalyticsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AnalyticsRange>(
      segments: const [
        ButtonSegment(
            value: AnalyticsRange.last90Days, label: Text('90d')),
        ButtonSegment(
            value: AnalyticsRange.last6Months, label: Text('6m')),
        ButtonSegment(
            value: AnalyticsRange.last12Months, label: Text('12m')),
        ButtonSegment(
            value: AnalyticsRange.ytd, label: Text('YTD')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Failed to load analytics: $error',
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = snapshot;
    final money = NumberFormat.currency(symbol: '\$');
    final compact = NumberFormat.compactCurrency(symbol: '\$');

    // `stretch` makes every child receive a tight, bounded width from
    // the Column. With `start` the cross-axis was loose, and
    // `width: double.infinity` on the chart Container leaked an
    // infinite width into fl_chart's AspectRatio during intrinsic
    // measurement, throwing "BoxConstraints forces an infinite width"
    // on every mouse hover.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI row — MRR, total revenue in window, paying users.
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _KpiCard(
              label: 'MRR',
              value: compact.format(s.mrrUsd),
              caption: 'Active subscriptions × monthly value.',
              color: theme.colorScheme.primary,
              inverted: true,
            ),
            _KpiCard(
              label: 'Revenue (window)',
              value: compact.format(s.totalRevenueUsd),
              caption:
                  '${DateFormat.yMMMd().format(s.windowStart)} – ${DateFormat.yMMMd().format(s.windowEnd)}',
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            _KpiCard(
              label: 'Paying users',
              value: s.funnel.payingUsers.toString(),
              caption:
                  '${(s.funnel.conversionRate * 100).toStringAsFixed(1)}% of signups',
              color: theme.colorScheme.secondaryContainer,
            ),
            _KpiCard(
              label: 'Active subscribers',
              value: s.funnel.activeSubscribers.toString(),
              caption:
                  '${(s.funnel.subscriptionRate * 100).toStringAsFixed(1)}% of signups',
              color: theme.colorScheme.primaryContainer,
            ),
          ],
        ),
        const SizedBox(height: 32),

        // ----- Revenue chart ------------------------------------------
        _SectionHeader(
          title: 'Monthly revenue',
          subtitle: 'Course purchases + subscriptions, stacked.',
        ),
        const SizedBox(height: 12),
        _Card(child: RevenueLineChart(data: s.revenue)),
        const SizedBox(height: 32),

        // ----- Plan breakdown -----------------------------------------
        _SectionHeader(
          title: 'By subscription plan',
          subtitle:
              'Revenue per plan over the window (yearly is normalised to monthly).',
        ),
        const SizedBox(height: 12),
        _Card(child: PlanBreakdownChart(data: s.byPlan)),
        const SizedBox(height: 32),

        // ----- Top courses --------------------------------------------
        _SectionHeader(
          title: 'Top courses by revenue',
          subtitle: 'One-time purchases only. Tier prices are USD fallback.',
        ),
        const SizedBox(height: 12),
        _Card(
          child: _TopCoursesTable(
            data: s.byCourse,
            money: money,
          ),
        ),
        const SizedBox(height: 32),

        // ----- Funnel -------------------------------------------------
        _SectionHeader(
          title: 'Conversion funnel',
          subtitle: 'From signup to paying customer.',
        ),
        const SizedBox(height: 12),
        FunnelStrip(funnel: s.funnel),
        const SizedBox(height: 32),

        // ----- Cohorts ------------------------------------------------
        _SectionHeader(
          title: 'Cohort retention',
          subtitle:
              'Each row = users who signed up that month. Each cell = % of that cohort who had any paid activity by month N.',
        ),
        const SizedBox(height: 12),
        _Card(child: CohortHeatmap(matrix: s.cohorts)),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    this.inverted = false,
  });
  final String label;
  final String value;
  final String caption;
  final Color color;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onColor = inverted
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: onColor.withValues(alpha: 0.85),
                )),
            const SizedBox(height: 12),
            Text(value,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: onColor,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 4),
            Text(caption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onColor.withValues(alpha: 0.75),
                )),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 2),
        Text(subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // No explicit width — the parent Column uses
    // `crossAxisAlignment: stretch` so we always receive a tight
    // bounded width from the layout pipeline. Setting
    // `width: double.infinity` here would propagate infinity during
    // intrinsic-width measurement passes (which fl_chart's
    // AspectRatio sometimes triggers via hover hit tests) and throw
    // "BoxConstraints forces an infinite width".
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: child,
    );
  }
}

class _TopCoursesTable extends StatelessWidget {
  const _TopCoursesTable({required this.data, required this.money});
  final List<CourseRevenue> data;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text('No course purchases in this window.',
            style: theme.textTheme.bodyMedium),
      );
    }
    return Column(
      children: [
        for (final row in data) ...[
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  row.title.isEmpty ? row.courseId : row.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Expanded(
                child: Text(
                  '${row.purchaseCount}',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  money.format(row.revenueUsd),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
        ],
      ],
    );
  }
}
