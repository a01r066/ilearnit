import 'package:flutter/foundation.dart';

import '../../domain/entities/time_signature.dart';

/// Drives the metronome UI. Hand-rolled (no freezed) so the file compiles
/// without a `build_runner` pass — the field set is small enough that
/// the codegen overhead isn't worth it.
@immutable
class MetronomeState {
  const MetronomeState({
    this.bpm = PracticeConstants.defaultBpm,
    this.signature = TimeSignature.fourFour,
    this.isRunning = false,
  });

  final int bpm;
  final TimeSignature signature;
  final bool isRunning;

  MetronomeState copyWith({
    int? bpm,
    TimeSignature? signature,
    bool? isRunning,
  }) =>
      MetronomeState(
        bpm: bpm ?? this.bpm,
        signature: signature ?? this.signature,
        isRunning: isRunning ?? this.isRunning,
      );
}
