# Observability: Crashlytics + Performance + Analytics

Three Firebase SDKs are wired together through a single observability
layer that:

- Captures crashes + non-fatal exceptions (Crashlytics)
- Records trace timings + automatic HTTP metrics (Performance)
- Logs user events + screen views (Analytics)
- Tags every signal with the current user id, role, skill level, and
  primary instrument
- Respects a single Settings toggle that pauses all three SDKs at
  once

The collection policy follows the platform conventions: **off in
debug builds, on in release builds**, overridable by the user
in `Settings → Privacy`.

## File map

```
lib/core/observability/
  analytics_events.dart            Event + parameter + user-property constants
  analytics_service.dart           Typed wrapper over FirebaseAnalytics
  crashlytics_service.dart         Wraps FirebaseCrashlytics + error handlers
  performance_service.dart         Wraps FirebasePerformance; trace() helper
  observability_providers.dart     Riverpod providers for SDKs + facades
  observability_bootstrap.dart     Auth → user-id link (provider)
```

Other touchpoints:

- `lib/bootstrap.dart` — installs error handlers, applies collection
  policy, logs `app_start`, activates the auth link.
- `lib/core/routing/app_router.dart` — attaches the
  `FirebaseAnalyticsObserver` to the GoRouter for automatic
  `screen_view` events.
- `lib/features/profile/presentation/pages/settings_page.dart` —
  exposes the master opt-out switch.
- `lib/core/storage/prefs_service.dart` —
  `observabilityOptOut` field (single boolean shared by all three).

## Native setup

### Android (debug + release)

The Crashlytics gradle plugin and the Google Services plugin are
already on the classpath if you previously wired FCM (P0-… era).
Confirm in `android/build.gradle.kts`:

```
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
    id("com.google.firebase.firebase-perf") version "1.4.2" apply false
}
```

…and in `android/app/build.gradle.kts`:

```
plugins {
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("com.google.firebase.firebase-perf")
}
```

No code changes needed beyond the Flutter side — the SDKs find the
`google-services.json` you already have.

### iOS

Crashlytics needs the dSYM upload script as a Run Phase in Xcode.
Open `ios/Runner.xcworkspace` → Runner target → Build Phases → +
`New Run Script Phase`:

```
"$PODS_ROOT/FirebaseCrashlytics/run"
```

Input Files (under "Input Files" of the same phase):

```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}
$(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)
```

When testing release builds on TestFlight, also upload dSYMs from
App Store Connect → TestFlight → Builds → dSYMs.

### Web

Crashlytics is mobile-only. Performance and Analytics work on web
without extra setup — the FirebaseOptions already include the web
config.

## Event taxonomy

Defined in `analytics_events.dart`. The strict naming convention
keeps the BigQuery export and Looker dashboards joinable across
funnels:

- snake_case, verb-noun order: `course_viewed`, `lecture_completed`
- prefix `app_` for app-level milestones (`app_start`,
  `app_rating_shown`)
- reserved Firebase names (`purchase`, `login`, `sign_up`,
  `screen_view`, `search`, `share`) are sent through typed helpers
  on `AnalyticsService` so Firebase auto-populates the matching
  dashboards.

### User properties

| Key | Source | Notes |
|---|---|---|
| `role` | `UserEntity.role.id` | student / instructor / admin |
| `skill_level` | onboarding output | beginner / intermediate / advanced |
| `primary_instrument` | onboarding output | guitar / piano / violin |
| `subscription_plan` | subscription notifier (write on plan change) | monthly / yearly / null |
| `onboarding_complete` | derived | true once skill_level is set |

## Custom code traces (Performance)

Use the `PerformanceService.trace()` helper instead of starting raw
traces — it auto-stops on throw and on return:

```dart
final perf = ref.read(performanceServiceProvider);
final lectures = await perf.trace('course_curriculum_load', () async {
  return curriculumDataSource.fetch(courseId);
});
```

Trace names should match the SLO you'd report against — keep them
stable.

## Error reporting patterns

**Fatal crashes** — automatic via `FlutterError.onError` +
`PlatformDispatcher.onError` + the isolate error listener.

**Non-fatal but logged** — for handled-but-unexpected paths, call:

```dart
ref.read(crashlyticsServiceProvider).recordError(
  err,
  stack,
  reason: 'IAP receipt verification failed',
);
```

**Breadcrumbs** — sprinkle `crashlytics.log('search:no_results')`
at decision points. They show above the stack on the next crash and
are free.

## Privacy + opt-out

`Settings → Privacy → Send anonymous usage data` flips
`prefs.observabilityOptOut`. The toggle:

1. Immediately disables all three SDKs (calls
   `setCrashlyticsCollectionEnabled(false)`,
   `setPerformanceCollectionEnabled(false)`,
   `setAnalyticsCollectionEnabled(false)`).
2. On next launch, `bootstrap.dart` reads the flag and applies the
   same policy before the first event can be fired.
3. The user toggling back ON re-enables everything immediately and
   on next launch.

Per Apple's tracking rules and the GDPR right to object, this is the
single switch we surface; engineers don't need to grant fine-grained
control to be compliant.

## Testing the wiring

Quick smoke test after pulling these changes:

1. `flutter pub get` to pull the three new SDKs.
2. `flutter run --release` (Crashlytics is no-op in debug).
3. Force a non-fatal:
   ```dart
   ref.read(crashlyticsServiceProvider).recordError(
     Exception('test non-fatal'), StackTrace.current,
     reason: 'observability smoke test',
   );
   ```
4. Within ~1 minute the event appears in the Firebase console under
   Crashlytics → Non-fatals.
5. Navigate two screens — confirm two `screen_view` events in
   Analytics → DebugView.
6. Sign in, sign out — confirm `userId` populates and clears in
   DebugView's left rail.
7. Open `Settings → Privacy`, toggle off, force another event —
   confirm DebugView stops receiving anything.

## When to add a new event

1. Add the event name + any new parameters to
   `analytics_events.dart`.
2. Add a typed helper method on `AnalyticsService`.
3. Call it from the relevant notifier / page.
4. Run the smoke test above and verify the event appears in
   DebugView with the expected parameters.
5. Add it to the BI funnel doc (if you have one) so the dashboard
   gets updated.

Avoid `analytics.logEvent('foo', ...)` from a feature file directly
— it bypasses the typed helper and the BI team won't see the new
event until they grep the codebase.
