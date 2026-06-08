import 'package:flutter/foundation.dart';

import '../../data/analytics_snapshot.dart';

/// The dashboard's time window. Used for both the chart and cohort
/// computation.
enum AnalyticsRange {
  last90Days,
  last6Months,
  last12Months,
  ytd;

  /// Render label — translated against an [AppLocalizations]-style
  /// lookup in the UI layer (we keep enum free of i18n dep).
  String get labelKey => switch (this) {
        AnalyticsRange.last90Days => 'analyticsRange90d',
        AnalyticsRange.last6Months => 'analyticsRange6m',
        AnalyticsRange.last12Months => 'analyticsRange12m',
        AnalyticsRange.ytd => 'analyticsRangeYtd',
      };

  /// Resolve to a concrete `[start, end]` pair relative to `now`. End
  /// is always "right now" — the chart's last bucket is the current
  /// (partial) month.
  ({DateTime start, DateTime end}) resolve(DateTime now) {
    switch (this) {
      case AnalyticsRange.last90Days:
        return (start: now.subtract(const Duration(days: 90)), end: now);
      case AnalyticsRange.last6Months:
        return (
          start: DateTime(now.year, now.month - 5, 1),
          end: now,
        );
      case AnalyticsRange.last12Months:
        return (
          start: DateTime(now.year, now.month - 11, 1),
          end: now,
        );
      case AnalyticsRange.ytd:
        return (start: DateTime(now.year, 1, 1), end: now);
    }
  }
}

/// State for the dashboard.
///
/// We hand-roll instead of freezed because the only mutable field is
/// the range; the snapshot itself sits inside an `AsyncValue` exposed
/// by a separate provider.
@immutable
class AnalyticsState {
  const AnalyticsState({
    this.range = AnalyticsRange.last12Months,
  });

  final AnalyticsRange range;

  AnalyticsState copyWith({AnalyticsRange? range}) =>
      AnalyticsState(range: range ?? this.range);

  // ignore: hash_and_equals — we want identity comparison on the enum.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalyticsState && other.range == range);

  @override
  int get hashCode => range.hashCode;

  /// Convenience — the (start, end) pair for the current selection.
  ({DateTime start, DateTime end}) get window =>
      range.resolve(DateTime.now());
}

/// Just an alias to make provider signatures readable.
typedef AnalyticsResult = AnalyticsSnapshot;
