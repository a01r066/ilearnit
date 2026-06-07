/// Common time signatures supported by the metronome.
///
/// `beatsPerMeasure` is what we actually use — the denominator is
/// preserved for display only (the click rate is BPM, independent of the
/// notation).
enum TimeSignature {
  twoFour(2, 4, '2/4'),
  threeFour(3, 4, '3/4'),
  fourFour(4, 4, '4/4'),
  fiveFour(5, 4, '5/4'),
  sixEight(6, 8, '6/8'),
  sevenEight(7, 8, '7/8');

  const TimeSignature(this.beatsPerMeasure, this.denominator, this.label);

  final int beatsPerMeasure;
  final int denominator;
  final String label;

  static TimeSignature fromLabel(String label) =>
      TimeSignature.values.firstWhere(
        (t) => t.label == label,
        orElse: () => TimeSignature.fourFour,
      );
}

/// Project-wide tempo and audio-asset constants.
class PracticeConstants {
  const PracticeConstants._();

  /// Lower BPM bound for the slider — slow ballad tempo.
  static const int minBpm = 40;

  /// Upper BPM bound — past which the timer overhead dominates click
  /// audio latency on most devices.
  static const int maxBpm = 240;

  /// Sensible starting BPM. Matches the default on most hardware metros.
  static const int defaultBpm = 90;

  /// The two click samples used by the metronome. Drop short mono WAVs
  /// (≤300 ms each) into the repo and register the directory in
  /// `pubspec.yaml`'s `flutter.assets`. See `docs/practice_tools.md`
  /// §3 for the recommended sample format.
  static const String accentClickAsset = 'assets/audio/click_high.wav';
  static const String regularClickAsset = 'assets/audio/click_low.wav';

  /// Tap-tempo window — only the last N taps are used to compute the
  /// median interval. Five matches what most hardware metros do.
  static const int tapTempoWindow = 5;

  /// If two consecutive taps are this far apart, we treat them as the
  /// start of a fresh measurement rather than a continuation.
  static const Duration tapTempoMaxInterval = Duration(seconds: 3);
}
