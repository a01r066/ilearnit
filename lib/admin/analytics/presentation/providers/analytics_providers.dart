import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../data/admin_analytics_datasource.dart';
import '../../data/analytics_snapshot.dart';
import 'analytics_notifier.dart';
import 'analytics_state.dart';

final adminAnalyticsDataSourceProvider =
    Provider<AdminAnalyticsDataSource>((ref) {
  return AdminAnalyticsDataSource(firestore: ref.watch(firestoreProvider));
});

final analyticsNotifierProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(),
);

/// Fetches the snapshot keyed by the current window. Switching the
/// range invalidates the AsyncValue, triggering a fresh load — no
/// manual `ref.invalidate` needed.
final analyticsSnapshotProvider = FutureProvider<AnalyticsSnapshot>(
  (ref) async {
    final state = ref.watch(analyticsNotifierProvider);
    final window = state.window;
    final ds = ref.watch(adminAnalyticsDataSourceProvider);
    return ds.loadAll(
      windowStart: window.start,
      windowEnd: window.end,
    );
  },
);
