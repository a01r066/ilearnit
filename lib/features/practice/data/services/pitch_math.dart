import 'dart:math' as math;

/// One detected pitch reading.
///
/// `cents` is the deviation from the *nearest* note (range −50..50). The
/// gauge needle on the tuner UI binds directly to this value.
class PitchReading {
  const PitchReading({
    required this.frequencyHz,
    required this.noteName,
    required this.octave,
    required this.cents,
    required this.confidence,
  });

  /// Sentinel emitted when no pitch is detected (silence, percussion).
  static const PitchReading none = PitchReading(
    frequencyHz: 0,
    noteName: '',
    octave: 0,
    cents: 0,
    confidence: 0,
  );

  final double frequencyHz;
  final String noteName;
  final int octave;
  final double cents; // −50..50
  final double confidence; // 0..1

  bool get isSilent => frequencyHz <= 0;

  bool get isInTune => cents.abs() < 5;
  bool get isClose => cents.abs() < 15;
  bool get isFlat => cents < -5;
  bool get isSharp => cents > 5;

  /// "A4", "C♯3", etc.
  String get displayLabel => isSilent ? '—' : '$noteName$octave';
}

/// Pure-Dart pitch utilities. Takes a frequency in Hz and returns the
/// note + octave + cents off. Independent of the audio source so the
/// metronome side of this feature isn't dragged into testing.
class PitchMath {
  const PitchMath._();

  /// Equal-tempered note names. Sharps only — flats are equivalent and
  /// we'd be re-rendering the same gauge.
  static const _noteNames = <String>[
    'C', 'C♯', 'D', 'D♯', 'E', 'F',
    'F♯', 'G', 'G♯', 'A', 'A♯', 'B',
  ];

  /// MIDI 69 == A4 == 440 Hz. We use that as the reference.
  static const double _a4Hz = 440;
  static const int _midiA4 = 69;

  /// Convert a frequency to a [PitchReading].
  ///
  /// Returns [PitchReading.none] for non-positive frequencies. The
  /// `confidence` field is just passed through from the caller — the
  /// pitch detector knows its own certainty, this class doesn't.
  static PitchReading fromHz(double hz, {double confidence = 1}) {
    if (hz <= 0 || hz.isNaN || hz.isInfinite) return PitchReading.none;

    // MIDI note number, real-valued. 12 * log2(hz / 440) + 69.
    final midiReal = 12 * (math.log(hz / _a4Hz) / math.ln2) + _midiA4;
    final midiInt = midiReal.round();
    final cents = (midiReal - midiInt) * 100;

    // C0 = MIDI 12 → octave 0; we want C0 to render as "C0".
    final octave = (midiInt ~/ 12) - 1;
    final noteIndex = ((midiInt % 12) + 12) % 12;
    final name = _noteNames[noteIndex];

    return PitchReading(
      frequencyHz: hz,
      noteName: name,
      octave: octave,
      cents: cents,
      confidence: confidence,
    );
  }
}
