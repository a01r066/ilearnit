---
name: flutter-riverpod-firebase-architecture
description: Project structure and coding conventions for a Flutter mobile app built on Riverpod 3, freezed, dartz Either, go_router and Firebase with dev/prod flavors (feature-first data/domain/presentation). Use this skill whenever you start a new Flutter + Firebase app, scaffold a feature, write a provider/notifier/repository, wire up bootstrap/main/flavors/Firebase init, set up go_router with guest mode, or debug Flutter layout errors such as "BoxConstraints forces an infinite width" — even if the user doesn't name Riverpod or this skill. Do NOT use for projects that already use Cubit/Bloc + GetIt; follow that project's own conventions instead.
---

# Flutter · Riverpod · Firebase architecture

A battle-tested layout for consumer Flutter apps with a Firebase backend.
It was extracted from a production marketplace app (courses, IAP,
subscriptions, offline media) and is deliberately boring: every feature
looks the same, so any file is easy to find and review.

Companion skills (use together when relevant):
`firebase-backend-security` (rules, Functions, signed media),
`flutter-iap-server-verification` (purchases),
`flutter-store-release-readiness` (store submission),
`flutter-l10n-a11y` (strings and accessibility).

## 1. Stack

| Concern | Package | Notes |
|---|---|---|
| State / DI | `flutter_riverpod` 3.x | `StateNotifierProvider` lives in `package:flutter_riverpod/legacy.dart` |
| Models | `freezed` + `json_serializable` | `build.yaml` sets `explicit_to_json: true` (nested models → Firestore) |
| Errors | `dartz` | `ResultFuture<T> = Future<Either<Failure, T>>` |
| Routing | `go_router` | `StatefulShellRoute.indexedStack` for tabs |
| Flavors | `flutter_flavorizr` | `dev` + `prod`, separate Firebase projects |
| Backend | Firebase (Auth, Firestore, Storage, Functions, Messaging, App Check, Remote Config, Crashlytics) | |

Check pub.dev for current major versions before pinning; APIs above were
current mid-2026.

## 2. Folder layout

```
lib/
  main.dart                 # sets F.appFlavor, calls bootstrap()
  flavors.dart              # Flavor enum + F accessor (flavorizr base + helpers)
  bootstrap.dart            # init order, ProviderContainer, runApp
  firebase_options_dev.dart / firebase_options_prod.dart   # flutterfire configure per project
  app/
    app.dart                # MaterialApp.router, theme, l10n, update gate
    session_cleanup.dart    # wipe per-user local state on sign-out
  core/                     # app-wide, feature-agnostic
    error/        failure.dart, exceptions.dart, failure_mapper.dart
    typedefs/     typedefs.dart
    routing/      app_router.dart, route_names.dart, shell_scaffold.dart
    session/      before_sign_out_hooks.dart
    storage/      prefs_service.dart, offline_storage.dart
    security/  update/  notifications/  observability/  theme/  widgets/
  shared/providers/         # firebaseAuthProvider, firestoreProvider, prefsProvider…
  l10n/                     # ARB files + l10n.dart (see flutter-l10n-a11y)
  features/<feature>/
    data/
      datasources/  <feature>_remote_datasource.dart   # Firestore / callables / HTTP
      models/       <thing>_model.dart                 # freezed + fromJson/toJson + toEntity()
      repositories/ <feature>_repository_impl.dart     # try/catch → Either
    domain/
      entities/     <thing>.dart                       # freezed, no JSON
      repositories/ <feature>_repository.dart          # abstract interface
    presentation/
      providers/    <feature>_providers.dart, <feature>_state.dart, <feature>_notifier.dart
      pages/  widgets/
```

There are **no use-case classes**: a notifier calls the repository
directly. Use cases add a file per verb and little else in apps of this
size. Small read-only features may skip `domain/repositories` and expose a
datasource through a `StreamProvider` (e.g. wishlist ids).

Scaffold a feature with the bundled script instead of hand-copying:

```bash
python3 <skill-dir>/scripts/new_feature.py --root <app-root> --feature lesson_notes --entity LessonNote --package my_app
```

It writes the 9 files from `templates/feature/` with names substituted.
Then run `dart run build_runner build -d`.

## 3. Layer rules (why they matter)

- **Datasources throw, repositories return `Either`.** Every repository
  method wraps its body in `try { … return Right(x); } catch (e, st) {
  return Left(mapToFailure(e, st)); }`. The UI then only ever handles
  `Failure`, with a localized `displayMessage` — no raw exception text
  reaches users.
- **Models vs entities.** Models know JSON/Firestore (`Timestamp`
  converters, `toJson`), entities don't. `model.toEntity()` lives on the
  model. This keeps Firestore types out of widgets and tests.
- **The client never writes privileged state.** Roles, entitlements,
  counters, aggregates and anything money-related are written by Cloud
  Functions. Datasources call a callable for those
  (see `firebase-backend-security`).
- **Enums carry wire values.** `enum CourseStatus { draft('draft') … }`
  with `fromWire()` that falls back safely; never `.name` from server
  data you don't control.

## 4. Riverpod conventions

- **DI = plain `Provider`.** `final xDataSourceProvider = Provider((ref) =>
  XDataSource(ref.watch(firestoreProvider)));` Repos depend on
  datasources the same way. Tests override these.
- **Reads = `StreamProvider` keyed on the current user.**
  `ref.watch(currentUserProvider)`; return `Stream.value(empty)` when
  signed out so guests never hit permission errors.
