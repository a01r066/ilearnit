import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/revenue_point.dart';

/// Horizontal bar comparing the two subscription plans by revenue in
/// the selected window. Small surface — we render an inline legend
/// rather than a separate ChartLegend widget.
class PlanBreakdownChart extends StatelessWidget {
  const PlanBreakdownChart({super.key, required this.data});
  final List<PlanRevenue> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text('No subscriptions in this window',
              style: theme.textTheme.bodyMedium),
        ),
      );
    }
    final maxRev = data
        .map((p) => p.revenueUsd)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final yMax = (maxRev == 0 ? 100 : maxRev * 1.15).ceilToDouble();

    return AspectRatio(
      aspectRatio: 16 / 6,
      child: BarChart(
        BarChartData(
          maxY: yMax,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yMax / 4,
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '\$${value.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _planLabel(data[i].planId),
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].revenueUsd,
                    color: _planColor(theme, data[i].planId),
                    width: 32,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _planLabel(String id) => switch (id) {
        'monthly' => 'Monthly',
        'yearly' => 'Yearly',
        _ => id,
      };

  Color _planColor(ThemeData theme, String id) => switch (id) {
        'monthly' => theme.colorScheme.tertiary,
        'yearly' => theme.colorScheme.primary,
        _ => theme.colorScheme.secondary,
      };
}
