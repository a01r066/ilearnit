import 'package:freezed_annotation/freezed_annotation.dart';

part 'revenue_point.freezed.dart';

/// One bucket of the revenue time series (one calendar month).
///
/// We split revenue into two streams so the dashboard can stack them
/// rather than show one opaque total:
///   • [purchasesUsd] — sum of one-time course purchases that happened
///     in this bucket.
///   • [subscriptionsUsd] — recognised subscription revenue in this
///     bucket (MRR × 1 month for actives, prorated for partials).
@freezed
abstract class RevenuePoint with _$RevenuePoint {
  const RevenuePoint._();

  const factory RevenuePoint({
    required DateTime month,
    @Default(0.0) double purchasesUsd,
    @Default(0.0) double subscriptionsUsd,
  }) = _RevenuePoint;

  double get totalUsd => purchasesUsd + subscriptionsUsd;
}

/// Aggregated revenue per subscription plan (monthly vs yearly) over
/// the selected window. Drives the "by plan" bar chart.
@freezed
abstract class PlanRevenue with _$PlanRevenue {
  const PlanRevenue._();

  const factory PlanRevenue({
    required String planId,
    @Default(0.0) double revenueUsd,
    @Default(0) int activeCount,
  }) = _PlanRevenue;
}

/// Aggregated revenue per course over the window.
@freezed
abstract class CourseRevenue with _$CourseRevenue {
  const CourseRevenue._();

  const factory CourseRevenue({
    required String courseId,
    @Default('') String title,
    @Default(0.0) double revenueUsd,
    @Default(0) int purchaseCount,
  }) = _CourseRevenue;
}
