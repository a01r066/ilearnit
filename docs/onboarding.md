# Onboarding Flow

Implements **P1-1** from `docs/go_live_roadmap.md` — a 3-screen first-run
flow that personalizes the catalogue and soft-asks for notification
permission before triggering the OS prompt.

---

## 1. User journey

Onboarding now runs **before** sign-in. A brand-new install sees the
picker steps without an auth prompt, then lands on a login page that
allows skipping into guest mode.

```
Launch app
   ↓
Splash (auth resolving)
   ↓
Router redirect:
   !prefs.onboardingDone → /onboarding   (regardless of auth state)
   ↓
[Step 1]  Instrument picker (guitar / piano / violin)
   ↓ Continue (disabled until selection)
[Step 2]  Skill level (beginner / intermediate / advanced)
   ↓ Continue (disabled until selection)
[Step 3]  Notifications soft-ask — explains value + 3 benefits
   ↓ "Enable notifications"
[OS permission prompt]
   ↓ "Done"
finish():
   • If signed in (re-onboarding case):
       PUT users/{uid}.primaryInstrument + skillLevel
   • If guest (common case):
       prefs.pendingPrimaryInstrument = instrument.id
       prefs.pendingSkillLevel = level.id
   • prefs.onboardingDone = true
   ↓
go(/login)                              ← was /home in the old flow
   ↓
LoginPage offers three actions:
   • Sign in / Sign up   → after auth: /home + bootstrap syncs
                            pending* prefs into users/{uid} + clears them.
   • Continue as guest   → /home with guest browse rules active.
   ↓
/home
```

`Skip` at any onboarding step flips the prefs flag without writing
anything — same end state, just empty picker values.

---

## 2. Architecture

```
OnboardingPage  (PageView shell, header dots, footer CTA)
   ├─ InstrumentStep   (writes state.instrument)
   ├─ LevelStep        (writes state.level)
   └─ NotificationsStep
            │
            ▼  via footer CTA
OnboardingNotifier
   ├─ selectInstrument / selectLevel
   ├─ next() / back()
   ├─ requestNotifications() → FcmService.requestPermission()
   └─ finish({skip}) → AuthRepository.updateProfile + PrefsService.setOnboardingDone
```

The page is purely a view of `state.step` — the PageView never receives
swipes (`NeverScrollableScrollPhysics`). Step transitions come from the
notifier only.

---

## 3. Files added

| Path | Role |
|---|---|
| `lib/features/onboarding/presentation/pages/onboarding_page.dart` | PageView shell + dots + Skip/Continue/Done CTA |
| `lib/features/onboarding/presentation/widgets/instrument_step.dart` | Tap-list of `InstrumentCategory` |
| `lib/features/onboarding/presentation/widgets/level_step.dart` | Tap-list of `CourseLevel` with blurbs |
| `lib/features/onboarding/presentation/widgets/notifications_step.dart` | Soft-ask copy + 3 benefit rows |
| `lib/features/onboarding/presentation/providers/onboarding_state.dart` | Hand-rolled immutable state (no codegen) |
| `lib/features/onboarding/presentation/providers/onboarding_notifier.dart` | `StateNotifier` driving the flow |
| `lib/features/onboarding/presentation/providers/onboarding_providers.dart` | Riverpod wiring |
| `docs/onboarding.md` | This file |

## 4. Files changed

- `lib/features/auth/domain/entities/user_entity.dart` — added nullable
  `skillLevel`.
- `lib/features/auth/data/models/user_model.dart` — same field, mirrored
  on `toEntity()`.
- `lib/features/auth/domain/repositories/auth_repository.dart` — new
  `updateProfile({primaryInstrument, skillLevel, displayName})`.
- `lib/features/auth/data/datasources/auth_remote_datasource.dart` +
  `repositories/auth_repository_impl.dart` — `updateProfile`
  implementation (Firestore merge + mirror displayName to FirebaseAuth).
- `lib/core/notifications/data/fcm_service.dart` — exposed a public
  `requestPermission()` distinct from `init()`.
- `lib/core/routing/route_names.dart` + `app_router.dart` — new
  `/onboarding` route registered above the shell, redirect gates the
  shell behind `prefs.onboardingDone`.
- `lib/l10n/app_en.arb`, `app_vi.arb` + generated `app_localizations*.dart`
  — 24 new keys.

The existing `PrefsService.onboardingDone` getter + setter were already
in place; no storage changes were needed.

## 5. Why a "soft" notification ask?

Apple + Google both surface a one-shot OS prompt the first time
`FirebaseMessaging.requestPermission()` is called. Users who decline that
prompt rarely re-enable the permission from Settings — the cost of a
mis-timed ask is permanent.

We therefore:
1. **Explain the value first.** Three concrete benefits with icons.
2. **Trigger the OS prompt only on tap.** The state's
   `notificationsRequested` flag flips to `true` after the call resolves,
   regardless of allow / deny.
3. **Never block on decline.** The "Done" CTA is enabled either way.
4. **Reassure the decliner.** If they declined, the post-prompt copy
   tells them they can enable from Settings later. (We should add the
   toggle there per P1-4 in the roadmap.)

## 6. Skill level semantics

`CourseLevel` is reused — same enum that filters the Courses list — so
the writeback can be consumed by:
- The Home rail (filter `featuredCoursesProvider` by user level — future
  refinement).
- The Courses page default filter (read user.skillLevel on first build).
- Personalized recommendations / instructor matching (future Cloud
  Function trigger).

For v1 the field is written but not yet *read* anywhere — that's fine,
it's cheap and we want the data so we can ship the rail tuning without
another migration.

## 7. Testing checklist

| Scenario | Expected |
|---|---|
| Fresh install, complete sign-up | Redirected to `/onboarding` |
| Pick instrument → Continue | Page swipes to level step, dot 2 highlights |
| Pick level → Continue | Page swipes to notifications step |
| Tap Enable → grant on OS prompt | "Thanks — you're all set" appears, CTA → Done |
| Tap Enable → deny on OS prompt | "You can enable from Settings later" appears, CTA → Done |
| Tap Done | `users/{uid}.primaryInstrument` + `.skillLevel` written, routed to `/home` |
| Tap Skip on step 1 | Routed to `/home`, no profile writes, prefs flag set |
| Force-quit on step 2 | Onboarding re-shown on relaunch (prefs flag not yet set) |
| Restart after completion | Goes straight to `/home`, never sees onboarding again |
| Offline during finish() | `AuthRepository.updateProfile` returns `Failure.network`, snackbar shown, prefs flag NOT set so user can retry |

## 8. Out-of-scope / future

- A Settings → "Run onboarding again" entry that clears the prefs flag.
- Reading `users/{uid}.skillLevel` on the Home rail / Courses filter.
- Optional 4th step: theme picker (vibrant / professional / system).
- Web variant — the admin portal currently bypasses onboarding because
  it ships with its own routing entirely.
