import 'package:firebase_performance/firebase_performance.dart';

/// Thin facade over [FirebasePerformance].
///
/// The two patterns we use:
///
///   1. **Code traces** for measuring durations of synthetic
///      operations (app warm start, feed load, payment flow).
///      ```dart
///      final trace = perf.start('app_start');
///      await ...;
///      await trace.stop();
///      ```
///
///   2. **HTTP metrics** are collected automatically by the SDK once
///      `httpMetricEnabled` is on — no app-side wiring needed for the
///      Dio interceptor or video player HTTP requests.
///
/// Performance collection respects the same user opt-out as
/// Crashlytics/Analytics. The SDK is a no-op in debug mode anyway.
class PerformanceService {
  PerformanceService(this._performance);

  final FirebasePerformance _performance;

  Future<void> setEnabled(bool enabled) async {
    await _performance.setPerformanceCollectionEnabled(enabled);
  }

  /// Convenience — `start()` returns a started trace so callers can
  /// `.stop()` it later without needing to call `.start()` themselves.
  Future<Trace> start(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    return trace;
  }

  /// Wrap an async body in a code trace. Returns whatever the body
  /// returns. The trace stops even if the body throws.
  Future<T> trace<T>(String name, Future<T> Function() body) async {
    final t = await start(name);
    try {
      return await body();
    } finally {
      await t.stop();
    }
  }

  /// Manual HTTP metric — needed when the auto-instrumented network
  /// libraries can't see your request (e.g. `flutter_video_player`
  /// loads on the platform side). Use sparingly.
  HttpMetric newHttpMetric(String url, HttpMethod method) =>
      _performance.newHttpMetric(url, method);
}
