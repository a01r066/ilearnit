# Practice audio assets

The metronome (`lib/features/practice/data/services/metronome_service.dart`)
expects two short WAV samples in this directory:

| File | Used as | Notes |
|---|---|---|
| `click_high.wav` | Accent click (downbeat — beat 1) | ≤200 ms, ~1500 Hz tone or stick-on-rim |
| `click_low.wav`  | Regular click (other beats)       | ≤200 ms, ~800 Hz tone or wood block    |

## Recommended format

- 44.1 kHz, 16-bit PCM, mono
- ≤300 ms total length (longer than that and consecutive ticks overlap
  at fast tempos)
- −6 dBFS peak (we don't compensate for loud samples)

## Where to get them

- Freesound.org — CC0 metronome samples are plentiful (search
  "metronome tick wav").
- Logic / Ableton ship metronome samples in their stock packs.
- Or generate them with Audacity → Generate → Tone (sine 1500 Hz / 800 Hz,
  ~80 ms with a 20 ms decay envelope).

## What happens if these files are missing

`MetronomeService.init()` will throw on `setAsset`, which the UI
swallows silently. The metronome will appear to run (the visual
heartbeat animation will pulse) but won't produce audio. Drop the WAVs
in and run `flutter clean && flutter pub get` to re-register the
assets bundle.