- **Many widgets, one listener.** Derive per-item selectors with
  `Provider.family` from one stream (e.g. `isSavedProvider(id)` reads a
  `Set<String>` stream) instead of a Firestore listener per card.
- **Mutations = `StateNotifier` + immutable state in its own file.**
  State is freezed (or a hand-rolled `copyWith` with an `_unset`
  sentinel for nullable fields). Optimistic UI: flip state, call repo,
  roll back on `Left`.
- **`autoDispose`** for page-scoped providers; keep app-wide ones alive.
- **Eager providers**: listeners that must exist before any UI (IAP
  purchase stream, notification bootstrap, session cleanup) are read once
  in `bootstrap.dart` via `container.read(...)` and the container is
  passed to `UncontrolledProviderScope`.
- Never call `ref.read` inside `build` for values the widget depends on —
  use `ref.watch`; use `ref.listen` for one-shot side effects (snackbars,
  navigation).

Templates: `templates/feature/presentation/providers/*`.

## 5. Flavors and Firebase init

1. `flavorizr.yaml` defines `dev` / `prod` (bundle ids `com.example.app.dev`
   / `com.example.app`). Run `flutterfire configure` once per Firebase
   project to produce `firebase_options_dev.dart` / `_prod.dart`.
2. `main.dart` maps Flutter's `appFlavor` (from `--flavor`) to `F.appFlavor`.
3. `bootstrap.dart` calls
   `Firebase.initializeApp(options: flavorOptions)` — the **DEFAULT** app.
   Every plugin uses `.instance`; a named app would leave the default bound
   to whatever native config file happened to be bundled.
4. **iOS: do not bundle `GoogleService-Info.plist`.** With Dart-side
   options a dev build can never silently talk to production. What the
   plist used to provide moves to per-flavor xcconfigs
   (`ios/Flutter/{dev,prod}{Debug,Profile,Release}.xcconfig`):
   `GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.…`, referenced as
   `$(GOOGLE_REVERSED_CLIENT_ID)` in Info.plist `CFBundleURLSchemes`.
   Google Sign-In then needs `clientId: Firebase.app().options.iosClientId`.
5. Android keeps `google-services.json` per flavor under
   `android/app/src/<flavor>/`.

Bootstrap order (template `templates/lib/bootstrap.dart`):
bindings → orientation → `Firebase.initializeApp` → App Check →
`onBackgroundMessage` → prefs → `ProviderContainer` → Crashlytics handlers
→ eager providers → `runApp(UncontrolledProviderScope)`.

## 6. Routing

- One `routerProvider` builds `GoRouter` with `refreshListenable` bound to
  auth state, so sign-in/out re-runs `redirect`.
- **Guest mode:** browsing is public; only paths in `_requiresAuth(loc)`
  (profile sub-pages, purchases, notes…) redirect to `/login?from=…`.
  Store reviewers and new users can explore before creating an account,
  which also satisfies App Review's "don't force login for non-account
  features".
- Tabs: `StatefulShellRoute.indexedStack` with a `ShellScaffold` that
  hosts the bottom bar (and things like a mini player).
- Full-screen flows (player, checkout) are top-level `GoRoute`s pushed
  over the shell.

Template: `templates/lib/core/routing/app_router.dart`.

## 7. Session hygiene

Sign-out must leave nothing of the previous user on the device:

- `BeforeSignOutHooks` — callbacks that need the user **still signed in**
  (e.g. `arrayRemove` this device's FCM token from `users/{uid}` — rules
  only allow the owner). `AuthNotifier.logout()` runs them, time-boxed,
  then calls `signOut()`.
- `sessionCleanupProvider` — listens for an authenticated →
  unauthenticated transition and stops players, wipes offline files,
  clears signed-URL caches, deletes the FCM token. Only fires on that
  transition so a guest's own data is untouched.

Templates: `templates/lib/core/session/before_sign_out_hooks.dart`,
`templates/lib/app/session_cleanup.dart`.

## 8. Material 3 layout pitfalls

These show up as red screens or silent layout failures; fix them the
same way every time:

- `FilledButton`/`ElevatedButton` inside a `Row`, `ListTile.trailing` or
  a `Wrap` → "BoxConstraints forces an infinite width" because M3 buttons
  default to `minimumSize: Size.fromHeight(…)` in some themes. Wrap in a
  bounded `SizedBox(width: …)` or use a compact hand-rolled
  `InkWell + Container` for trailing actions.
- `ListTile.trailing` with anything wider than an icon → use a custom
  `Row` row widget instead of fighting `ListTile`.
- `Tooltip` / `IconButton(tooltip:)` placed in `MaterialApp.builder`
  (above the Navigator) throws "No Overlay widget found" — use
  `Semantics(label:)` there instead.
- `Expanded` inside a `SingleChildScrollView` column → unbounded height;
  use `shrinkWrap` lists or `CustomScrollView` slivers.

## 9. New feature checklist

- [ ] Scaffolded with `scripts/new_feature.py`; build_runner run.
- [ ] Repository methods return `ResultFuture` and use `mapToFailure`.
- [ ] Providers watch `currentUserProvider` and handle signed-out.
- [ ] Every user-visible string in ARB (see `flutter-l10n-a11y`).
- [ ] Privileged writes go through a callable; rules deny client writes.
- [ ] Route added; `_requiresAuth` updated if it needs an account.
- [ ] Anything cached per user is cleared in `sessionCleanupProvider`.
- [ ] Widget/unit test for the notifier with overridden providers.

More detail and rationale: `references/patterns.md`.
