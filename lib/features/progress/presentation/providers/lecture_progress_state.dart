import 'package:flutter/foundation.dart';

/// In-memory mirror of the most recent progress write for one lecture.
///
/// Hand-rolled (no freezed) so this state file compiles without a
/// `build_runner` pass — the only fields are scalars.
@immutable
class LectureProgressState {
  const LectureProgressState({
    this.positionSec = 0,
    this.durationSec = 0,
    this.completed = false,
    this.lastFlushedAt,
    this.isFlushing = false,
  });

  /// Last play-head value observed from the player.
  final int positionSec;

  /// Last duration observed from the player.
  final int durationSec;

  /// True once the user has watched ≥ 95 % of the lecture.
  final bool completed;

  /// Wall-clock time of the most recent successful Firestore write. The
  /// notifier uses this to throttle: writes happen at most every 10 s.
  final DateTime? lastFlushedAt;

  /// True while an upsert is in flight. Surfaced so a UI debug overlay
  /// (or tests) can observe pending state.
  final bool isFlushing;

  double get fraction {
    if (durationSec <= 0) return 0;
    final f = positionSec / durationSec;
    if (f.isNaN || f.isNegative) return 0;
    return f.clamp(0.0, 1.0);
  }

  LectureProgressState copyWith({
    int? positionSec,
    int? durationSec,
    bool? completed,
    Object? lastFlushedAt = _unset,
    bool? isFlushing,
  }) {
    return LectureProgressState(
      positionSec: positionSec ?? this.positionSec,
      durationSec: durationSec ?? this.durationSec,
      completed: completed ?? this.completed,
      lastFlushedAt: identical(lastFlushedAt, _unset)
          ? this.lastFlushedAt
          : lastFlushedAt as DateTime?,
      isFlushing: isFlushing ?? this.isFlushing,
    );
  }

  static const Object _unset = Object();
}
