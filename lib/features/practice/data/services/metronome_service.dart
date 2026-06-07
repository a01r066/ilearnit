import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../domain/entities/time_signature.dart';

/// Wraps the click-playback engine — owns the two preloaded
/// [AudioPlayer]s (accent + regular) and the periodic timer that
/// schedules ticks.
///
/// `just_audio` adds 30-80 ms of latency on Android vs. a native
/// SoundPool implementation, but it's already in our stack and is
/// adequate for v1. If users complain about timing drift, swap the
/// audio engine for `soundpool` without changing this class's API.
class MetronomeService {
  MetronomeService();

  final _accent = AudioPlayer();
  final _regular = AudioPlayer();

  bool _initialized = false;
  Timer? _ticker;
  int _beatIndex = 0;

  /// One-time asset preload. Idempotent — calling twice is safe.
  Future<void> init() async {
    if (_initialized) return;
    // setAsset returns the duration; we ignore it because both samples
    // are short enough that we can fire-and-forget.
    await Future.wait([
      _accent.setAsset(PracticeConstants.accentClickAsset),
      _regular.setAsset(PracticeConstants.regularClickAsset),
    ]);
    _initialized = true;
  }

  /// Begin (or restart) the metronome at [bpm] under [signature]. Safe
  /// to call while already running — we just reset the schedule.
  void start({
    required int bpm,
    required TimeSignature signature,
  }) {
    stop();
    _beatIndex = 0;
    final interval = Duration(
      microseconds: (60 * 1000 * 1000 / bpm).round(),
    );
    // Play the first beat immediately so the user doesn't wait a full
    // interval to hear feedback after pressing Start.
    _playClick(0, signature);
    _beatIndex = 1;
    _ticker = Timer.periodic(interval, (_) {
      _playClick(_beatIndex, signature);
      _beatIndex = (_beatIndex + 1) % signature.beatsPerMeasure;
    });
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  bool get isRunning => _ticker != null;

  void _playClick(int beat, TimeSignature signature) {
    final player = beat == 0 ? _accent : _regular;
    // seek(0) so the next .play() restarts the sample cleanly; without
    // it the second click in a row gets dropped on Android.
    player
      ..seek(Duration.zero)
      ..play();
  }

  Future<void> dispose() async {
    stop();
    await _accent.dispose();
    await _regular.dispose();
  }
}
