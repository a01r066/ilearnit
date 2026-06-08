import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/revenue_point.dart';

/// Stacked area chart: course purchases + subscription revenue per
/// month. Used as the headline chart on the analytics page.
class RevenueLineChart extends StatelessWidget {
  const RevenueLineChart({super.key, required this.data});
  final List<RevenuePoint> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _empty(context);
    }
    final theme = Theme.of(context);
    final maxY = data
        .map((p) => p.totalUsd)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final yMax = (maxY == 0 ? 100 : maxY * 1.15).ceilToDouble();

    final purchaseSpots = <FlSpot>[];
    final totalSpots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      final p = data[i];
      purchaseSpots.add(FlSpot(i.toDouble(), p.purchasesUsd));
      totalSpots.add(FlSpot(i.toDouble(), p.totalUsd));
    }

    return AspectRatio(
      aspectRatio: 16 / 7,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: yMax,
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
                reservedSize: 56,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _money(value),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (data.length / 6).ceilToDouble().clamp(1, 12),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat.MMM().format(data[i].month),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Subscriptions = total minus purchases — visually it shows
            // as the band between the purchases line and the total
            // line.
            LineChartBarData(
              spots: totalSpots,
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            LineChartBarData(
              spots: purchaseSpots,
              isCurved: true,
              color: theme.colorScheme.tertiary,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color:
                    theme.colorScheme.tertiary.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );

  String _money(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }
}
