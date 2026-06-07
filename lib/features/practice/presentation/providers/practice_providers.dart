import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/services/metronome_service.dart';
import '../../data/services/tuner_engine.dart';
import 'metronome_notifier.dart';
import 'metronome_state.dart';
import 'tuner_notifier.dart';
import 'tuner_state.dart';

// ---------- Metronome -----------------------------------------------------

final metronomeServiceProvider = Provider<MetronomeService>(
  (ref) {
    final service = MetronomeService();
    ref.onDispose(service.dispose);
    return service;
  },
);

/// Long-lived so the metronome keeps ticking when the user swipes
/// between the Metronome and Tuner tabs.
final metronomeNotifierProvider =
    StateNotifierProvider<MetronomeNotifier, MetronomeState>(
  (ref) => MetronomeNotifier(ref.watch(metronomeServiceProvider)),
);

// ---------- Tuner ---------------------------------------------------------

/// Override this provider at app boot to swap in a real mic-backed
/// engine (see `docs/practice_tools.md` §4). The default
/// [StubTunerEngine] is enough for the UI to compile and render its
/// empty state.
final tunerEngineProvider = Provider<TunerEngine>(
  (ref) {
    final engine = StubTunerEngine();
    ref.onDispose(engine.dispose);
    return engine;
  },
);

final tunerNotifierProvider =
    StateNotifierProvider<TunerNotifier, TunerState>(
  (ref) => TunerNotifier(ref.watch(tunerEngineProvider)),
);
