# Practice Tools (Metronome + Tuner)

Implements **P2-6** from `docs/go_live_roadmap.md` — a daily-use feature
that gets students opening the app even when they aren't watching a
lecture. Reached from `Profile → Practice tools`.

---

## 1. Why "in Profile" instead of a 6th bottom nav

The shell already has five tabs (Home, Courses, Instructors, Songbooks,
Profile). A 6th would crowd the nav and squeeze the visible labels on
narrow screens. Practice tools are an accessory utility, not a daily
landing surface — Profile entry preserves the option to promote it
later if usage data warrants.

---

## 2. Architecture

```
PracticePage (DefaultTabController, 2 tabs)
├── MetronomeView
│     ▲
│     └─ metronomeNotifierProvider ── MetronomeNotifier
│                                       │
│                                       └─ MetronomeService
│                                            ├─ just_audio AudioPlayer (accent)
│                                            ├─ just_audio AudioPlayer (regular)
│                                            └─ Timer.periodic (BPM-derived)
│
└── TunerView
      ▲
      └─ tunerNotifierProvider ── TunerNotifier
                                    │
                                    └─ tunerEngineProvider ── TunerEngine
                                         (default StubTunerEngine)
                                         (override to a real mic engine
                                          at app boot — see §4)
                                    │
                                    └─ PitchMath.fromHz(...) → PitchReading
```

The metronome and tuner share nothing except a tab controller — they
can be lifted into separate pages if a v2 design wants them on
different screens.

---

## 3. Metronome engine notes

- **Click samples.** Two short WAVs at
  `assets/audio/click_high.wav` (accent) and `click_low.wav` (regular).
  See `assets/audio/README.md` for the recommended format and where to
  source them.
- **Latency.** `just_audio` adds 30-80 ms on Android compared to a
  native SoundPool implementation. Acceptable for v1; if users
  complain about timing drift, swap `MetronomeService` to use
  `soundpool` without changing its public API.
- **Tap tempo.** Median of the last 5 inter-tap intervals (cleared if
  the user pauses for >3 s). Robust against the first slightly-off
  tap.
- **Tempo change while running.** `setBpm` / `setSignature` restart
  the timer so the new tempo / accent pattern takes effect
  immediately.
- **Visual heartbeat.** The big circle pulses in time with the BPM
  even when audio is muted, so the user has a fallback visual cue.

---

## 4. Tuner engine — pluggable mic capture

The pitch math is pure Dart and ships ready (`PitchMath.fromHz`). The
mic capture side is **not** included because:

1. Native config (Info.plist + AndroidManifest entries) is best done
   by the host app, not shipped as a hard dependency.
2. Multiple mic-capture packages exist
   (`flutter_audio_capture`, `mic_stream`, `record`); we don't want
   to pin a choice in a shared feature.

The default `StubTunerEngine` emits `PitchReading.none` so the UI
compiles and renders an empty state. Wire up the real engine at app
boot by overriding `tunerEngineProvider`.

### Recommended real implementation

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_audio_capture: ^1.1.11
  pitch_detector_dart: ^0.0.4
```

Then in `lib/main_dev.dart` / `lib/main_prod.dart`, before the
`runApp(ProviderScope(child: …))`, swap in a real engine:

```dart
class FlutterAudioCaptureTunerEngine implements TunerEngine {
  final _capture = FlutterAudioCapture();
  final _detector = PitchDetector(audioSampleRate: 44100, bufferSize: 2048);
  final _controller = StreamController<PitchReading>.broadcast();

  @override
  Stream<PitchReading> get pitchStream => _controller.stream;

  @override
  Future<void> start() async {
    await _capture.start(
      _onFrame,
      _onError,
      sampleRate: 44100,
      bufferSize: 2048,
    );
  }

  void _onFrame(dynamic frame) async {
    final samples = (frame as List).cast<double>();
    final result = await _detector.getPitchFromFloatBuffer(samples);
    if (result.pitched) {
      _controller.add(
        PitchMath.fromHz(result.pitch, confidence: result.probability),
      );
    } else {
      _controller.add(PitchReading.none);
    }
  }

  void _onError(Object e) {/* log */}

  @override
  Future<void> stop() => _capture.stop();

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}

