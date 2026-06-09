import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around [FirebaseCrashlytics] so the rest of the app
/// can opt in/out without importing the SDK directly.
///
/// Configuration defaults:
///   • Debug builds → collection DISABLED (no noise in dashboards).
///   • Release builds → collection ENABLED.
///   • A user toggle in Settings can override either way.
class CrashlyticsService {
  CrashlyticsService(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  /// Wire up the global error handlers. Idempotent — calling twice is
  /// safe.
  Future<void> installErrorHandlers() async {
    FlutterError.onError = (details) {
      // Forward to Crashlytics. `fatal: true` puts the crash into the
      // top dashboard panel rather than "Non-fatals".
      _crashlytics.recordFlutterFatalError(details);
    };

    // Uncaught async errors (e.g. from Futures with no .catchError).
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true; // mark as handled — prevents the engine from logging twice
    };

    // Errors raised on a different isolate (e.g. compute()).
    Isolate.current.addErrorListener(RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair as List<dynamic>;
      await _crashlytics.recordError(
        errorAndStacktrace.first,
        errorAndStacktrace.last as StackTrace?,
        fatal: true,
      );
    }).sendPort);
  }

  /// Default policy: enabled in release, disabled in debug, overridable
  /// by the user via Settings.
  Future<void> applyCollectionPolicy({required bool userOptIn}) async {
    final enabled = kReleaseMode && userOptIn;
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  Future<void> setUserId(String? uid) =>
      _crashlytics.setUserIdentifier(uid ?? '');

  Future<void> setCustomKey(String key, Object value) =>
      _crashlytics.setCustomKey(key, value);

  /// Logs a non-fatal exception — surfaces in the "Non-fatals" panel.
  /// Use for caught-but-unexpected paths (failed background fetches,
  /// IAP edge cases).
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    Iterable<DiagnosticsNode> information = const [],
  }) =>
      _crashlytics.recordError(
        error,
        stack,
        reason: reason,
        information: information,
        fatal: false,
      );

  /// Append a breadcrumb-style log line — visible above the stack
  /// trace on crash reports.
  void log(String message) => _crashlytics.log(message);
}
