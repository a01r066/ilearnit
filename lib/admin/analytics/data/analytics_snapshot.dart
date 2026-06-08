import '../domain/entities/cohort_matrix.dart';
import '../domain/entities/revenue_point.dart';

/// Single payload the dashboard renders against. Returned by
/// [AdminAnalyticsDataSource.loadAll] in one shot so the page only
/// shows one spinner, not five.
class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.revenue,
    required this.byPlan,
    required this.byCourse,
    required this.cohorts,
    required this.funnel,
    required this.mrrUsd,
    required this.totalRevenueUsd,
    required this.windowStart,
    required this.windowEnd,
  });

  /// Monthly revenue buckets across the window, ordered oldest →
  /// newest. Empty buckets are filled with zeros so the line chart
  /// doesn't have gaps.
  final List<RevenuePoint> revenue;

  final List<PlanRevenue> byPlan;
  final List<CourseRevenue> byCourse;

  final CohortMatrix cohorts;
  final FunnelCounts funnel;

  /// Snapshot KPIs — recomputed every load.
  final double mrrUsd;
  final double totalRevenueUsd;

  final DateTime windowStart;
  final DateTime windowEnd;

  factory AnalyticsSnapshot.empty({
    required DateTime windowStart,
    required DateTime windowEnd,
  }) =>
      AnalyticsSnapshot(
        revenue: const [],
        byPlan: const [],
        byCourse: const [],
        cohorts: const CohortMatrix(),
        funnel: const FunnelCounts(),
        mrrUsd: 0,
        totalRevenueUsd: 0,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
}
