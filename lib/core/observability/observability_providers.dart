import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';
import 'crashlytics_service.dart';
import 'performance_service.dart';

/// SDK singletons exposed as providers so tests can substitute fakes.
final firebaseCrashlyticsProvider = Provider<FirebaseCrashlytics>(
  (_) => FirebaseCrashlytics.instance,
);

final firebasePerformanceProvider = Provider<FirebasePerformance>(
  (_) => FirebasePerformance.instance,
);

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>(
  (_) => FirebaseAnalytics.instance,
);

/// Application-facing facades.
final crashlyticsServiceProvider = Provider<CrashlyticsService>(
  (ref) => CrashlyticsService(ref.watch(firebaseCrashlyticsProvider)),
);

final performanceServiceProvider = Provider<PerformanceService>(
  (ref) => PerformanceService(ref.watch(firebasePerformanceProvider)),
);

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.watch(firebaseAnalyticsProvider)),
);

/// Lightweight observer for the GoRouter — emits `screen_view` events
/// on every navigation. Exposed as a provider so the router can read
/// the same instance the analytics service writes to.
final firebaseAnalyticsObserverProvider =
    Provider<FirebaseAnalyticsObserver>(
  (ref) => FirebaseAnalyticsObserver(
    analytics: ref.watch(firebaseAnalyticsProvider),
  ),
);
