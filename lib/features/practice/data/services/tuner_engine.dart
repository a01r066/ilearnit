import 'dart:async';

import 'pitch_math.dart';

/// Streams pitch readings.
///
/// `pitch_detector_dart` only does the FFT — it needs raw PCM frames
/// from the mic. We don't bind to a specific mic-capture package here:
/// instead, [TunerEngine] is an interface and the real implementation
/// (using `flutter_audio_capture` + `pitch_detector_dart`) is wired up
/// by the host project once the native permission boilerplate is in.
///
/// The default [StubTunerEngine] emits `PitchReading.none` forever so
/// the UI compiles and renders an empty state in tests / dev builds.
/// See `docs/practice_tools.md` §4 for the recommended real
/// implementation.
abstract interface class TunerEngine {
  /// Single shared stream — subscribing twice gets the same broadcast.
  Stream<PitchReading> get pitchStream;

  /// Request mic permission + start the capture pipeline. Idempotent.
  Future<void> start();

  /// Stop the capture pipeline. Free to call repeatedly.
  Future<void> stop();

  Future<void> dispose();
}

/// Default no-op engine. Surfaces a quiet "needs setup" state.
///
/// To enable the real tuner, follow `docs/practice_tools.md` §4 and
/// override `tunerEngineProvider` with a `FlutterAudioCaptureTunerEngine`
/// (or your preferred mic package) at app boot.
class StubTunerEngine implements TunerEngine {
  final _controller = StreamController<PitchReading>.broadcast();

  @override
  Stream<PitchReading> get pitchStream => _controller.stream;

  @override
  Future<void> start() async {
    // Push a single "none" reading so a fresh subscriber sees something
    // — listening to a silent broadcast stream is otherwise indistinguishable
    // from being unsubscribed.
    _controller.add(PitchReading.none);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
