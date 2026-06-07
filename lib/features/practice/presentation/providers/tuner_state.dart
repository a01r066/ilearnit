import 'package:flutter/foundation.dart';

import '../../data/services/pitch_math.dart';

/// Drives the tuner UI. Hand-rolled — small state, no codegen needed.
@immutable
class TunerState {
  const TunerState({
    this.isListening = false,
    this.reading = PitchReading.none,
    this.permissionDenied = false,
  });

  final bool isListening;
  final PitchReading reading;

  /// Set when the user dismissed the mic permission dialog. The UI
  /// surfaces a "Re-enable in Settings" CTA in this case.
  final bool permissionDenied;

  TunerState copyWith({
    bool? isListening,
    PitchReading? reading,
    bool? permissionDenied,
  }) =>
      TunerState(
        isListening: isListening ?? this.isListening,
        reading: reading ?? this.reading,
        permissionDenied: permissionDenied ?? this.permissionDenied,
      );
}
