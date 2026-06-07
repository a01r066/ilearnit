import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../data/services/pitch_math.dart';
import '../../data/services/tuner_engine.dart';
import 'tuner_state.dart';

/// Bridges the [TunerEngine] stream to a [TunerState] the UI binds to.
class TunerNotifier extends StateNotifier<TunerState> {
  TunerNotifier(this._engine) : super(const TunerState());

  final TunerEngine _engine;
  StreamSubscription<PitchReading>? _sub;

  Future<void> start() async {
    if (state.isListening) return;
    try {
      await _engine.start();
      _sub = _engine.pitchStream.listen(_onReading);
      state = state.copyWith(isListening: true, permissionDenied: false);
    } catch (_) {
      // Most likely the user denied mic permission. The concrete engine
      // exposes the error type; we treat any startup failure as a
      // permission denial for the UI's purposes.
      state = state.copyWith(permissionDenied: true);
    }
  }

  Future<void> stop() async {
    if (!state.isListening) return;
    await _sub?.cancel();
    _sub = null;
    await _engine.stop();
    state = state.copyWith(
      isListening: false,
      reading: PitchReading.none,
    );
  }

  void _onReading(PitchReading next) {
    state = state.copyWith(reading: next);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _engine.dispose();
    super.dispose();
  }
}
