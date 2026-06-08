import 'package:flutter_riverpod/legacy.dart';

import 'analytics_state.dart';

/// Holds the user's window selection. The actual data fetch lives on a
/// FutureProvider keyed off this notifier's state, so changing the
/// range automatically invalidates the cached snapshot.
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier() : super(const AnalyticsState());

  void setRange(AnalyticsRange range) {
    if (state.range == range) return;
    state = state.copyWith(range: range);
  }
}
