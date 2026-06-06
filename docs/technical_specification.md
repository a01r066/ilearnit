# iLearnIt — Technical Specification

A consolidated reference for the iLearnIt platform. Read this end-to-end on your first day; come back to individual sections as needed. Per-feature deep-dives live in sibling docs (see [§21 References](#21-references)).

---

## Table of contents

1. [Overview](#1-overview)
2. [Tech stack](#2-tech-stack)
3. [Repository layout](#3-repository-layout)
4. [Architecture principles](#4-architecture-principles)
5. [Feature catalog](#5-feature-catalog)
6. [Firestore data model](#6-firestore-data-model)
7. [Cloud Storage layout](#7-cloud-storage-layout)
8. [State management pattern](#8-state-management-pattern)
9. [Routing](#9-routing)
10. [Authentication & authorization](#10-authentication--authorization)
11. [In-app purchases & subscriptions](#11-in-app-purchases--subscriptions)
12. [Push notifications](#12-push-notifications)
13. [Internationalization (i18n)](#13-internationalization-i18n)
14. [Theming](#14-theming)
15. [Admin portal](#15-admin-portal)
16. [Search](#16-search)
17. [Cloud Functions](#17-cloud-functions)
18. [Build, run, deploy](#18-build-run-deploy)
19. [Coding conventions](#19-coding-conventions)
20. [Security model](#20-security-model)
21. [References](#21-references)

---

## 1. Overview

**iLearnIt** is a Tonebase-style online classical-music learning platform with three primary instrument verticals: **guitar**, **piano**, **violin**. It ships as:

- a **consumer mobile app** (iOS + Android, Flutter), and
- a **web admin portal** (Flutter web target of the same codebase).

The consumer app lets students browse courses by instrument, watch video lectures, sample sheet-music **songbooks**, subscribe to a Personal Plan, leave reviews, search, and receive push notifications. The admin portal lets staff manage courses, instructors, songbooks, applications, subscriptions, and broadcast notifications. Backend is **Firebase** — Auth, Firestore, Storage, Cloud Messaging, Cloud Functions.

### Product surfaces

| Surface | Entry point | Audience |
|---|---|---|
| Consumer mobile app | `lib/main.dart` → `App` | Students |
| Admin web portal | `lib/main_admin.dart` → `AdminApp` | Staff (instructors + admins) |
| Marketing landing page | `public/` → Firebase Hosting | Anonymous |
| Cloud Functions | `functions/src/index.ts` | Server-side automation |

---

## 2. Tech stack

| Layer | Choice | Why |
|---|---|---|
| Language | Dart 3.4+ | Sound null safety, sealed classes, pattern matching |
| UI | Flutter 3.22+ | Single codebase mobile + web admin |
| State | `flutter_riverpod` 3.x | Compile-time safety, scoped providers, family + autoDispose |
| Immutable data | `freezed` 3.x + `json_serializable` | Generated equality, copyWith, fromJson |
| Functional errors | `dartz` (`Either<Failure, T>`) | Forces caller to handle failures |
| Routing | `go_router` 17.x | Declarative, deep-link friendly, ShellRoute for tabs |
| Networking | `dio` + `pretty_dio_logger` | Interceptors for auth header attach |
| Firebase | `firebase_core/auth/firestore/storage/messaging` | First-party SDKs |
| IAP | `in_app_purchase` 3.x | One stream, both stores |
| Local notifications | `flutter_local_notifications` 17.x | Foreground display + tap routing |
| Secure storage | `flutter_secure_storage` | Tokens (Keychain / EncryptedSharedPrefs) |
| Prefs | `shared_preferences` | Non-sensitive flags + MRU lists |
| Connectivity | `connectivity_plus` | Network gate before remote calls |
| Charts | `fl_chart` | (Reserved for analytics) |
| Web file picking | `file_picker` 8.x | Admin cover/banner/media upload |
| Localization | `flutter_localizations` + `intl` + ARB | English + Vietnamese |
| Codegen | `build_runner` + `freezed` + `json_serializable` + `flutter_gen` | Generated code only |
| Flavors | `flutter_flavorizr` | `dev` + `prod` Firebase projects |

### Why these choices

- **freezed + json_serializable** match `flutter_riverpod`'s expectation of immutable state; the `.copyWith()` story makes notifiers ergonomic.
- **`Either<Failure, T>`** keeps repositories pure — the UI layer doesn't see exceptions, only typed failures.
- **`go_router` with `StatefulShellRoute.indexedStack`** lets each bottom-nav tab keep its own navigation stack across switches.
- **Single Firestore** for courses + instructors + songbooks + reviews avoids the cross-DB consistency problem; `users/{uid}` is the source of truth for role + subscription.

---

## 3. Repository layout

```
ilearnit/
├── android/           Native Android shell (signing in android/app/key.properties)
├── ios/               Native iOS shell (Runner.xcworkspace)
├── web/               Flutter web shell (index.html for both consumer + admin)
├── public/            Marketing landing page (Firebase Hosting)
├── functions/         Cloud Functions (TypeScript)
├── sample_data/       JSON seeds + seed_firestore.js (Node Admin SDK)
├── docs/              Per-feature design docs + this spec
├── firestore.rules    Security rules
├── firestore.indexes.json
├── firebase.json
├── pubspec.yaml
└── lib/
    ├── main.dart                    Consumer entry
    ├── main_admin.dart              Admin web entry
    ├── bootstrap.dart               Consumer init (Firebase, IAP, FCM, …)
    ├── bootstrap_admin.dart         Admin init
    ├── flavors.dart                 `F.appFlavor` enum + per-flavor knobs
    ├── firebase_options_{dev,prod}.dart
    │
    ├── app/                         Consumer MaterialApp.router shell
    │   └── app.dart
    │
    ├── core/                        Cross-cutting infrastructure
    │   ├── constants/               api_endpoints.dart (collection names), app_constants.dart
    │   ├── error/                   failure.dart (freezed sealed), exceptions.dart, error_mapper.dart
    │   ├── network/                 network_info.dart (connectivity gate), dio_client.dart, interceptors/
    │   ├── notifications/           FCM + flutter_local_notifications wrappers
    │   ├── routing/                 app_router.dart, route_names.dart, shell_scaffold.dart
    │   ├── storage/                 prefs_service.dart, secure_storage_service.dart
    │   ├── theme/                   app_theme.dart, theme_palette.dart, app_colors.dart, app_text_styles.dart
    │   ├── typedefs/                ResultFuture<T> = Future<Either<Failure, T>>
    │   ├── utils/                   extensions.dart (context.textTheme, etc.), validators.dart
    │   └── widgets/                 error_view, empty_view, loading_indicator, primary_button
    │
    ├── features/                    Consumer-facing feature modules
    │   ├── auth/                    Email/pw + Google + Apple sign-in
    │   ├── courses/                 List, detail, lectures, curriculum, reviews
    │   ├── home/                    Welcome + Featured + Popular-by-instrument carousels
    │   ├── instructors/             List + detail page with social links
    │   ├── profile/                 Profile + Settings + theme/language pickers
    │   ├── purchases/               Per-course IAP (PriceTier)
    │   ├── search/                  Suggestions + results + filters
    │   ├── songbooks/               5th nav tab — sheet music catalogue
    │   └── subscriptions/           Personal Plan monthly/yearly
    │
    ├── admin/                       Admin portal feature modules
    │   ├── admin_app.dart           MaterialApp.router
    │   ├── routing/                 admin_router.dart, admin_route_names.dart
    │   ├── shared/                  AdminScaffold (side nav), AdminProviders, UnauthorizedPage
    │   ├── auth/                    AdminLoginPage
    │   ├── dashboard/               Stats tiles
    │   ├── courses/                 Course CRUD + media upload
    │   ├── instructors/             Applications review + instructor management
    │   ├── songbooks/               Songbook CRUD
    │   ├── subscriptions/           Active subscribers + revoke/extend
    │   └── notifications/           Topic broadcast composer
    │
    ├── l10n/
    │   ├── app_en.arb               English source of truth
    │   ├── app_vi.arb               Vietnamese
    │   └── generated/               flutter gen-l10n output (committed)
    │
    └── shared/
        └── providers/               firebase_providers.dart, connectivity_provider.dart, storage_providers.dart
```

### File-naming conventions

- Domain: `<noun>_entity.dart` (freezed).
- Data: `<noun>_model.dart` (freezed + json), `<noun>_datasource.dart`, `<noun>_repository_impl.dart`.
- Presentation: `<feature>_state.dart` (freezed) + `<feature>_notifier.dart` (`StateNotifier`) + `<feature>_providers.dart` (Riverpod wiring) in **separate files** — this is non-negotiable per `CLAUDE.md`.

---

## 4. Architecture principles

### Clean architecture in layers

```
        ┌────────────────────────────────────────────────────┐
        │  Presentation (widgets + Riverpod providers)        │
        │  • depends on Domain entities                       │
        │  • watches State, calls Notifier methods            │
        └────────────────────────────────────────────────────┘
                              ▲
                              │  (typed)
        ┌────────────────────────────────────────────────────┐
        │  Domain (entities + repository interfaces)          │
        │  • framework-free                                   │
        │  • freezed entities; abstract repos return          │
        │    ResultFuture<T> = Future<Either<Failure, T>>     │
        └────────────────────────────────────────────────────┘
                              ▲
                              │  (impl)
        ┌────────────────────────────────────────────────────┐
        │  Data (models, datasources, repository impls)       │
        │  • freezed + JsonSerializable models                │
        │  • Firestore/IAP/Storage adapters                   │
        │  • catches exceptions, returns Failures             │
        └────────────────────────────────────────────────────┘
```

Cross-layer rules:

- **Domain never imports Flutter or Firebase.** It can be unit-tested without a binding.
- **Presentation never imports Firebase directly.** It speaks to providers, which speak to repositories.
- **Data is the only layer that catches exceptions.** Everything past it deals with `Either<Failure, T>`.

### Repository pattern

Every feature exposes a repository contract in domain that the data layer implements. Example signature:

```dart
abstract interface class CoursesRepository {
  ResultFuture<CoursesPage> fetchCourses({
    InstrumentCategory? category,
    CourseLevel? level,
    String? cursor,
    int limit = 20,
  });
  ResultFuture<CourseEntity> fetchCourseById(String id);
  ResultFuture<List<CourseEntity>> fetchFeatured({int limit = 5});
}
```

Notifiers unwrap the Either:

```dart
final result = await _repo.fetchFeatured();
result.fold(
  (failure) => state = state.copyWith(lastFailure: failure),
  (items)   => state = state.copyWith(featured: items),
);
```

### Network gate

`NetworkInfo.isConnected` is checked **before** every remote call in the repo:

```dart
if (!await _network.isConnected) return const Left(Failure.network());
```

This avoids hanging on captive-portal Wi-Fi and gives the UI a deterministic offline path.

---

## 5. Feature catalog

| Module | Routes (consumer) | Routes (admin) | Firestore | Storage |
|---|---|---|---|---|
| Auth | `/splash`, `/login`, `/signup` | `/login` | `users/{uid}` | — |
| Home | `/home` | — | `courses` (read) | — |
| Courses | `/courses`, `/courses/:id`, `/courses/:id/lectures/:lid` | — | `courses`, `courses/{id}/sections`, `courses/{id}/sections/{sid}/lectures`, `courses/{id}/reviews` | `courses/{id}/…` |
| Instructors | `/instructors`, `/instructors/:id` | — | `instructors` | — |
| Songbooks | `/songbooks`, `/songbooks/:id` | `/admin/songbooks`, `/admin/songbooks/:id` | `songbooks`, `songbooks/{id}/reviews` | `songbooks/{id}/…` |
| Purchases (per-course) | (in-app sheet) | — | (managed by IAP listener) | — |
| Subscriptions | `/profile/subscription`, `/profile/subscription/checkout` | `/admin/subscriptions` | `users/{uid}.subscription` (embedded map) | — |
| Search | `/search` | — | `courses` (read) | — |
| Profile | `/profile`, `/profile/settings`, `/profile/subscription` | — | `users/{uid}` | — |
| Reviews | (mounted in course detail) | — | `courses/{id}/reviews/{uid}` | — |
| Admin: applications | — | `/admin/applications` | `instructor_applications/{uid}` | — |
| Admin: instructors mgmt | — | `/admin/instructors` | `users` (where role=instructor) | — |
| Admin: all courses | — | `/admin/courses`, `/my-courses/:id` | `courses` | `courses/{id}/…` |
| Admin: notifications | — | `/admin/notifications` | `notification_broadcasts/{id}` | — |
| Cloud Functions | — | — | reads/writes across the above | — |

### Cross-feature integration matrix

| Consumer feature | Reads from | Writes to |
|---|---|---|
| Course detail | `courses/{id}`, `courses/{id}/sections`, `courses/{id}/reviews`, `enrollments`, `users/{uid}.subscription` | `courses/{id}/reviews/{uid}` (with rating + reviewCount recompute on course doc) |
| Buy course | App Store / Play Store | `enrollments/{id}` (via IAP listener) |
| Subscribe | App Store / Play Store | `users/{uid}.subscription` (client-side after IAP success) |
| Home — Popular by instrument | `courses where category == X` | — |
| Search | `courses` (full catalogue, capped at 200) | `SharedPreferences` (recent searches) |
| Songbooks tab | `songbooks where isBestseller == true`, `songbooks/{id}` | `SharedPreferences` (recent songbook MRU) |
| Notifications | — | Reads its own FCM token, writes to `users/{uid}.fcmTokens` |

---

## 6. Firestore data model

Top-level collections (one source of truth: `lib/core/constants/api_endpoints.dart`):

```
users/{uid}                         User profile + role + embedded subscription map + fcmTokens
instructors/{id}                    Instructor profile (independent of users)
instructor_applications/{uid}       Pending/approved/rejected instructor applications
courses/{id}                        Course doc
  sections/{sid}                    Module/section
    lectures/{lid}                  Video/audio/pdf lecture
  reviews/{userId}                  Course reviews (one per user)
songbooks/{id}                      Sheet-music book
  reviews/{reviewId}                Songbook reviews
enrollments/{id}                    User-bought course (one per (user, course))
notification_broadcasts/{id}        Admin-queued FCM broadcasts (Function consumes)
```

### Document shapes (selected)

**`users/{uid}`**
```jsonc
{
  "id": "abc123",
  "email": "thanh@example.com",
  "displayName": "Thanh",
  "photoUrl": "https://…",
  "emailVerified": true,
  "primaryInstrument": "piano",
  "role": "student",            // student | instructor | admin
  "isSuspended": false,
  "createdAt": "2025-…",
  "fcmTokens": ["fG2…", "x9k…"],
  "subscription": {              // embedded map; absent → no subscription
    "planId": "yearly",
    "productId": "info.ilearnit.personal_yearly",
    "startedAt": "2025-06-01T…",
    "expiresAt": "2026-06-01T…",
    "autoRenew": true,
    "canceledAt": null,
    "platform": "ios",
    "originalTransactionId": "…"
  }
}
```

**`courses/{id}`**
```jsonc
{
  "id": "course_015",
  "title": "Bach's Lute Suites for Modern Guitar",
  "summary": "…",
  "thumbnailUrl": "https://…",
  "category": "guitar",
  "level": "intermediate",
  "instructorId": "ins_003",
  "instructorName": "Marcus Reinhardt",
  "lessonCount": 12,
  "enrollmentCount": 540,
  "rating": 4.7,                 // recomputed by client when a review is written
  "reviewCount": 38,             // ditto
  "durationMinutes": 410,
  "isFeatured": true,
  "tags": ["bach", "fingerstyle"],
  "priceTier": "standard",       // basic | standard | premium
  "publishedAt": "2025-…"
}
```

**`courses/{id}/reviews/{userId}`**
```jsonc
{
  "id": "<userId>",
  "courseId": "course_015",
  "userId": "<userId>",
  "userName": "Thanh",
  "userPhotoUrl": "…",
  "rating": 5,                   // 1..5
  "body": "Best course I've taken.",
  "createdAt": "…",
  "updatedAt": "…"
}
```

**`songbooks/{id}`** — see `docs/songbooks.md` for full shape.
**`instructor_applications/{uid}`** — see `docs/admin_portal.md`.

### Aggregates

Two fields are denormalized for fast list rendering:

- `courses/{id}.rating` and `.reviewCount` — recomputed by `CourseReviewsDataSource._recomputeAggregate` after every review write. For large N (>5k per course), swap for a Cloud Function counter.
- `users/{uid}.subscription` — written client-side after a successful IAP. A server-side verifier (future) would replace this with receipt validation.

---

## 7. Cloud Storage layout

```
courses/{courseId}/
  thumbnail/{filename}                                Course thumbnail
  sections/{sectionId}/lectures/{lectureId}/
    media/{filename}                                  Video/audio/PDF
    resources/{filename}                              Sheet music PDF, exercises

songbooks/{songbookId}/
  cover/{filename}                                    Portrait 3:4
  banner/{filename}                                   Wide 16:9
```

Uploads go through `AdminStorageService`, which wraps `firebase_storage.putData` and emits a `Stream<UploadProgress>` so the editor UIs can show a `LinearProgressIndicator` while bytes upload.

Storage security rules live next to Firestore rules — see `docs/admin_portal.md` §Storage rules.

---

## 8. State management pattern

### File trinity per feature with a StateNotifier

```
presentation/providers/
  <feature>_state.dart        // @freezed, all UI-visible fields, with @Default values
  <feature>_notifier.dart     // StateNotifier<State> with action methods
  <feature>_providers.dart    // Riverpod wiring (datasource → notifier)
```

This is the project convention from `CLAUDE.md`. Don't merge them into one file; the separation makes each piece testable in isolation.

### Provider kinds and when to use them

| Type | Use case |
|---|---|
| `Provider<T>` | Stateless services + selectors (e.g. `firebaseAuthProvider`, `hasActiveSubscriptionProvider`). |
| `FutureProvider<T>` | One-shot async data with `.autoDispose` (e.g. `featuredCoursesProvider`, `popularByInstrumentProvider`). |
| `StreamProvider<T>` | Firestore subscriptions (`courseReviewsProvider`, `currentAdminUserProvider`). |
| `StateNotifierProvider<N, S>` | Mutable user-driven state (auth, search, reviews, subscriptions, theme). |

Use `.family` whenever the provider's value depends on an argument (`courseId`, `category`, `userId`). Use `.autoDispose` whenever the provider's data is screen-scoped.

### Eager-init pattern

Some providers must be alive before any UI renders so they catch background events. These are read once from `bootstrap.dart` after the `ProviderContainer` is built:

```dart
container.read(purchasesNotifierProvider);        // listens to IAP stream
container.read(subscriptionNotifierProvider);     // subscribes to user.subscription map
container.read(notificationBootstrapProvider);    // wires FCM + auth
```

If you add a notifier that needs to receive background events, eager-read it here.

---

## 9. Routing

Two independent routers — one per app.

### Consumer router (`lib/core/routing/app_router.dart`)

- Top-level routes: `/splash`, `/login`, `/signup`, `/search` (pushed above the shell), `/error`.
- `StatefulShellRoute.indexedStack` with **five** branches: Home, Courses, Instructors, Songbooks, Profile. Each branch has its own `GlobalKey<NavigatorState>` so navigation stacks persist across tab switches.
- Redirect logic uses `auth.isResolving` / `isAuthenticated` / `isUnauthenticated` from `AuthState` to bounce between `/splash`, `/login`, and `/home`.

Subscription detail page lives nested under profile so the bottom nav stays visible:

```
/profile
  /settings
  /subscription
    /checkout
```

### Admin router (`lib/admin/routing/admin_router.dart`)

- Public routes: `/login`, `/apply`, `/pending`, `/unauthorized`.
- `ShellRoute` wraps the rest with `AdminScaffold` (side nav).
- `_redirect()` enforces role-based access:

```
| signed-out               | → /login                              |
| signed-in, suspended     | → /unauthorized                        |
| signed-in, student       | → /apply or /pending                   |
| signed-in, instructor    | → /, except /admin/* → / (redirected) |
| signed-in, admin         | → /, all routes accessible             |
```

- A `_GoRouterRefreshStream` `ChangeNotifier` listens to `authNotifierProvider` and `currentAdminUserProvider` and calls `notifyListeners()` so `go_router` re-evaluates redirects on role changes.

---

## 10. Authentication & authorization

### Methods

- Email/password (Firebase Auth).
- Google Sign-In: native plugin on mobile; `FirebaseAuth.signInWithPopup` on web.
- Sign in with Apple: native plugin on iOS/macOS with nonce + sha256; `signInWithPopup` on web. See `docs/social_auth_setup.md` for Service ID and APNs setup.

All three flows funnel through `AuthRepository.{login, signup, signInWithGoogle, signInWithApple}` → `Either<Failure, UserEntity>`. The notifier maps `Failure.auth(code: 'cancelled')` to a silent return (no error snackbar when the user just dismisses the picker).

On first social sign-in, `_upsertSocialUser` creates the `users/{uid}` doc with `role: 'student'` (default).

### Roles (`UserRole` enum)

| Role | What they see | How to grant |
|---|---|---|
| `student` | Mobile app only | Default for every new user |
| `instructor` | Mobile app + admin portal (My Courses) | Approved instructor application via admin portal |
| `admin` | Mobile app + admin portal (everything) | Manual Firestore edit (one-time bootstrap), then admin-portal promotion |

`isSuspended: true` on the user doc revokes admin portal access entirely.

### Token persistence

Firebase ID tokens are written to `flutter_secure_storage` (Keychain / EncryptedSharedPreferences) after each successful sign-in, in case any non-Firebase backend calls need an `Authorization: Bearer` header through Dio interceptors.

---

## 11. In-app purchases & subscriptions

Two coexisting flows over **one** `purchaseStream`. `PurchasesNotifier` filters to per-course `PriceTier` products; `SubscriptionNotifier` filters to subscription products. Both write to Firestore on success.

### Per-course (`PriceTier`)

| Tier | Product ID | USD (fallback) | VND (fallback) |
|---|---|---|---|
| basic | `info.ilearnit.tier_basic` | $9.99 | ₫199.000 |
| standard | `info.ilearnit.tier_standard` | $19.99 | ₫399.000 |
| premium | `info.ilearnit.tier_premium` | $39.99 | ₫799.000 |

### Personal Plan (`SubscriptionPlan`)

| Plan | Product ID | USD | VND |
|---|---|---|---|
| Monthly | `info.ilearnit.personal_monthly` | $9.99 | ₫800.000 |
| Yearly | `info.ilearnit.personal_yearly` | $79.99 | ₫3.000.000 |

Both use auto-renewing subscriptions on App Store / Play Console.

### Course access gate

`hasUnlockedAccessProvider(courseId)` returns `true` if either: (a) `isCoursePurchasedProvider(courseId)` is `true`, OR (b) `hasActiveSubscriptionProvider` is `true`. `BuyCourseButton` reads it and swaps the "Unlock for ₫…" CTA for "Continue course" with an "Included in your Personal Plan" caption when subscribed.

Reviews use the same gate to control the "Write a review" CTA.

### Locale-aware pricing

The store-delivered `ProductDetails.price` wins at runtime. While waiting for store init we render `SubscriptionPlan.fallbackLabelFor(localeCode)` — `₫` for `vi`, USD otherwise.

See `docs/subscriptions.md` for the full IAP setup.

---

## 12. Push notifications

Architecture in `docs/push_notifications.md`. TL;DR:

- `bootstrap.dart` + `bootstrap_admin.dart` both register the top-level `firebaseMessagingBackgroundHandler` and eagerly create `notificationBootstrapProvider`.
- The bootstrap initializes `LocalNotificationsService`, `FcmService`, requests permission, binds the token to `users/{uid}.fcmTokens`, reconciles topic subscriptions on auth change.
- Foreground messages route through `LocalNotificationsService.show()` so they render while the app is open.
- Tap events from any state surface on `notificationTapsProvider`. The consumer app routes via the payload's `type` (`enrollment_created`, `application_approved`, `broadcast`, …); admin routes to `/`.

Three Cloud Functions on the send side:
- `onApplicationDecision` — DMs the applicant on approve/reject.
- `onEnrollmentCreated` — DMs the buyer with a deep-link to the course.
- `onNotificationBroadcast` — admin queues a broadcast; function fans out to the topic and flips status back.

---

## 13. Internationalization (i18n)

- ARB sources live at `lib/l10n/app_en.arb` (source of truth) and `lib/l10n/app_vi.arb`.
- `l10n.yaml` configures `flutter gen-l10n` with `synthetic-package: false` → output at `lib/l10n/generated/`.
- `nullable-getter: false` — `AppLocalizations.of(context)` returns non-null. No `!` ever needed.
- Use `t.someKey` everywhere user-facing. Placeholder strings (`{name}`, `{price}`) become typed methods on the generated `AppLocalizations` class.

### What's localized

- Navigation labels, Home headings, Settings, Auth, common actions, purchases, lecture lock messages, subscription/checkout, search chrome, songbook chrome, instructor detail chrome, popular section headings.

### What stays English for v1

- Admin portal chrome (internal staff tool).
- Filter sheet internal labels (Instrument, Level, etc.) — functional, low priority.
- Migration recipe per page in `docs/localization.md` if you want to translate more.

---

## 14. Theming

Single `AppTheme` class with a palette-driven builder. Three named themes shipped via `ThemeType` enum:

| Theme | Palette | Brightness |
|---|---|---|
| `vibrant` (default) | Violet primary + gold accent | Light |
| `professional` | Slate primary + sky accent | Light |
| `system` | Vibrant light + custom dark | Follows OS |

`AppTheme.{vibrant, professional, systemLight, systemDark}()` are one-line factories over a shared `_build(palette)` function. Adding a new theme = adding a new `ThemePalette` constant.

Theme choice persists via `PrefsService.themeMode`. The legacy `light` / `dark` values are remapped on load (`light → vibrant`, `dark → system`) so existing installs migrate cleanly.

`AppColors` keeps brand + instrument + status constants that widgets reference directly (e.g. `AppColors.guitar`, `AppColors.error`). The active `ColorScheme.primary` from `Theme.of(context)` is what theme-aware widgets read.

---

## 15. Admin portal

### Architecture

A second `MaterialApp.router` mounted from `lib/main_admin.dart` → `lib/bootstrap_admin.dart` → `lib/admin/admin_app.dart`. The mobile build never imports anything under `lib/admin/` — it's literally a different `flutter build web -t lib/main_admin.dart` target.

### Surfaces

| Page | Audience | Path |
|---|---|---|
| Dashboard | Instructor + Admin | `/` |
| My Courses | Instructor + Admin | `/my-courses`, `/my-courses/:id` (editor) |
| All Courses | Admin only | `/admin/courses` |
| Applications | Admin only | `/admin/applications` |
| Instructors | Admin only | `/admin/instructors` |
| Songbooks | Admin only | `/admin/songbooks`, `/admin/songbooks/:id` (editor) |
| Subscriptions | Admin only | `/admin/subscriptions` |
| Notifications | Admin only | `/admin/notifications` |

### Bootstrapping the first admin

Manually flip `users/{your-uid}.role = 'admin'` in Firebase Console once. Subsequent admins are promoted by an existing admin via the Instructors page (or by manual Firestore edit — the portal intentionally doesn't expose a "mint new admin" UI).

Full deployment + Firestore rules in `docs/admin_portal.md`.

---

## 16. Search

Single-screen modal pushed above the shell with two modes — Suggestions and Results — toggled by `SearchMode` in `SearchState`.

- Catalogue is pulled once on init (`SearchRemoteDataSource.fetchAllCourses(limit: 200)`) and re-ranked client-side on every keystroke (250ms debounced via `Timer`).
- Scoring: title prefix +5, title substring +3, tag +2, instructor / summary +1. Ties broken by `enrollmentCount`.
- Filter sheet (instruments, levels, minRating, maxPriceVnd) applies in-memory.
- Recent searches in `SharedPreferences` (MRU, capped at 8).
- Badges (Bestseller / Highest rated / New) computed from the current result set, not the catalogue.

For catalogues over a few hundred courses, swap to Algolia / Typesense / Firestore's `search_terms` array-contains pattern.

---

## 17. Cloud Functions

Located at `functions/`. TypeScript, deployed via `firebase deploy --only functions`. Initialised with the Admin SDK so they bypass Firestore rules.

| Function | Trigger | Purpose |
|---|---|---|
| `onApplicationDecision` | `onDocumentUpdated('instructor_applications/{uid}')` | DM the applicant when status flips to approved/rejected |
| `onEnrollmentCreated` | `onDocumentCreated('enrollments/{id}')` | DM the buyer with deep-link |
| `onNotificationBroadcast` | `onDocumentCreated('notification_broadcasts/{id}')` | Fan out to FCM topic + write `sentAt` |

The admin portal queues broadcasts by writing to `notification_broadcasts/{id}` with `status: 'pending'`. The Function picks it up and flips the status — the admin's UI re-renders live.

---

## 18. Build, run, deploy

### Flavors

`flutter_flavorizr` ships `dev` and `prod`. Each flavor maps to its own Firebase project (`ilearnit-dev` / `ilearnit-31f41`).

```bash
flutter run --flavor dev -t lib/main_dev.dart        # mobile dev
flutter run --flavor prod -t lib/main_prod.dart      # mobile prod
flutter run -d chrome -t lib/main_admin.dart --flavor dev   # admin web dev
```

### Codegen

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Run after editing any `@freezed` or `@JsonSerializable` class. Generates `*.freezed.dart` and `*.g.dart`.

### Localization

`flutter pub get` auto-runs `flutter gen-l10n` because `generate: true` is set in `pubspec.yaml`.

### Production builds

```bash
flutter build apk --flavor prod -t lib/main_prod.dart --release
flutter build appbundle --flavor prod -t lib/main_prod.dart --release
flutter build ipa --flavor prod -t lib/main_prod.dart --release --export-options-plist=ios/ExportOptions.plist
flutter build web -t lib/main_admin.dart --flavor prod --dart-define=FLAVOR=prod --release
```

Signing notes for Android + iOS in `docs/signing_and_publishing.md`.

### Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions --project ilearnit-dev
```

### Firestore

```bash
firebase deploy --only firestore:rules --project ilearnit-dev
firebase deploy --only firestore:indexes --project ilearnit-dev
```

`firebase.json` must declare the `firestore` block pointing at `firestore.rules` + `firestore.indexes.json`.

### Hosting

```bash
# landing page
firebase deploy --only hosting:landing
# admin portal
flutter build web -t lib/main_admin.dart --flavor prod --release
firebase deploy --only hosting:admin
```

---

## 19. Coding conventions

### Mandatory

1. **Separated state files.** `<feature>_state.dart`, `<feature>_notifier.dart`, `<feature>_providers.dart` are three files, never one.
2. **freezed for entities + models + states.** Plain Dart classes only for stateless utilities or sealed unions where freezed would be overkill (e.g. `SearchSuggestion`).
3. **`Either<Failure, T>`** in every repository return type. Map exceptions in data; UI never sees raw `Exception`.
4. **Network gate before remote calls.** `if (!await _network.isConnected) return const Left(Failure.network());`
5. **Use `t.someKey` everywhere user-facing.** Hard-coded strings are tolerated only in admin chrome and internal filter labels.
6. **Avoid `Platform.isIOS` in code that may compile to web.** Use `defaultTargetPlatform` (web-safe) and gate with `!kIsWeb` if needed.
7. **`autoDispose` on family providers** unless the data must outlive a route push. Stateful keep-alive only for: `purchasesNotifierProvider`, `subscriptionNotifierProvider`, `notificationBootstrapProvider`.

### Encouraged

- `const` constructors everywhere they fit.
- Private widgets (`_Foo`) inside the same file as the page that uses them; promote to `widgets/` only when reused.
- Snackbar errors via `context.showSnack` (from `core/utils/extensions.dart`), not bespoke `ScaffoldMessenger` calls.
- One responsibility per provider. Compose with `ref.watch(otherProvider)` rather than fattening one provider.
- Color hex literals at the top of the widget file, not inline.

### Discouraged

- Direct Firebase calls from UI widgets (use providers).
- `setState` after `await` without `if (!mounted) return;`.
- Importing `package:firebase_*` outside `lib/{features,admin,core}/.../data/`.
- Optional-positional args. Use named args for anything beyond 2 positional.

---

## 20. Security model

### Firestore rules

Consolidated at `firestore.rules`. Helpers: `isSignedIn()`, `uid()`, `userDoc()`, `role()`, `isSuspended()`, `isAdmin()`, `isInstructor()`.

Read access:
- **Public**: `courses`, `courses/*/sections`, `courses/*/sections/*/lectures`, `courses/*/reviews`, `instructors`, `songbooks`, `songbooks/*/reviews`.
- **Owner or admin**: `users/{userId}`, `instructor_applications/{userId}`, `enrollments/{id}` (where `userId == uid`).
- **Admin only**: `notification_broadcasts`.

Write access:
- **Author of own doc** (with field constraints): `users/{userId}` (carve out role + isSuspended), `instructor_applications/{userId}` (status must be 'pending'), `courses/{id}/reviews/{userId}` (rating ∈ 1..5), `notification_broadcasts/{id}` (createdBy == uid).
- **Instructor (owner of resource)**: `courses/{id}` and nested sections/lectures.
- **Admin**: everything.

### Storage rules

Mirror Firestore — public read of `courses/*` and `songbooks/*`, writes restricted to admin or owning instructor (resolved via a `firestore.get` cross-reference).

### Client-side gates

These are UX gates, not security gates — the rules above are what matters.

- `hasUnlockedAccessProvider(courseId)`: gates the "Continue course" CTA and the "Write a review" CTA.
- `hasActiveSubscriptionProvider`: gates the trial banner on the Songbooks tab.
- `currentRoleProvider` in admin portal: gates the nav items.

### Secret material

- API keys / config in `firebase_options_{dev,prod}.dart` — committed; these are designed to be public per Firebase guidance.
- IAP signing keys, APNs `.p8`, Google Service Account JSON — **never** committed. The Cloud Function CI/CD reads them from environment / Application Default Credentials.

---

## 21. References

Per-feature deep-dives:

| Doc | Covers |
|---|---|
| [`docs/admin_portal.md`](admin_portal.md) | Admin portal architecture, Firestore rules, build/deploy, first-admin bootstrap |
| [`docs/social_auth_setup.md`](social_auth_setup.md) | Google + Apple Sign-In setup for iOS, Android, and web (admin portal) |
| [`docs/push_notifications.md`](push_notifications.md) | FCM + local notifications + Cloud Functions + APNs + Android POST_NOTIFICATIONS |
| [`docs/subscriptions.md`](subscriptions.md) | Personal Plan IAP setup, Firestore schema, App Store / Play Console config |
| [`docs/songbooks.md`](songbooks.md) | Songbooks tab + detail + admin CRUD, schema, index hints, sample data |
| [`docs/signing_and_publishing.md`](signing_and_publishing.md) | Android signing config, iOS ExportOptions, store deployment |
| [`docs/localization.md`](localization.md) | i18n architecture, adding a new string, adding a new language |

External references:

- Firebase docs: <https://firebase.google.com/docs>
- go_router: <https://pub.dev/packages/go_router>
- flutter_riverpod: <https://riverpod.dev>
- freezed: <https://pub.dev/packages/freezed>
- in_app_purchase: <https://pub.dev/packages/in_app_purchase>
- App Store Connect IAP: <https://developer.apple.com/in-app-purchase/>
- Play Console Subscriptions: <https://support.google.com/googleplay/android-developer/answer/140504>

### Conventions cheat sheet

```dart
// Domain entity
@freezed
abstract class CourseEntity with _$CourseEntity {
  const CourseEntity._();
  const factory CourseEntity({
    required String id,
    required String title,
    @Default(0.0) double rating,
  }) = _CourseEntity;

  String get fallbackPrice => priceTier.fallbackPrice;
}

// Data model
@freezed
abstract class CourseModel with _$CourseModel {
  const CourseModel._();
  const factory CourseModel({
    required String id,
    @Default('') String title,
    @TimestampConverter() DateTime? publishedAt,
  }) = _CourseModel;
  factory CourseModel.fromJson(Map<String, dynamic> json) =>
      _$CourseModelFromJson(json);
  factory CourseModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CourseModel.fromJson({...data, 'id': doc.id});
  }
  CourseEntity toEntity() => CourseEntity(id: id, title: title);
}

// State
@freezed
abstract class FooState with _$FooState {
  const FooState._();
  const factory FooState({
    @Default(false) bool isLoading,
    Failure? lastFailure,
  }) = _FooState;
}

// Notifier
class FooNotifier extends StateNotifier<FooState> {
  FooNotifier(this._repo) : super(const FooState());
  final FooRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, lastFailure: null);
    final result = await _repo.something();
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, lastFailure: failure),
      (value)   => state = state.copyWith(isLoading: false /* + value field */),
    );
  }
}

// Providers
final fooNotifierProvider =
    StateNotifierProvider.autoDispose<FooNotifier, FooState>(
  (ref) => FooNotifier(ref.watch(fooRepositoryProvider)),
);
```

---

**Last updated:** 2026-06-06 — when in doubt, this doc is older than the code. Run `git log -- docs/technical_specification.md` to see when it was last touched, and `git log --since="<that date>" -- lib/` to see what's changed since.
