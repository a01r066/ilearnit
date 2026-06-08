# In-App Rating Prompt

Implements **P1-12** from `docs/go_live_roadmap.md`. Fires the OS-native
rating sheet (`SKStoreReviewController` on iOS, `ReviewManager` on
Android) at a well-timed moment — after the user has finished their
third lecture, never within the first week of install, never more than
once per 90 days.

The OS sheets enforce their own per-year caps too (Apple: 3
prompts/year; Google: rate-limited but undocumented). Our gating sits
on top of those.

---

## 1. Gating policy

```
shouldPrompt():
  if now - installedAt < 7 days             → false   (rule 1)
  if completedLectureCount < 3              → false   (rule 2)
  if lastRatingPromptAt
     && now - lastRatingPromptAt < 90 days  → false   (rule 3)
  if !InAppReview.isAvailable()             → false   (rule 4)
  → true
```

The thresholds live in `AppConstants` so an A/B test on the cooldown
is a one-line change. Default values:

- `ratingMinInstallAge`: 7 days
- `ratingMinCompletedLectures`: 3
- `ratingCooldown`: 90 days

---

## 2. Architecture

```
Lecture player tick (~1 Hz)
        ↓
LectureProgressNotifier.onTick(...)
        ↓ (95% watched edge)
[justCompleted == true]
        ↓
onLectureCompleted() callback (constructor-injected)
        ↓
AppRatingNotifier.recordCompletedLecture()
        ↓
prefs.incrementCompletedLectureCount()
        ↓
_maybePrompt():
   ├─ check gates
   ├─ stamp prefs.lastRatingPromptAt = now   ◄── BEFORE the plugin call
   ├─ InAppReview.requestReview()
   └─ AuthRepository.updateRatingPromptStamp(now)   ◄── best-effort
        ↓
users/{uid}.metadata.lastRatingPromptAt = <Timestamp>
```

### Why stamp prefs BEFORE the plugin call

A failed native call (plugin crash, OS denial, user cancellation)
should not free us to re-prompt on the very next tick. Stamping first
preserves the cooldown even if `requestReview()` throws.

### Why mirror to `users/{uid}.metadata.lastRatingPromptAt`

`PrefsService` lives in app sandboxed storage — wiped on uninstall.
If the user reinstalls and signs back in, we don't want to be the
overeager app that prompts them again the day they return. The
Firestore mirror lets a future enhancement (read the stamp on first
launch into prefs) restore the cooldown across reinstalls.

For v1 the read-back isn't wired — prefs is still authoritative on the
local device. Filed as future polish.

---

## 3. Files added

| Path | Role |
|---|---|
| `lib/features/app_rating/data/services/app_rating_service.dart` | Thin wrapper around `InAppReview` plugin |
| `lib/features/app_rating/presentation/providers/app_rating_notifier.dart` | Gating + plugin call + best-effort remote mirror |
| `lib/features/app_rating/presentation/providers/app_rating_providers.dart` | Riverpod wiring |
| `docs/app_rating_prompt.md` | This file |

## 4. Files changed

- `pubspec.yaml` — added `in_app_review: ^2.0.9`.
- `lib/core/constants/app_constants.dart` — three new SharedPreferences
  keys (`kInstalledAt`, `kCompletedLectureCount`,
  `kLastRatingPromptAt`) + three threshold constants.
- `lib/core/storage/prefs_service.dart` — getters/setters for the
  three new keys + `resetRatingPromptForQa` helper.
- `lib/bootstrap.dart` — `prefs.setInstalledAtIfMissing(DateTime.now())`
  on every launch (no-op after first call).
- `lib/features/auth/domain/repositories/auth_repository.dart` +
  `data/datasources/auth_remote_datasource.dart` +
  `data/repositories/auth_repository_impl.dart` — new
  `updateRatingPromptStamp(DateTime)` that writes to
  `users/{uid}.metadata.lastRatingPromptAt`.
- `lib/features/progress/presentation/providers/lecture_progress_notifier.dart`
  — added an optional `onLectureCompleted` callback that fires once
  on the completion edge.
- `lib/features/progress/presentation/providers/progress_providers.dart`
  — wires `AppRatingNotifier.recordCompletedLecture` into that callback.

## 5. Native config

`in_app_review` doesn't need extra plist or manifest entries —
SKStoreReviewController and ReviewManager are built into the SDKs.
But the plugin checks for Play Store availability on Android, which
requires Play Services. Already a requirement of every other Firebase
plugin in the stack.

To test the dialog **before publishing to the stores**, Google
provides the [Test Track method](https://developer.android.com/guide/playcore/in-app-review/test);
Apple's StoreKit sandbox shows the sheet under any TestFlight build.

## 6. Testing checklist

| Scenario | Expected |
|---|---|
| Fresh install, day 1, no lectures | No prompt |
| Day 8, 0 lectures | No prompt (rule 2) |
| Day 5, 5 lectures | No prompt (rule 1) |
| Day 8, finish lecture 3 | Native rating sheet appears once |
| Same day, finish lecture 4 | No prompt (cooldown) |
| Day 100, finish another lecture | Sheet appears again (cooldown expired) |
| Plugin returns `isAvailable: false` (web) | Silent no-op; no crash |
| Plugin throws | Local cooldown still set; we don't re-prompt next tick |
| Re-install + sign in | Local cooldown resets; can re-prompt after 7 days. Remote mirror exists for a future feature to restore it. |

## 7. QA reset

In debug builds, the prompt can be re-triggered without a clean
install. From a debug console or a temporary settings tile:

```dart
await ref.read(prefsProvider).resetRatingPromptForQa();
```

This wipes `installedAt`, `completedLectureCount`, and
`lastRatingPromptAt`. The next launch re-stamps `installedAt` to
`DateTime.now()` so you'll need to either wait 7 days, override the
threshold, or temporarily lower `AppConstants.ratingMinInstallAge`.

## 8. Future work

- **Read-back from `users/{uid}.metadata.lastRatingPromptAt` on first
  launch.** Restores the cooldown across reinstalls. One read on
  auth-state-resolved would do it.
- **More "natural moments."** Certificate completion, finishing a
  learning path, hitting a practice streak. Each call site is one
  `recordCompletedLecture`-equivalent.
- **A/B test the cooldown.** Lower `ratingCooldown` and measure rating
  volume vs. negative-review rate.
- **Self-throttle telemetry.** Once Firebase Analytics ships, log
  `rating_prompt_attempted` + `rating_prompt_gated` so we can see
  why a prompt didn't fire on real devices.