// In bootstrap.dart:
ProviderScope(
  overrides: [
    tunerEngineProvider.overrideWith((ref) {
      final engine = FlutterAudioCaptureTunerEngine();
      ref.onDispose(engine.dispose);
      return engine;
    }),
  ],
  child: App(),
)
```

### Native permission boilerplate

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>The tuner uses your microphone to detect the pitch of the note you play.</string>
```

**Android** — `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

The actual runtime permission prompt is fired by the mic-capture
package when `start()` runs. If the user denies, `TunerEngine.start`
should throw — `TunerNotifier.start` catches it and flips
`state.permissionDenied = true`, which surfaces a "Re-enable in
Settings" banner on the tuner UI.

---

## 5. Files added

| Path | Role |
|---|---|
| `lib/features/practice/domain/entities/time_signature.dart` | TimeSignature enum (2/4..7/8) + PracticeConstants (BPM bounds, asset paths, tap-tempo window) |
| `lib/features/practice/data/services/metronome_service.dart` | just_audio + Timer.periodic engine |
| `lib/features/practice/data/services/pitch_math.dart` | Hz → note name + cents (pure Dart) |
| `lib/features/practice/data/services/tuner_engine.dart` | `TunerEngine` interface + `StubTunerEngine` default |
| `lib/features/practice/presentation/providers/metronome_state.dart` | Hand-rolled state |
| `lib/features/practice/presentation/providers/metronome_notifier.dart` | StateNotifier + tap-tempo logic |
| `lib/features/practice/presentation/providers/tuner_state.dart` | Hand-rolled state |
| `lib/features/practice/presentation/providers/tuner_notifier.dart` | StateNotifier wrapping the engine stream |
| `lib/features/practice/presentation/providers/practice_providers.dart` | Riverpod wiring |
| `lib/features/practice/presentation/widgets/metronome_view.dart` | BPM controls + signature picker + tap-tempo + visual heartbeat |
| `lib/features/practice/presentation/widgets/tuner_view.dart` | Note label + cents readout + custom-painted gauge needle |
| `lib/features/practice/presentation/pages/practice_page.dart` | Tab shell |
| `assets/audio/README.md` | What WAVs the engine expects + recommended format |
| `docs/practice_tools.md` | This file |

## 6. Files changed

- `lib/core/routing/route_names.dart` + `app_router.dart` — new
  `/profile/practice` route nested under the profile branch.
- `lib/features/profile/presentation/pages/profile_page.dart` — new
  "Practice tools" tile under Subscription.
- `pubspec.yaml` — registered `assets/audio/` under
  `flutter.assets`.
- `lib/l10n/app_en.arb`, `app_vi.arb` + generated `app_localizations*.dart`
  — 18 new keys.

## 7. Testing checklist

| Scenario | Expected |
|---|---|
| Open Profile → Practice tools | PracticePage opens on the Metronome tab |
| Drag BPM slider | Number readout updates live; heartbeat speeds up |
| Tap +/- buttons | BPM increments by 1, clamped at 40 / 240 |
| Tap "Tap here in rhythm" 4 times at ~120 BPM | BPM jumps to ~120 |
| Pause between taps (>3 s) | Tap buffer resets; next two taps start a fresh measurement |
| Tap Start with no WAV samples shipped | Heartbeat pulses, no audio (no crash) |
| Tap Start with samples in place | Hear accent + regular clicks at the chosen BPM |
| Swipe to Tuner with StubTunerEngine | "Play a note to begin." rendered; gauge static |
| Wire real engine + grant mic perm | Note + cents update live; gauge needle swings |
| Deny mic perm | "Re-enable in Settings" banner shown |
| Swipe back to Metronome | Tuner stops listening; metronome state preserved |
| Background the app | Audio + capture pause; resume restores state |

## 8. Future work

- **Subdivision picker.** Eighth / sixteenth subdivisions inside each
  beat (the audio engine already supports per-tick variants — just add
  a `subdivision` field on `MetronomeState`).
- **Tempo presets.** Larghetto / Adagio / Allegro etc. as quick chips
  above the slider.
- **Tuner instrument presets.** Standard guitar / bass / violin
  tunings — highlight the target note when it's the closest match.
- **Strobe tuner mode.** Visual representation that's better than a
  needle for ±2¢ precision.
- **Practice streak tracking.** Log "user played the metronome for
  N minutes today" to `users/{uid}/practiceStreak/{date}` and surface
  the streak count on the Home tab.
- **Native SoundPool engine.** Drop-in replacement for the
  `MetronomeService` if timing drift becomes a v2 issue.
