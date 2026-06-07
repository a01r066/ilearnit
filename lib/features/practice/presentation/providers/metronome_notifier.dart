import 'package:flutter_riverpod/legacy.dart';

import '../../data/services/metronome_service.dart';
import '../../domain/entities/time_signature.dart';
import 'metronome_state.dart';

/// Bridges the [MetronomeService] (audio + timer) to the Riverpod UI
/// layer. Owns the in-memory tap-tempo ring buffer too — that data is
/// transient and doesn't belong in [MetronomeState].
class MetronomeNotifier extends StateNotifier<MetronomeState> {
  MetronomeNotifier(this._service) : super(const MetronomeState()) {
    _service.init();
  }

  final MetronomeService _service;
  final List<DateTime> _taps = <DateTime>[];

  void start() {
    _service.start(bpm: state.bpm, signature: state.signature);
    state = state.copyWith(isRunning: true);
  }

  void stop() {
    _service.stop();
    state = state.copyWith(isRunning: false);
  }

  void toggle() => state.isRunning ? stop() : start();

  /// Clamp + apply a new BPM. Restarts the engine if it's currently
  /// running so the tempo change takes effect immediately.
  void setBpm(int next) {
    final clamped = next.clamp(
      PracticeConstants.minBpm,
      PracticeConstants.maxBpm,
    );
    state = state.copyWith(bpm: clamped);
    if (state.isRunning) start();
  }

  void setSignature(TimeSignature next) {
    state = state.copyWith(signature: next);
    if (state.isRunning) start();
  }

  /// Record a tap. Once we have ≥ 2 taps within
  /// [PracticeConstants.tapTempoMaxInterval] of each other we compute
  /// the median interval over the trailing window and apply it as BPM.
  void tap() {
    final now = DateTime.now();
    // Reset the buffer if the gap exceeds the window — a stale tap
    // shouldn't pull the median around.
    if (_taps.isNotEmpty &&
        now.difference(_taps.last) > PracticeConstants.tapTempoMaxInterval) {
      _taps.clear();
    }
    _taps.add(now);
    if (_taps.length > PracticeConstants.tapTempoWindow) {
      _taps.removeAt(0);
    }
    if (_taps.length < 2) return;

    // Median of intervals — robust against the first slightly-off tap.
    final intervals = <int>[];
    for (var i = 1; i < _taps.length; i++) {
      intervals.add(
        _taps[i].difference(_taps[i - 1]).inMilliseconds,
      );
    }
    intervals.sort();
    final medianMs = intervals[intervals.length ~/ 2];
    if (medianMs <= 0) return;
    final bpm = (60000 / medianMs).round();
    setBpm(bpm);
  }

  void resetTaps() => _taps.clear();

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
