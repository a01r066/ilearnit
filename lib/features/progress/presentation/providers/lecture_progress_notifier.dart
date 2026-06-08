import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../data/datasources/lecture_progress_datasource.dart';
import 'lecture_progress_state.dart';

/// Coordinates writing one lecture's progress to Firestore.
///
/// Throttling policy (matches `docs/go_live_roadmap.md` P0-8):
///   • Player ticks call [onTick] every wall-clock second.
///   • A Firestore write happens at most every 10 s **or** immediately
///     when the lecture transitions to completed.
///   • [flush] is invoked on pause and from `dispose` so the very last
///     position isn't lost.
///
/// Completion threshold: 95 % of `durationSec` watched. We use 95 % rather
/// than 100 % because most players never reach the exact end (encoder
/// padding, network buffer cut-off).
class LectureProgressNotifier extends StateNotifier<LectureProgressState> {
  LectureProgressNotifier({
    required LectureProgressDataSource datasource,
    required String userId,
    required String courseId,
    required String lectureId,
    required this.metaProvider,
    this.onLectureCompleted,
    Duration throttle = const Duration(seconds: 10),
  })  : _datasource = datasource,
        _userId = userId,
        _courseId = courseId,
        _lectureId = lectureId,
        _throttle = throttle,
        super(const LectureProgressState());

  final LectureProgressDataSource _datasource;
  final String _userId;
  final String _courseId;
  final String _lectureId;
  final Duration _throttle;

  /// Fired once per notifier when the lecture transitions to completed.
  /// Drives the in-app rating prompt's "completed lecture count" gate
  /// (P1-12) plus any other "natural moment" hooks added later.
  final void Function()? onLectureCompleted;

  /// Pulled lazily on every flush so notifiers don't have to be torn down
  /// when the underlying course doc (title / cover) is edited by an admin.
  final CourseMetaSnapshot Function() metaProvider;

  bool _disposed = false;
  Timer? _pendingFlush;

  /// Called by the player on every position tick.
  ///
  /// We always update the in-memory state so the UI can show smooth
  /// progress without waiting for the throttled Firestore write.
  void onTick({required int positionSec, required int durationSec}) {
    if (_disposed) return;

    final completedNow = durationSec > 0 &&
        positionSec >= (durationSec * 0.95).floor();
    final justCompleted = !state.completed && completedNow;

    state = state.copyWith(
      positionSec: positionSec,
      durationSec: durationSec,
      completed: completedNow,
    );

    if (justCompleted) {
      // Completion is a milestone — push it immediately so the rollup
      // increments the completedCount even if the user closes the page
      // within the next throttle window.
      unawaited(_flushImmediate());
      // Fire the "natural moment" hook (in-app rating, future
      // certificate generation, etc.). Guarded against synchronous
      // throws so a misbehaving listener can't poison the player.
      try {
        onLectureCompleted?.call();
      } catch (_) {}
      return;
    }

    final now = DateTime.now();
    final last = state.lastFlushedAt;
    final dueByElapsed =
        last == null || now.difference(last) >= _throttle;
    if (dueByElapsed && _pendingFlush == null) {
      // Schedule one write per throttle window; later ticks within the
      // window are coalesced.
      _pendingFlush = Timer(_throttle, () {
        _pendingFlush = null;
        unawaited(_flushImmediate());
      });
      // First tick of the window also flushes so the user sees an early
      // checkpoint instead of waiting 10 s for any persistence at all.
      if (last == null) {
        unawaited(_flushImmediate());
      }
    }
  }

  /// Called from the player on pause + on widget dispose. Forces a write
  /// regardless of throttle so the very latest position is captured.
  Future<void> flush() => _flushImmediate();

  Future<void> _flushImmediate() async {
    if (_disposed) return;
    if (state.durationSec <= 0 && state.positionSec <= 0) return;
    state = state.copyWith(isFlushing: true);
    try {
      await _datasource.upsertLectureProgress(
        userId: _userId,
        courseId: _courseId,
        lectureId: _lectureId,
        positionSec: state.positionSec,
        durationSec: state.durationSec,
        completed: state.completed,
        meta: metaProvider(),
      );
      state = state.copyWith(
        isFlushing: false,
        lastFlushedAt: DateTime.now(),
      );
    } catch (_) {
      // Swallow — progress is best-effort. The next tick will retry.
      state = state.copyWith(isFlushing: false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _pendingFlush?.cancel();
    // Fire-and-forget; the dataSource call survives because Firestore
    // SDK queues writes against the wider app lifecycle, not the
    // notifier's.
    unawaited(_flushImmediate());
    super.dispose();
  }
}
