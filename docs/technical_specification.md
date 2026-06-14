# iLearnIt — Technical Specification

A single, authoritative reference for the iLearnIt platform. Read this end-to-end on your first day; come back to individual sections as needed. Per-feature deep-dives live in sibling docs (see [§35 References](#35-references)).

> **Last verified:** 2026-06-13 against `lib/`, `firebase.json`, `functions/src/index.ts` (11 functions), `firestore.rules`, the bottom-nav `shell_scaffold.dart` (Songbooks tab removed), and every doc in `docs/`. When in doubt, this file is older than the code — `git log -- docs/technical_specification.md` shows the last touch and `git log --since="<that date>" -- lib/` shows what's drifted.

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
12. [Push notifications & inbox](#12-push-notifications--inbox)
13. [Lecture progress & "Continue learning"](#13-lecture-progress--continue-learning)
14. [Offline downloads](#14-offline-downloads)
15. [Wishlist](#15-wishlist)
16. [Learning paths](#16-learning-paths)
17. [Course Q&A and lecture notes](#17-course-qa-and-lecture-notes)
18. [Practice tools (metronome + tuner)](#18-practice-tools-metronome--tuner)
19. [Onboarding flow](#19-onboarding-flow)
20. [App rating prompt](#20-app-rating-prompt)
21. [Observability (Crashlytics + Performance + Analytics)](#21-observability-crashlytics--performance--analytics)
22. [Internationalization (i18n)](#22-internationalization-i18n)
23. [Theming](#23-theming)
24. [Search](#24-search)
25. [Video pipeline: Cloudflare Stream](#25-video-pipeline-cloudflare-stream)
26. [Admin portal](#26-admin-portal)
27. [Landing-page CMS + marketing site](#27-landing-page-cms--marketing-site)
28. [Cloud Functions](#28-cloud-functions)
29. [Build, run, deploy](#29-build-run-deploy)
30. [Coding conventions](#30-coding-conventions)
31. [Security model](#31-security-model)
32. [Pagination, skeletons, refresh](#32-pagination-skeletons-refresh)
33. [Account deletion + legal docs](#33-account-deletion--legal-docs)
34. [Go-live roadmap status](#34-go-live-roadmap-status)
35. [References](#35-references)

---

## 1. Overview

**iLearnIt** is a Tonebase-style online classical-music learning platform with three primary instrument verticals — **guitar**, **piano**, **violin**. It ships as:

- a **consumer mobile app** (iOS + Android, Flutter);
- a **web admin portal** (Flutter web target of the same codebase); and
- a **marketing landing page** at `ilearnit.info` (static HTML on Firebase Hosting, content-managed from the admin portal via Firestore).

The consumer app lets students browse courses by instrument, watch HLS-streamed lectures (Cloudflare Stream), sample sheet-music **songbooks**, subscribe to a Personal Plan or buy individual courses, track lecture progress and resume, download lectures for offline viewing, save courses to a wishlist, follow editorial **learning paths**, ask questions, write personal notes, practice with a metronome + tuner, and receive push notifications mirrored to an in-app inbox.

The admin portal lets staff manage courses, instructor profiles, songbooks, learning paths, applications, subscriptions, broadcast notifications, edit the landing-page CMS, and read a revenue + cohort dashboard. Backend is **Firebase** — Auth, Firestore, Storage, Cloud Messaging, Cloud Functions, Crashlytics, Performance, Analytics, Hosting. Video lives on **Cloudflare Stream** with playback URLs resolved server-side.

### Product surfaces

| Surface | Entry point | Audience |
|---|---|---|
| Consumer mobile app | `lib/main.dart` → `App` | Students |
| Admin web portal | `lib/main_admin.dart` → `AdminApp` | Staff (instructors + admins) |
| Marketing landing page | `web/public/` → Firebase Hosting | Anonymous |
| Cloud Functions | `functions/src/index.ts` | Server-side automation |

---

## 2. Tech stack

| Layer | Choice | Why |
|---|---|---|
| Language | Dart 3.8+ | Sound null safety, sealed classes, pattern matching |
| UI | Flutter 3.22+ | Single codebase mobile + web admin |
| State | `flutter_riverpod` 3.x (+ `riverpod_annotation` 4.x) | Compile-time safety, scoped providers, family + autoDispose |
| Immutable data | `freezed` 3.x + `json_serializable` | Generated equality, copyWith, fromJson |
| Functional errors | `dartz` (`Either<Failure, T>`) | Forces caller to handle failures |
| Routing | `go_router` 17.x | Declarative, deep-link friendly, StatefulShellRoute for tabs |
| Networking | `dio` 5.x + `pretty_dio_logger` | Interceptors for auth header attach |
| Firebase | `firebase_core/auth/firestore/storage/messaging/crashlytics/performance/analytics/functions` | First-party SDKs |
| Video | Cloudflare Stream HLS + `video_player` | Server-resolved playback URLs; HLS native on iOS, ExoPlayer on Android |
| Audio | `just_audio` + `audioplayers` | Lecture playback + metronome ticks |
| IAP | `in_app_purchase` 3.x | One stream, both stores |
| Local notifications | `flutter_local_notifications` 17.x | Foreground display + tap routing |
| In-app review | `in_app_review` 2.x | OS-native rating sheet |
| Secure storage | `flutter_secure_storage` 10.x | Tokens + downloads manifest |
| Prefs | `shared_preferences` 2.x | Non-sensitive flags + MRU lists |
| Connectivity | `connectivity_plus` 7.x | Network gate before remote calls |
| Charts | `fl_chart` 1.x | Revenue + cohort analytics |
| Web file picking | `file_picker` 8.x | Admin cover/banner/media upload |
| Localization | `flutter_localizations` + `intl` + ARB | English + Vietnamese |
| Codegen | `build_runner` + `freezed` + `json_serializable` + `flutter gen-l10n` | Generated code only |
| Flavors | `flutter_flavorizr` | `dev` + `prod` Firebase projects |
| Document rendering | `flutter_markdown` 0.7.x | Bundled legal docs (privacy + terms) |
| Shimmer | `shimmer` 3.x | Skeleton placeholders |
| Cached images | `cached_network_image` 3.x | Thumbnails + covers |
| Cloud Functions runtime | Node.js 20 + TypeScript + `firebase-functions` v6 | Trigger + callable handlers |

### Why these choices

- **freezed + json_serializable** match `flutter_riverpod`'s expectation of immutable state; the `.copyWith()` story makes notifiers ergonomic.
- **`Either<Failure, T>`** keeps repositories pure — the UI layer doesn't see exceptions, only typed failures.
- **`go_router` with `StatefulShellRoute.indexedStack`** lets each bottom-nav tab keep its own navigation stack across switches.
- **Single Firestore** for the catalogue avoids cross-DB consistency problems; `users/{uid}` is the source of truth for role + subscription + topic subscriptions + fcmTokens.
- **Cloudflare Stream over Firebase Storage** for video — Storage egress is expensive and unindexed; Stream gives HLS, signed-URL support, and a CDN.

---

## 3. Repository layout

```
ilearnit/
├── android/           Native Android shell (signing in android/app/key.properties)
├── ios/               Native iOS shell (Runner.xcworkspace)
├── web/               Flutter web shell + static marketing site under web/public/
├── functions/         Cloud Functions (TypeScript, Node 20)
├── sample_data/       JSON seeds + seed_firestore.js + seed_site_content.js
├── docs/              Per-feature design docs + this spec
├── assets/
│   ├── legal/         privacy_policy.md + terms_of_service.md (bundled)
│   ├── audio/         Metronome click_high.wav + click_low.wav
│   └── images/        Logos, etc.
├── firestore.rules    Security rules (single file)
├── firestore.indexes.json
├── firebase.json      Firestore + Functions + Hosting + Flutter platforms
├── pubspec.yaml
└── lib/
    ├── main.dart                    Consumer entry
    ├── main_admin.dart              Admin web entry
    ├── bootstrap.dart               Consumer init (Firebase, IAP, FCM, observability)
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
    │   ├── notifications/           FCM + flutter_local_notifications + inbox + topic-prefs
    │   ├── observability/           Crashlytics, Performance, Analytics services + providers + bootstrap
    │   ├── routing/                 app_router.dart, route_names.dart, shell_scaffold.dart
    │   ├── storage/                 prefs_service.dart, secure_storage_service.dart
    │   ├── theme/                   app_theme.dart, theme_palette.dart, app_colors.dart, app_text_styles.dart
    │   ├── typedefs/                ResultFuture<T> = Future<Either<Failure, T>>
    │   ├── utils/                   extensions.dart, validators.dart
    │   └── widgets/                 error_view, empty_view, loading_indicator, skeleton primitives
    │
    ├── features/                    Consumer-facing feature modules
    │   ├── app_rating/              OS-native rating sheet trigger
    │   ├── auth/                    Email/pw + Google + Apple sign-in + reauth + deleteAccount
    │   ├── courses/                 List, detail, sections/lectures, reviews, Cloudflare resolver
    │   ├── downloads/               Offline lecture downloads (encrypted manifest)
    │   ├── home/                    Welcome + Featured + Continue Learning + Learning Paths rail + Popular-by-instrument
    │   ├── instructors/             List grid + detail page with social links
    │   ├── learning_paths/          Editorial multi-course sequences
    │   ├── legal/                   Bundled privacy + terms renderer
    │   ├── notes/                   Per-lecture personal notes (with optional timestamp)
    │   ├── onboarding/              3-screen first-run flow
    │   ├── practice/                Metronome + Tuner (Profile entry)
    │   ├── profile/                 Profile + Settings + theme/language/observability pickers
    │   ├── progress/                Lecture-progress tracking + rollup
    │   ├── purchases/               Per-course IAP (PriceTier)
    │   ├── qa/                      Course Q&A (per-lecture threads + verified-instructor replies)
    │   ├── search/                  Suggestions + results + filters
    │   ├── songbooks/               5th nav tab — sheet music catalogue
    │   ├── subscriptions/           Personal Plan monthly/yearly
    │   └── wishlist/                Saved courses + bookmark heart
    │
    ├── admin/                       Admin portal feature modules
    │   ├── admin_app.dart           MaterialApp.router
    │   ├── routing/                 admin_router.dart, admin_route_names.dart
    │   ├── shared/                  AdminScaffold (side nav), AdminProviders, UnauthorizedPage
    │   ├── auth/                    AdminLoginPage
    │   ├── dashboard/               Stats tiles
    │   ├── courses/                 Course CRUD + media upload + Cloudflare UID field
    │   ├── instructors/             Applications review + instructor management + instructor profile CRUD
    │   ├── songbooks/               Songbook CRUD
    │   ├── learning_paths/          Learning-path CRUD + ReorderableListView course picker
    │   ├── subscriptions/           Active subscribers + revoke/extend
    │   ├── notifications/           Topic broadcast composer
    │   ├── analytics/               Revenue + cohort + funnel dashboard
    │   └── site_content/            Landing-page CMS editor
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
- Presentation: `<feature>_state.dart` (freezed) + `<feature>_notifier.dart` (`StateNotifier`) + `<feature>_providers.dart` (Riverpod wiring) in **separate files** — non-negotiable per `CLAUDE.md`.

---

## 4. Architecture principles

### Clean architecture in layers

```
┌────────────────────────────────────────────────────┐
│  Presentation (widgets + Riverpod providers)       │
│  • depends on Domain entities                      │
│  • watches State, calls Notifier methods           │
└────────────────────────────────────────────────────┘
                      ▲
                      │  (typed)
┌────────────────────────────────────────────────────┐
│  Domain (entities + repository interfaces)         │
│  • framework-free                                  │
│  • freezed entities; abstract repos return         │
│    ResultFuture<T> = Future<Either<Failure, T>>    │
└────────────────────────────────────────────────────┘
                      ▲
                      │  (impl)
┌────────────────────────────────────────────────────┐
│  Data (models, datasources, repository impls)      │
│  • freezed + JsonSerializable models               │
│  • Firestore/IAP/Storage/Cloudflare adapters       │
│  • catches exceptions, returns Failures            │
└────────────────────────────────────────────────────┘
```

Cross-layer rules:

- **Domain never imports Flutter or Firebase.** It can be unit-tested without a binding.
- **Presentation never imports Firebase directly.** It speaks to providers, which speak to repositories.
- **Data is the only layer that catches exceptions.** Everything past it deals with `Either<Failure, T>`.

### Repository pattern

Every feature exposes a repository contract in domain that the data layer implements. Notifiers unwrap the Either:

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

| Module | Consumer routes | Admin routes | Firestore | Storage / external |
|---|---|---|---|---|
| Auth | `/splash`, `/login`, `/signup` | `/login`, `/apply`, `/pending`, `/unauthorized` | `users/{uid}`, `instructor_applications/{uid}` | — |
| Onboarding | `/onboarding` | — | `users/{uid}.primaryInstrument` + `.skillLevel` | — |
| Home | `/home` | — | `courses` (featured + popular), `learning_paths`, `users/{uid}/courseProgress` | — |
| Courses | `/courses`, `/courses/:id`, `/courses/:id/lectures/:lectureId` | `/admin/courses`, `/my-courses`, `/my-courses/:id` | `courses`, `courses/{id}/sections`, `…/lectures`, `…/reviews`, `…/questions`, `…/questions/{qid}/replies` | `courses/{id}/…` + Cloudflare Stream |
| Instructors | `/instructors`, `/instructors/:id` | `/admin/instructors`, `/admin/instructor-profiles`, `/admin/instructor-profiles/:id` | `instructors`, `users` (where role=instructor) | — |
| Songbooks (deep-link only — **not in bottom nav**) | `/songbooks`, `/songbooks/:id` (pushed above the shell) | `/admin/songbooks`, `/admin/songbooks/:id` | `songbooks`, `songbooks/{id}/reviews` | `songbooks/{id}/…` |
| Learning paths | `/learning-paths/:id` | `/admin/learning-paths`, `/admin/learning-paths/:id` | `learning_paths/{id}` | `learning_paths/{id}/cover/…` |
| Lecture player | `/courses/:id/lectures/:lectureId?at=N` | — | `courses/{id}/sections/{sid}/lectures/{lid}`, `users/{uid}/courseProgress`, `users/{uid}/notes`, `…/questions` | Cloudflare HLS, local downloads |
| Notes | `/profile/notes` | — | `users/{uid}/notes/{noteId}` | — |
| Q&A | `/courses/:id/lectures/:lectureId/qa/:questionId` | — | `…/questions/{qid}`, `…/questions/{qid}/replies/{rid}` | — |
| Purchases (per-course) | (in-app sheet) | — | `enrollments/{id}` (via IAP listener) | App Store / Play |
| Subscriptions | `/profile/subscription`, `/profile/subscription/checkout` | `/admin/subscriptions` | `users/{uid}.subscription` (embedded map) | App Store / Play |
| Wishlist | `/profile/wishlist` | — | `users/{uid}/wishlist/{courseId}` | — |
| Downloads | `/profile/downloads` | — | — | Local Documents dir + secure-storage manifest |
| Practice | `/profile/practice` | — | — | Bundled audio assets + mic |
| Notifications | `/notifications`, `/profile/settings/notifications` | `/admin/notifications` | `users/{uid}/notifications/{id}`, `users/{uid}.subscribedTopics`, `notification_broadcasts/{id}` | FCM |
| Search | `/search` | — | `courses` (top 200) | SharedPreferences (MRU) |
| Profile + Settings | `/profile`, `/profile/settings`, `/profile/settings/notifications`, `/profile/delete-account` | — | `users/{uid}` | — |
| Reviews | (mounted in course detail) | — | `courses/{id}/reviews/{userId}` | — |
| Legal | `/legal/:slug` | — | — | Bundled MD assets |
| My learning | `/profile/my-learning` | — | `users/{uid}/courseProgress` (rollup reuse) | — |
| Analytics | — | `/admin/analytics` | `users`, `enrollments`, `courses` (admin-scoped reads) | — |
| Landing-page CMS | — | `/admin/landing-page` | `site_content/landing` | — |
| Instructor revenue | — | `/my-revenue`, `/my-students` | `transactions` (own), `enrollments` (own course), `users/{uid}/courseProgress` | — |
| Admin revenue | — | `/admin/transactions`, `/admin/payouts` | `transactions`, `payouts` | — |
| Cloud Functions | — | — | reads/writes across the above | FCM, Cloudflare API |

---

## 6. Firestore data model

Top-level collections (single source of truth: `lib/core/constants/api_endpoints.dart`):

```
users/{uid}                                          User profile + role + embedded subscription + fcmTokens + subscribedTopics
  notifications/{id}                                 In-app inbox mirror of 1:1 pushes
  wishlist/{courseId}                                Bookmarks
  notes/{noteId}                                     Private lecture notes
  courseProgress/{courseId}                          Per-course progress rollup
    lectures/{lectureId}                             Per-lecture playhead + completed flag
instructors/{id}                                     Instructor profile (independent of users)
instructor_applications/{uid}                        Pending/approved/rejected
courses/{id}                                         Course doc
  sections/{sid}                                     Module/section
    lectures/{lid}                                   Video/audio/PDF lecture (cloudflareVideoId optional)
      questions/{qid}                                Q&A thread root
        replies/{rid}                                One nested level of replies
  reviews/{userId}                                   Course reviews (one per user)
songbooks/{id}                                       Sheet-music book
  reviews/{reviewId}                                 Songbook reviews
learning_paths/{pathId}                              Editorial multi-course sequence
enrollments/{id}                                     User-bought course (one per (user, course))
notification_broadcasts/{id}                         Admin-queued FCM broadcasts
site_content/{slug}                                  Landing-page CMS (slug = "landing" for the marketing site)
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
  "primaryInstrument": "piano",   // guitar | piano | violin | null
  "skillLevel": "intermediate",   // beginner | intermediate | advanced | null
  "role": "student",              // student | instructor | admin
  "isSuspended": false,
  "onboardingComplete": true,
  "createdAt": "2025-…",
  "fcmTokens": ["fG2…"],
  "subscribedTopics": ["all_users", "instrument_piano"],
  "metadata": { "lastRatingPromptAt": "…" },
  "subscription": {                // embedded map; absent → no subscription
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
  "rating": 4.7,
  "reviewCount": 38,
  "durationMinutes": 410,
  "isFeatured": true,
  "tags": ["bach", "fingerstyle"],
  "priceTier": "standard",         // basic | standard | premium
  "publishedAt": "2025-…"
}
```

**`courses/{id}/sections/{sid}/lectures/{lid}`** — lectures live as **individual Firestore docs in a subcollection** under each section, NOT as an embedded array on the section doc. The consumer's `CoursesRemoteDataSource.fetchSections` fetches the lectures subcollection per section in parallel (`Future.wait`) and hydrates the `lectures` field on each `CourseSectionModel` via `copyWith`. The admin writer and the Q&A / progress / notes / Cloudflare resolver all assume per-lecture docs.


```jsonc
{
  "id": "lec_001",
  "title": "Prelude",
  "type": "video",                 // video | audio | document
  "durationSec": 360,
  "mediaUrl": "https://…",         // legacy Firebase Storage URL
  "cloudflareVideoId": "bf53017eb20e5db311c21d30ffb5a075"  // ← 32-hex UID for Cloudflare Stream
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
  "rating": 5,                     // 1..5
  "body": "Best course I've taken.",
  "createdAt": "…",
  "updatedAt": "…"
}
```

**`users/{uid}/courseProgress/{courseId}`** (rollup) + `/lectures/{lid}` (per-lecture). See [§13](#13-lecture-progress--continue-learning).

**`users/{uid}/notes/{noteId}`** — see [§17](#17-course-qa-and-lecture-notes).

**`users/{uid}/wishlist/{courseId}`** — see [§15](#15-wishlist).

**`learning_paths/{pathId}`** — see [§16](#16-learning-paths).

**`site_content/{slug}`** — see [§27](#27-landing-page-cms--marketing-site).

**Songbooks, applications** — see `docs/songbooks.md` and `docs/admin_portal.md`.

### Aggregates

- `courses/{id}.rating` and `.reviewCount` — recomputed by `CourseReviewsDataSource._recomputeAggregate` after every review write. For large N (>5k per course), swap for a Cloud Function counter (P1-7).
- `users/{uid}/courseProgress/{cid}.completedCount` — only incremented on the non-completed → completed edge. The notifier reads the prior `completed` value before the batch write to guarantee idempotency.
- `users/{uid}.subscription` — written client-side after a successful IAP. A server-side verifier (P0-1, future) would replace this with receipt validation.
- Question `replyCount` + `isInstructorAnswered` use `FieldValue.increment(1)` in the same batch as the reply write.

---

## 7. Cloud Storage layout

```
courses/{courseId}/
  thumbnail/{filename}                                Course thumbnail
  sections/{sectionId}/lectures/{lectureId}/
    media/{filename}                                  Legacy video/audio/PDF (Cloudflare for new)
    resources/{filename}                              Sheet music PDF, exercises

songbooks/{songbookId}/
  cover/{filename}                                    Portrait 3:4
  banner/{filename}                                   Wide 16:9

learning_paths/{pathId}/
  cover/{filename}                                    Path cover (one-shot upload)
```

Uploads go through `AdminStorageService`, which wraps `firebase_storage.putData` and emits a `Stream<UploadProgress>` for lecture media (so editor UIs can show a `LinearProgressIndicator`). Learning-path covers use a one-shot `uploadLearningPathCover` returning `Future<String>` — a path cover is a single JPEG; a progress bar is overkill.

Storage security rules mirror Firestore — public read of `courses/*` and `songbooks/*`, writes restricted to admin or owning instructor via a `firestore.get` cross-reference. See `docs/admin_portal.md` §Storage rules.

---

## 8. State management pattern

### File trinity per feature with a StateNotifier

```
presentation/providers/
  <feature>_state.dart        // @freezed, all UI-visible fields, with @Default values
  <feature>_notifier.dart     // StateNotifier<State> with action methods
  <feature>_providers.dart    // Riverpod wiring (datasource → notifier)
```

Project convention from `CLAUDE.md`. Don't merge them; the separation makes each piece testable in isolation. A handful of small features (downloads, lecture-progress, onboarding, delete-account, app-rating) keep their state classes hand-rolled (no codegen) because they have ≤4 fields and the equality bookkeeping isn't worth a freezed pass — flagged in their respective docs.

### Provider kinds and when to use them

| Type | Use case |
|---|---|
| `Provider<T>` | Stateless services + selectors (e.g. `firebaseAuthProvider`, `hasActiveSubscriptionProvider`, `cloudflareStreamServiceProvider`). |
| `FutureProvider<T>` | One-shot async data with `.autoDispose` (e.g. `featuredCoursesProvider`, `popularByInstrumentProvider`, `cloudflareStreamPlaybackProvider`, `analyticsSnapshotProvider`). |
| `StreamProvider<T>` | Firestore subscriptions (`courseReviewsProvider`, `currentAdminUserProvider`, `wishlistStreamProvider`, `notificationsInboxProvider`, `learningPathsStreamProvider`, `continueLearningProvider`). |
| `StateNotifierProvider<N, S>` | Mutable user-driven state (auth, search, reviews, subscriptions, theme, downloads, onboarding, lecture-progress, wishlist toggle, topic toggles, analytics range, landing-page CMS draft). |

Use `.family` whenever the provider depends on an argument. Use `.autoDispose` whenever the data is screen-scoped.

### Eager-init pattern

Some providers must be alive before any UI renders so they catch background events. These are read once from `bootstrap.dart` after the `ProviderContainer` is built:

```dart
container.read(purchasesNotifierProvider);        // listens to IAP stream
container.read(subscriptionNotifierProvider);     // subscribes to user.subscription map
container.read(notificationBootstrapProvider);    // wires FCM + auth + inbox
container.read(observabilityBootstrapProvider);   // wires auth → Crashlytics/Analytics user-id
```

If you add a notifier that needs to receive background events, eager-read it here.

---

## 9. Routing

Two independent routers — one per app.

### Consumer router (`lib/core/routing/app_router.dart`)

Top-level routes (above the shell so the bottom nav is hidden):

```
/splash, /login, /signup, /onboarding, /search, /notifications,
/legal/:slug, /learning-paths/:id, /error
```

`StatefulShellRoute.indexedStack` with **five** branches — Home, Courses, Instructors, Songbooks, Profile. Each branch owns a `GlobalKey<NavigatorState>` so navigation stacks persist across tab switches.

Nested per-branch routes:

```
/home
/courses          → /courses/:id → /courses/:id/lectures/:lectureId?at=N
                                      → /qa/:questionId?sectionId=…
/instructors      → /instructors/:id
/songbooks        → /songbooks/:id
/profile
  /settings
    /notifications      (preferences)
  /subscription
    /checkout
  /wishlist
  /downloads
  /notes
  /practice
  /delete-account
```

Redirect logic uses `AuthState.isResolving / isAuthenticated / isUnauthenticated` and runs in **four** branches:

```
Launch ─► Splash ─► Onboarding (first run only) ─► Login (skippable) ─► Home
                                                       │
                                                       └─ "Continue as guest" → Home
```

1. **Resolving** — splash sticks; everything else redirects to splash.
2. **Onboarding not done** — runs FIRST, before the auth check. Both guests and authenticated users get the 3-screen onboarding (instrument → skill level → notifications soft-ask) on a fresh install. Legal pages stay reachable so the footer links on the onboarding screens still work.
3. **Authenticated** — kick out of pre-shell screens (splash / login / signup / onboarding) to `/home`; everything else is open.
4. **Guest (signed out, onboarding done)** — *guest browse mode*. Splash bounces to `/login`. From `/login` the user can sign in OR tap "Continue as guest" to drop into `/home`. The full shell (Home / Courses / Instructors / Songbooks / Profile), `/courses/:id`, `/courses/:id/lectures/:lectureId` (free-preview lectures only — paid ones still hit the BuyCourseButton gate), `/instructors/:id`, `/songbooks/:id`, `/search`, `/learning-paths/:id`, and `/legal/*` are all guest-reachable. The `_requiresAuth(loc)` helper at the bottom of `app_router.dart` enumerates the per-user routes that DO still bounce to `/login`: `/profile/subscription[/checkout]`, `/profile/wishlist`, `/profile/notes`, `/profile/delete-account`, `/profile/settings/notifications`, and `/notifications`.

### Pre-auth onboarding answers

The picker steps (instrument + skill level) used to write directly to `users/{uid}` via `AuthRepository.updateProfile`. In the new flow, onboarding runs **before** sign-in — there's no `uid` yet. `OnboardingNotifier.finish()` branches:

- **If a Firebase user is already signed in** (the re-onboarding case), it writes straight to `users/{uid}` like before.
- **If the user is a guest** (the common case), it stashes the answers in `PrefsService.pendingPrimaryInstrument` + `.pendingSkillLevel`. The auth bootstrap reads these on the next successful sign-in, writes them to `users/{uid}`, and calls `clearPendingOnboarding()`.

Action-level gates (BuyCourseButton, BookmarkButton, "Write a review", "Ask a question", "Add note") still need to detect `currentUser == null` on tap and route to `/login` — the router gate only catches direct URL access.

A `FirebaseAnalyticsObserver` is attached to the router for automatic `screen_view` events (see [§21](#21-observability-crashlytics--performance--analytics)).

### Admin router (`lib/admin/routing/admin_router.dart`)

Public routes: `/login`, `/apply`, `/pending`, `/unauthorized`.

`ShellRoute` wraps the rest with `AdminScaffold` (side nav). Authenticated paths:

```
/                              dashboard
/my-courses                    instructor's own courses list
/my-courses/:id                course editor
/admin/courses                 (admin) all courses
/admin/applications            (admin) instructor applications queue
/admin/instructors             (admin) active instructors
/admin/instructor-profiles     (admin) instructor profile CRUD
/admin/instructor-profiles/:id (admin) instructor profile editor
/admin/songbooks               (admin) songbooks list
/admin/songbooks/:id           (admin) songbook editor
/admin/learning-paths          (admin) learning paths list
/admin/learning-paths/:id      (admin) learning path editor
/admin/subscriptions           (admin) active subscribers
/admin/notifications           (admin) broadcast composer
/admin/analytics               (admin) revenue + cohorts
/admin/landing-page            (admin) marketing-site CMS editor
```

Role guard:

| signed-out | → `/login` |
| signed-in, suspended | → `/unauthorized` |
| signed-in, student | → `/apply` or `/pending` |
| signed-in, instructor | → `/`, `/admin/*` redirected back |
| signed-in, admin | → all routes accessible |

A `_GoRouterRefreshStream` `ChangeNotifier` listens to `authNotifierProvider` and `currentAdminUserProvider`, calling `notifyListeners()` so `go_router` re-evaluates redirects on role changes.

---

## 10. Authentication & authorization

### Methods

- Email/password (Firebase Auth).
- Google Sign-In: native plugin on mobile; `FirebaseAuth.signInWithPopup` on web.
- Sign in with Apple: native plugin on iOS/macOS with nonce + sha256; `signInWithPopup` on web. See `docs/social_auth_setup.md` for Service ID + APNs setup.

All three flows funnel through `AuthRepository.{login, signup, signInWithGoogle, signInWithApple}` → `Either<Failure, UserEntity>`. The notifier maps `Failure.auth(code: 'cancelled')` to a silent return (no error snackbar when the user dismisses the picker). On first social sign-in, `_upsertSocialUser` creates `users/{uid}` with `role: 'student'`.

### Roles

| Role | What they see | How to grant |
|---|---|---|
| `student` | Mobile app only | Default for every new user |
| `instructor` | Mobile app + admin portal (My Courses) | Approved instructor application via admin portal |
| `admin` | Mobile app + admin portal (everything) | Manual Firestore edit (one-time bootstrap), then admin-portal promotion |

`isSuspended: true` revokes admin portal access entirely.

### Re-auth + account deletion

Firebase rejects `deleteUser()` if the token is older than ~5 min, so `DeleteAccountPage` re-authenticates first, branching on `currentUser.providerData[*].providerId` (`password`, `google.com`, `apple.com`). After confirmation, the client calls the `deleteAccount` Cloud Function — see [§33](#33-account-deletion--legal-docs).

### Token persistence

Firebase ID tokens are written to `flutter_secure_storage` after each successful sign-in, so non-Firebase Dio calls can attach `Authorization: Bearer` via interceptors.

---

## 11. In-app purchases & subscriptions

Two coexisting flows over **one** `purchaseStream`. `PurchasesNotifier` filters to per-course `PriceTier` products; `SubscriptionNotifier` filters to subscription products. Both write to Firestore on success.

### Per-course (`PriceTier`)

| Tier | Product ID | USD (fallback) | VND (fallback) |
|---|---|---|---|
| basic | `info.ilearnit.tier_basic` | $9.99 | ₫199.000 |
| standard | `info.ilearnit.tier_standard` | $19.99 | ₫399.000 |
| premium | `info.ilearnit.tier_premium` | $39.99 | ₫799.000 |

Non-consumable. Restore-purchases supported via `Profile → Restore purchases`.

### Personal Plan (`SubscriptionPlan`)

| Plan | Product ID | USD | VND |
|---|---|---|---|
| Monthly | `info.ilearnit.personal_monthly` | $9.99 | ₫800.000 |
| Yearly | `info.ilearnit.personal_yearly` | $79.99 | ₫3.000.000 |

Both auto-renewing on the same subscription group. Trial flag (7-day free) is pending (P1-2).

### Course access gate

`hasUnlockedAccessProvider(courseId)` returns `true` when either `isCoursePurchasedProvider(courseId)` is true OR `hasActiveSubscriptionProvider` is true. `BuyCourseButton` reads it and swaps the "Unlock for ₫…" CTA for "Continue course" with an "Included in your Personal Plan" caption when subscribed. The reviews "Write a review" CTA uses the same gate.

### Trust model

**Client writes the entitlement after a successful purchase.** Firestore rules let users write their own `subscription` map (carved out from the general user write). A server-side verifier (P0-1) is on the roadmap — see `docs/go_live_roadmap.md`.

### Locale-aware pricing

Store-delivered `ProductDetails.price` wins at runtime. While waiting for store init we render `SubscriptionPlan.fallbackLabelFor(localeCode)` — `₫` for `vi`, USD otherwise. Same for per-course tiers.

Full setup in `docs/iap_setup.md` and `docs/subscriptions.md`.

---

## 12. Push notifications & inbox

### Send side — Cloud Functions

| Function | Trigger | Purpose |
|---|---|---|
| `onApplicationDecision` | `onDocumentUpdated('instructor_applications/{uid}')` | DM the applicant on approve/reject |
| `onEnrollmentCreated` | `onDocumentCreated('enrollments/{id}')` | DM the buyer with deep-link |
| `onCoursePriceDrop` | `onDocumentUpdated('courses/{id}')` | Notify wishlisters when `priceTier` rank decreases |
| `onCourseQuestionCreated` | `onDocumentCreated('courses/{cid}/sections/{sid}/lectures/{lid}/questions/{qid}')` | DM the course instructor |
| `onNotificationBroadcast` | `onDocumentCreated('notification_broadcasts/{id}')` | Fan out to FCM topic + flip status |

All 1:1 triggers use a shared `notifyUser(uid, notification, data)` helper that fires the FCM push **and** mirrors a row into `users/{uid}/notifications/{id}` in parallel.

### Topic catalogue (synced between client + Functions)

| Topic | Who's on it | Used by |
|---|---|---|
| `all_users` | Every device on launch | Admin broadcasts |
| `instrument_guitar` / `_piano` / `_violin` | Users with matching `primaryInstrument` | Per-instrument announcements |
| `admins` | Users with `role: 'admin'` | Platform alerts |

`reconcileTopicsForUser(role, instrument)` runs on every auth user change so promoting someone to admin or changing their instrument rebalances their subs automatically.

### Client wiring

`bootstrap.dart` + `bootstrap_admin.dart` both register `firebaseMessagingBackgroundHandler` and eagerly create `notificationBootstrapProvider`. The bootstrap:

- Initializes `LocalNotificationsService` + `FcmService`.
- Requests permission (Android 13+ runtime; iOS APNs).
- Binds the token to `users/{uid}.fcmTokens` (arrayUnion).
- Forwards foreground messages to `LocalNotificationsService.show()`.
- Surfaces taps via `notificationTapsProvider`; the consumer app's `App._handleTap` routes by `payload.type` (`enrollment_created`, `application_approved`, `broadcast`, `price_drop`, `question_created`).

### In-app inbox + topic preferences

`users/{uid}/notifications/{id}` mirrors every 1:1 push (broadcasts not mirrored — see `docs/notifications_inbox.md` §6). The `NotificationBell` widget renders an unread badge; `/notifications` shows the list with mark-read, mark-all-read, swipe-delete, clear-all. Settings → Notifications exposes per-topic switches whose state is reflected in `users/{uid}.subscribedTopics` (mirror, since FCM doesn't expose a "list my topics" API).

Full architecture in `docs/push_notifications.md` and `docs/notifications_inbox.md`.

---

## 13. Lecture progress & "Continue learning"

`users/{uid}/courseProgress/{courseId}` is a rollup doc with `/lectures/{lid}` sub-docs for per-lecture playheads. See `docs/lecture_progress.md` for the field-by-field schema; key points:

- `LectureProgressNotifier` throttles to **one write per 10 s** in steady state, but flushes immediately on the playing → paused edge, on completion (`positionSec ≥ 0.95 × durationSec`), and from `dispose()`.
- The rollup's `completedCount` is incremented only on the non-completed → completed edge (idempotent — rewatching does not double-count).
- Both `VideoLecturePlayer` and `AudioLecturePlayer` emit whole-second ticks plus the pause edge to drive the notifier.
- A `MetaRegistry` is updated when each `LecturePlayerPage` builds, so the rollup picks up renamed/recovered course titles + thumbnails on the next flush.

Three read providers:

| Provider | Where used |
|---|---|
| `courseProgressSummaryProvider(courseId)` | Course detail — `CourseProgressCard` (LinearProgressIndicator + Resume CTA) |
| `lectureProgressByCourseProvider(courseId)` | Lecture player — seeds `initialPositionSec` |
| `continueLearningProvider(limit)` | Home tab — "Continue learning" rail (newest-first, self-hides when empty) |

Firestore rules: owner-only, no admin override. Aggregate "how many students finished my course?" stats should come from a future Cloud Function writing denormalized totals to `courses/{id}`.

### Coupling with the app-rating prompt

`LectureProgressNotifier` exposes an `onLectureCompleted` callback that fires once on the completion edge. The `progress_providers.dart` wiring funnels it into `AppRatingNotifier.recordCompletedLecture` — see [§20](#20-app-rating-prompt).

---

## 14. Offline downloads

Subscribers + course owners can download lecture media to view offline. `docs/offline_downloads.md` carries the full design; condensed:

- **Media bytes** live in app-private Documents at `downloads/{lectureId}.{mp4|m4a|pdf}`. Removed on uninstall.
- **Manifest** sits in `flutter_secure_storage` (Keychain on iOS / EncryptedSharedPrefs on Android) under key `downloads_manifest_v1` — encrypted-at-rest per P1-8 acceptance criteria.
- Engine is Dio + `CancelToken` per `lectureId`. Status machine: `none → queued → downloading → completed | failed | paused`. Resume is a fresh `enqueue` (no `Range:` resume in v1 — filed as future work).
- A broadcast `Stream<DownloadProgressEvent>` drives both the per-lecture `LectureDownloadButton` and the `/profile/downloads` page so the two surfaces never diverge.
- Manifest writes throttled to every ~256 KB to avoid hammering EncryptedSharedPrefs (which re-encrypts the whole blob on every write on Android).
- The lecture player swaps in `Uri.file(localPath).toString()` when the download is complete; the network swap is transparent to `video_player` / `just_audio`.
- No native permissions needed — `getApplicationDocumentsDirectory()` writes inside the app sandbox on both platforms.

Note: download support currently caches **legacy Firebase Storage URLs only**. Offline playback of Cloudflare HLS streams requires the Cloudflare Stream offline-DRM SDK (Mux-style) and is filed as future work.

---

## 15. Wishlist

Bookmark courses for later + price-drop alerts. See `docs/wishlist.md`.

- Doc id == course id under `users/{uid}/wishlist/{courseId}` → O(1) toggle + perfect dedup.
- Denormalized `title`, `thumbnailUrl`, `instructorName`, `priceTier` on each entry — no N+1 reads on the Saved list.
- `WishlistToggleNotifier` keeps an in-memory optimistic overlay (`optimisticallyAdded` / `optimisticallyRemoved`) so the heart flips within one frame on flaky 3G. Rolled back + snackbar on write failure.
- Bookmark heart on `CourseCard` (top-right of thumbnail, absorbs its own tap), `CourseDetailPage` `SliverAppBar` actions, and `SearchResultTile`.
- Profile → Saved tile subtitle counts via `wishlistCountProvider`.

**Price-drop notification** — `onCoursePriceDrop` Cloud Function: when a course's `priceTier` rank drops (basic < standard < premium), it queries `collectionGroup('wishlist').where('courseId', '==', cid)`, updates each saver's denorm `priceTier`, and sends a push + inbox row via `notifyUser`. Chunked at 20 recipients per `Promise.all` to keep within FCM quotas.

Required composite index: `wishlist.courseId` (collection group) — already in `firestore.indexes.json`.

---

## 16. Learning paths

Editorial multi-course sequences (think Tonebase "Classical Guitar from Scratch — 12 Weeks"). Implements P2-5. See `docs/learning_paths.md`.

- `learning_paths/{pathId}` with `courseIds: array<string>` (order significant), `title`, `summary`, `coverUrl`, `instrument?`, `totalHours`, `isPublished`.
- Consumer datasource filters `isPublished == true`; admin datasource doesn't, so editors can find drafts.
- Home rail (`LearningPathsRail`) self-hides when empty.
- Detail page (`/learning-paths/:id`) lists courses in order with per-course progress bars (via `courseProgressSummaryProvider` + `courseByIdProvider`), routes each row into the existing `CourseDetailPage`.
- Admin: `AdminLearningPathsPage` list + `LearningPathEditorPage` (flat single-page layout — see file-header comment for the hit-test bug history that drove the rewrite). Course picker uses a query-filtered list that excludes already-selected courses; selected courses use a reorderable rendering with up/down arrows (not `ReorderableListView` — that triggered the same Material 3 hit-test bug).
- Cover upload uses one-shot `uploadLearningPathCover` on `AdminStorageService`.
- Composite indexes: `(isPublished, createdAt desc)` and `(isPublished, instrument, createdAt desc)`.

---

## 17. Course Q&A and lecture notes

Two side-by-side feature modules that ship inside the lecture player body.

### Q&A — `docs/qa.md`

Per-lecture comment threads with a one-level reply trail. Replies don't have replies — flat moderation, flat UI.

```
courses/{cid}/sections/{sid}/lectures/{lid}/questions/{qid}
  body: 5..2000 chars
  replyCount, isInstructorAnswered (FieldValue.increment / one-shot flag)
  replies/{rid}
    body: 1..2000 chars
    isInstructor: bool   ← denormalized at write time; rules enforce that only the course instructor or admin can set true
```

- `LectureQASection` shows up to 3 latest questions + "Ask" CTA + "See all N".
- `QuestionThreadPage` reads `courseByIdProvider` to compute `isInstructorOfCourse` and stamps it into the `ReplyFormKey`.
- `VerifiedInstructorBadge` widget — pill component, `compact: true` for the question list.
- `onCourseQuestionCreated` Cloud Function notifies the instructor.
- Routing: `/courses/:id/lectures/:lectureId/qa/:questionId?sectionId=…` (sectionId as query param, not path segment, so URLs stay short and shareable).

### Notes — `docs/notes.md`

Private per-user notes that can pin to a playback position.

```
users/{uid}/notes/{noteId}
  body: 1..4000 chars
  timestampSec: int?   ← null = unpinned
  courseId + lectureId + denormalized course/lecture titles
```

- `PlaybackPositionRegistry` (plain singleton exposed via Riverpod `Provider`) — the video/audio player writes the current position on every `onTick`. The "Add note" sheet polls it at tap time instead of subscribing (would rebuild every consumer every second).
- `WriteNoteSheet` pre-fills `timestampSec` from the registry; user can clear it inline.
- `LectureNotesSection` (embedded in `_LectureBody`) shows up to 5 timestamped notes plus an Add CTA.
- `/profile/notes` shows the full list grouped by course title; tapping a note's timestamp pill routes into the lecture player with `?at=N` (the player reads the query param and passes it as `initialPositionOverrideSec`).
- Firestore rule: owner-only, no admin override — notes are private even from moderation tools.

`deleteAccount` cascades both subcollections (notes + wishlist).

---

## 18. Practice tools (metronome + tuner)

Profile → Practice tools (`/profile/practice`). Reachable from Profile instead of a 6th nav slot (would crowd the labels). See `docs/practice_tools.md`.

- **Metronome** — `just_audio` `AudioPlayer` × 2 (accent + regular) driven by a BPM-derived `Timer.periodic`. WAV assets at `assets/audio/click_high.wav` and `click_low.wav`. Tap-tempo uses the median of the last 5 inter-tap intervals (cleared after 3s pause). BPM clamped to 40..240. Visual heartbeat pulses even when audio is muted.
- **Tuner** — pitch math is pure Dart (`PitchMath.fromHz` → note + cents). Mic capture is **pluggable** via the `TunerEngine` interface; default is `StubTunerEngine` that emits `PitchReading.none`. Wire a real engine (e.g. `flutter_audio_capture` + `pitch_detector_dart`) at app boot by overriding `tunerEngineProvider`. Native permission boilerplate (`NSMicrophoneUsageDescription`, `RECORD_AUDIO`) documented in the same doc.

Both tabs share nothing except a `DefaultTabController`.

---

## 19. Onboarding flow

3-screen first-run flow gated by `prefs.onboardingDone`. See `docs/onboarding.md`. Implements P1-1.

- Step 1: Instrument picker (guitar/piano/violin) → writes `users/{uid}.primaryInstrument`.
- Step 2: Skill level (beginner/intermediate/advanced) → writes `users/{uid}.skillLevel`.
- Step 3: Notifications soft-ask — explains value, then triggers the OS prompt only on tap. Decline doesn't block "Done" — copy reassures the user they can enable later.
- `Skip` flips the prefs flag without the profile writes.
- Offline `finish()` returns `Failure.network`, snackbar shown, prefs flag NOT set so retry works.
- Web variant: not shown — the admin portal bypasses onboarding.

Router redirect: `isAuthenticated && !prefs.onboardingDone → /onboarding`.

---

## 20. App rating prompt

OS-native rating sheet via `in_app_review`. Implements P1-12. See `docs/app_rating_prompt.md`.

Gating policy:

```
if now - installedAt < 7 days             → false
if completedLectureCount < 3              → false
if now - lastRatingPromptAt < 90 days     → false
if !InAppReview.isAvailable()             → false
→ true
```

- `bootstrap.dart` calls `prefs.setInstalledAtIfMissing(DateTime.now())` once.
- Lecture-progress notifier's `onLectureCompleted` callback fires `AppRatingNotifier.recordCompletedLecture()`, which increments `completedLectureCount` and calls `_maybePrompt()`.
- `prefs.lastRatingPromptAt` is stamped **before** the plugin call so a failed/cancelled prompt still respects the 90-day cooldown.
- Best-effort mirror to `users/{uid}.metadata.lastRatingPromptAt` for a future read-back-on-install feature.

Thresholds live in `AppConstants` (one-line A/B knob).

---

## 21. Observability (Crashlytics + Performance + Analytics)

Implements P0-6. See `docs/observability.md`.

Three Firebase SDKs (`firebase_crashlytics`, `firebase_performance`, `firebase_analytics`) wired through `lib/core/observability/`:

```
analytics_events.dart            Typed event + parameter + user-property constants
analytics_service.dart           Wrapper over FirebaseAnalytics
crashlytics_service.dart         Wraps FirebaseCrashlytics + error handlers
performance_service.dart         Wraps FirebasePerformance; trace() helper
observability_providers.dart     Riverpod wiring
observability_bootstrap.dart     Auth → setUserId + user-properties link
```

- **Off in debug, on in release**, overridable in `Settings → Privacy → Send anonymous usage data` (`prefs.observabilityOptOut`). Toggle takes effect immediately AND on next launch.
- **Auto-`screen_view`**: a `FirebaseAnalyticsObserver` is attached to the GoRouter.
- **User properties** synced from auth: `role`, `skill_level`, `primary_instrument`, `subscription_plan`, `onboarding_complete`.
- **Performance traces** via `perf.trace('name', () async => …)` — auto-stops on throw and on return.
- **Fatal crashes** captured automatically via `FlutterError.onError` + `PlatformDispatcher.onError` + isolate listener.
- **Non-fatals**: `crashlytics.recordError(err, stack, reason: '…')`.
- **Breadcrumbs**: `crashlytics.log('search:no_results')`.

iOS Crashlytics needs the Run Script Phase (`"$PODS_ROOT/FirebaseCrashlytics/run"`) — config detailed in the doc. Android pulls the SDKs from gradle plugins already wired for FCM.

---

## 22. Internationalization (i18n)

- ARB sources: `lib/l10n/app_en.arb` (source of truth) and `lib/l10n/app_vi.arb`.
- `l10n.yaml`: `synthetic-package: false` (output at `lib/l10n/generated/`), `nullable-getter: false` (so `AppLocalizations.of(context)` returns non-null).
- `pubspec.yaml` has `generate: true` — `flutter pub get` auto-runs `flutter gen-l10n`.

### What's localized

Navigation, Home headings + popular sections, Settings (themes + language + observability + notifications), Auth labels + social-button copy + legal footer, common actions, purchases, lecture lock messages, subscription + checkout, search chrome, songbook chrome, instructor detail chrome, learning paths, downloads, wishlist, notifications inbox + topic toggles, Q&A, notes, onboarding, practice tools chrome, delete account.

### What stays English for v1

- Admin portal chrome (internal staff tool).
- Filter sheet internal labels (Instrument, Level, etc.).
- Legal document bodies (titles localized, body markdown EN-only — `_vi.md` variants are a documented extension).

Migration recipe per page in `docs/localization.md`.

---

## 23. Theming

Single `AppTheme` class with a palette-driven builder. Three named themes shipped via `ThemeType`:

| Theme | Palette | Brightness |
|---|---|---|
| `vibrant` (default) | Violet primary + gold accent | Light |
| `professional` | Slate primary + sky accent | Light |
| `system` | Vibrant light + custom dark | Follows OS |

`AppTheme.{vibrant, professional, systemLight, systemDark}()` are one-line factories over a shared `_build(palette)`. Adding a new theme = adding a new `ThemePalette` constant.

Theme choice persists via `PrefsService.themeMode`. Legacy `light` / `dark` values are remapped on load (`light → vibrant`, `dark → system`).

`AppColors` keeps brand + instrument + status constants (e.g. `AppColors.guitar`, `AppColors.error`). The active `ColorScheme.primary` from `Theme.of(context)` is what theme-aware widgets read.

Skeleton primitives in `lib/core/widgets/skeleton.dart` (`SkeletonShimmer`, `SkeletonBox`, `SkeletonText`, `SkeletonAvatar`) recolor automatically because they read `surfaceContainerHighest` + `surfaceContainerHigh` from the active scheme.

---

## 24. Search

Single-screen modal pushed above the shell with two modes — Suggestions and Results — toggled by `SearchMode` in `SearchState`.

- Catalogue pulled once on init (`SearchRemoteDataSource.fetchAllCourses(limit: 200)`); re-ranked client-side on every keystroke (250 ms debounce).
- Scoring: title prefix +5, title substring +3, tag +2, instructor / summary +1. Ties broken by `enrollmentCount`.
- Filter sheet (instruments, levels, minRating, maxPriceVnd) applies in-memory.
- Recent searches in `SharedPreferences` (MRU, capped at 8).
- Badges (Bestseller / Highest rated / New) computed from the current result set.

For catalogues over a few hundred courses, the documented swap path is Typesense (self-hosted on a $5 droplet, indexed via Cloud Function trigger) → Algolia. The `SearchRepository` interface stays stable across phases (see `docs/go_live_roadmap.md` P1-15).

---

## 25. Video pipeline: Cloudflare Stream

Lectures stream via **Cloudflare Stream HLS**. The Flutter client carries only the 32-hex video UID (`lecture.cloudflareVideoId`); the Cloud Function holds the API token and returns playback URLs on demand. See `docs/cloudflare_stream.md`.

### Token hygiene

The Cloudflare API token **never** ships in the Flutter binary. It lives only in Firebase Secrets:

```
firebase functions:secrets:set CLOUDFLARE_API_TOKEN
firebase functions:secrets:set CLOUDFLARE_ACCOUNT_ID
```

If the token ever leaks (chat history, screenshot, repo), rotate immediately at Cloudflare dashboard → My Profile → API Tokens. Use the "Read Stream and Stream Videos" template — read-only is enough for playback resolution.

### Data flow

```
admin editor ─► cloudflareVideoId on the lecture doc
                       │
                       ▼ (consumer)
              ref.watch(cloudflareStreamPlaybackProvider(uid))
                       │
                       ▼ httpsCallable
                resolveStreamPlayback  ← Cloud Function (secrets injected)
                       │
                       ▼ GET /accounts/{id}/stream/{uid}
                Cloudflare Stream API
                       │
                       ▼ {hlsUrl, dashUrl, thumbnailUrl, durationSec, readyToStream}
                       ▼
            video_player plays the HLS URL
```

### Playback resolution order

`_VideoBody` in `lecture_player_page.dart` picks:

1. **Local downloaded file** (`file://…`) — if `localMediaPathForLectureProvider` is set.
2. **Cloudflare Stream HLS** — when `lecture.cloudflareVideoId` is set.
3. **Legacy Firebase Storage `mediaUrl`** — for pre-migration lectures.

This makes the migration safe: existing lectures keep working, new lectures use Cloudflare, and migration can be per-section.

### Caching

`CloudflareStreamService` keeps in-memory resolutions for **50 minutes** (Cloudflare's signed-URL default TTL is 60). Cache is bound to the Riverpod container — killed on app cold start, Riverpod container recreation, and sign-out.

Manual invalidation (after the admin replaces a video):

```dart
ref.read(cloudflareStreamServiceProvider).invalidate(videoId);
ref.invalidate(cloudflareStreamPlaybackProvider(videoId));
```

### Auth gate

The callable requires `request.auth` — anonymous scrapers cannot enumerate UIDs. If a paywall is added later (e.g. "this lecture requires enrollment"), the check goes inside `resolveStreamPlayback` before the fetch.

### Signed URLs (future)

If "Require signed URLs" is toggled on a Cloudflare video, mint a signed JWT in `resolveStreamPlayback` (`jsonwebtoken` npm + Firebase Secret `CLOUDFLARE_STREAM_SIGNING_KEY`). Code skeleton in `docs/cloudflare_stream.md`.

### HLS support per platform

- **iOS** — native via AVPlayer (`video_player` plugin).
- **Android** — ExoPlayer (`video_player` v2.8+).
- **Web** — `video_player_web` doesn't ship HLS; use the Cloudflare iframe (`https://customer-<code>.cloudflarestream.com/<uid>/iframe`) or add `hls.js`. Out of scope for v1.

### Admin editor

`lib/admin/courses/presentation/course_editor_page.dart` exposes a "Cloudflare Stream video UID" TextField on the lecture dialog — paste the 32-hex UID from the Cloudflare dashboard URL.

---

## 26. Admin portal

A second `MaterialApp.router` mounted from `lib/main_admin.dart` → `lib/bootstrap_admin.dart` → `lib/admin/admin_app.dart`. The mobile build never imports `lib/admin/` — it's literally a different `flutter build web -t lib/main_admin.dart` target. See `docs/admin_portal.md`.

### Surfaces

| Page | Audience | Path |
|---|---|---|
| Dashboard | Instructor + Admin | `/` |
| My Courses | Instructor + Admin | `/my-courses`, `/my-courses/:id` (editor) |
| My Revenue | Instructor + Admin | `/my-revenue` — own-instructor KPIs + recent transactions + Export CSV |
| My Students | Instructor + Admin | `/my-students` — own enrollments grouped by course + Message students (broadcast) + Export CSV |
| All Courses | Admin only | `/admin/courses` |
| Applications | Admin only | `/admin/applications` |
| Instructors (active) | Admin only | `/admin/instructors` |
| Instructor profiles (CRUD on `instructors/` collection) | Admin only | `/admin/instructor-profiles`, `/admin/instructor-profiles/:id` |
| Songbooks | Admin only | `/admin/songbooks`, `/admin/songbooks/:id` |
| Learning paths | Admin only | `/admin/learning-paths`, `/admin/learning-paths/:id` |
| Subscriptions | Admin only | `/admin/subscriptions` |
| Notifications | Admin only | `/admin/notifications` |
| Analytics | Admin only | `/admin/analytics` |
| Transactions | Admin only | `/admin/transactions` — table + status filter + per-row Refund |
| Payouts | Admin only | `/admin/payouts` — list + Mark paid (bookkeeping only) |
| Landing-page CMS | Admin only | `/admin/landing-page` |

### Instructor revenue & student management

Udemy-style revenue + students surface on the admin web portal. Full
spec in `docs/instructor_revenue.md`. Highlights:

- **Two new Firestore collections** — `transactions` (paid / refunded
  purchase records, masked `last4` only — never full card data) and
  `payouts` (periodic per-instructor bookkeeping; `pending` → `paid`).
- **Privacy enforced server-side.** Firestore rules restrict
  `transactions` reads to `studentUid == uid || instructorId == uid
  || isAdmin()`. Instructors literally cannot read another
  instructor's purchases.
- **Refund flow.** Admin clicks Refund on `/admin/transactions` →
  `processRefund` Cloud Function flips status, cancels the
  enrollment, notifies the student via inbox + push. v1 is
  bookkeeping-only — process the storefront refund out-of-band.
- **Instructor → students broadcast.** "Message students" on
  `/my-students` calls `instructorBroadcast` which server-side
  resolves the enrolled-student list (instructor never sees emails or
  FCM tokens) and fans out via the existing `notifyUser` helper.
- **In-browser CSV download** on every page — pure Dart `buildCsv`
  helper + `dart:html` Blob URL trigger (`csv_export.dart`).

### Course editor — hit-test history

A long series of "Cannot hit test a render box with no size" crashes in Material 3 drove several admin editors to be rewritten with a flat single-page layout instead of the original `Form` + `TextFormField` validators + `DropdownButtonFormField` + `ReorderableListView` + `ListTile` stack. The learning-path editor's class-level dartdoc captures the list of widgets that were the root cause. Apply the same pattern (plain TextField, ChoiceChip Wrap, hand-rolled reorderable rows with up/down arrows, no bare `Material` panel wrappers without explicit dimensions, no `FilledButton.icon` next to `Expanded` in a Row) when adding new editors.

### Bootstrapping the first admin

Manually flip `users/{your-uid}.role = 'admin'` in Firebase Console once. Subsequent admins are promoted by an existing admin via the Instructors page (the portal intentionally doesn't expose a "mint new admin" UI).

### Analytics dashboard

`docs/analytics.md` carries the full spec. Highlights:

- Reads three collections in a single load: `courses`, `enrollments`, `users`. ~26k document reads at v1 scale (5k users / 1k subscribers / 20k enrollments) — fine for an admin-only page.
- Revenue valuation: course purchase = USD fallback price (basic $9.99 / standard $19.99 / premium $39.99); subscription = `SubscriptionPlan.fallbackUsd / billingPeriodMonths` per active month, straight-lined across `[startedAt, expiresAt]`.
- Cohort matrix: monotonically retained ("once they pay, they're retained forever"). Triangular shape — row N has `12 - N` populated cells.
- Funnel stages: Signed up → Onboarded (`onboardingComplete == true OR skillLevel != null`) → Made a payment → Active subscribers.
- `AnalyticsRange` enum: 90d, 6m, 12m, YTD. `analyticsSnapshotProvider` caches by window; manual "Refresh" button invalidates.
- Escape hatch at scale: nightly Cloud Function writes `analytics/monthly/{YYYY-MM}` and `analytics/cohorts/{YYYY-MM}` pre-aggregated docs.

Full deployment + Firestore + Storage rules in `docs/admin_portal.md`.

---

## 27. Landing-page CMS + marketing site

The marketing site at `web/public/` is hydrated from a single Firestore doc at `site_content/landing`. See `docs/site_content_cms.md`.

### Data model

```
site_content/landing
  hero: {eyebrow, title, subtitle, ctaPrimary{Label,Href}, ctaSecondary{Label,Href}, imageUrl?}
  features: [{icon, title, description}]
  pricingTiers: [{name, priceLabel, billingNote, ctaLabel, ctaHref, isFeatured, perks: [string]}]
  faqs: [{question, answer}]
  contact: {email, phone, address, twitterUrl, instagramUrl, youtubeUrl}
  updatedAt: Timestamp
```

One fat document instead of subcollections — the static site needs every section in one round-trip; subdivisions add latency without buying anything for a tightly-scoped editorial product.

### Static hydration

`web/public/assets/js/cms.js` runs on every visit:

1. Initializes Firebase with the inlined `firebaseConfig` (currently pointing at `ilearnit-31f41`).
2. Fetches `site_content/landing`. If anything fails (SDK not loaded, ad blocker, doc missing, `firebaseConfig` not populated), the static fallback HTML stays — the page never appears broken.
3. Resolves `data-cms="path.to.field"` against the doc and rewrites `textContent`.
4. Resolves `data-cms-href="…"` / `data-cms-src="…"` and rewrites the attribute.
5. For each `data-cms-list="features"` container, clones the matching `<template id="cms-tpl-feature">` once per item with `{{field}}` mustache substitution. Arrays inside an item iterate via `{{#perks}}<li>{{.}}</li>{{/perks}}`. Every value is HTML-escaped — templates are author-controlled but values come from Firestore and should not inject markup.

### Admin editor

`/admin/landing-page` (admin role required). Five sections — Hero, Features (reorderable), Pricing, FAQ (reorderable), Contact + social. Save publishes immediately. "Save changes" only lights up when the form draft diverges from the last loaded snapshot (deep equality on Freezed entities). "Discard changes" reverts.

### Firestore rules

```
match /site_content/{slug} {
  allow read: if true;     // public — landing site fetches anonymously
  allow write: if isAdmin();
}
```

### Seeding a new project

```
node sample_data/seed_site_content.js
```

Sets the full doc to the defaults baked into the static fallback HTML so the live site looks identical before any editorial work.

### Hosting

`firebase.json` has a `hosting` block pointing at `web/public/` with `cleanUrls`, `trailingSlash: false`, an SPA-style rewrite to `/404.html`, and aggressive cache headers on `/assets/{css,js,img}/**` (`max-age=604800` / `max-age=2592000`) while HTML stays `max-age=0, must-revalidate`.

---

## 28. Cloud Functions

Located at `functions/`. TypeScript, Node 20, deployed via `firebase deploy --only functions`. Initialised with the Admin SDK so they bypass Firestore rules.

| Function | Type | Trigger / signature | Purpose |
|---|---|---|---|
| `onApplicationDecision` | Firestore | `onDocumentUpdated('instructor_applications/{uid}')` | DM applicant on approve/reject + write inbox row |
| `onEnrollmentCreated` | Firestore | `onDocumentCreated('enrollments/{id}')` | DM buyer with deep-link + inbox row |
| `onNotificationBroadcast` | Firestore | `onDocumentCreated('notification_broadcasts/{id}')` | Fan out to FCM topic + flip status |
| `onCoursePriceDrop` | Firestore | `onDocumentUpdated('courses/{id}')` | Notify wishlisters when `priceTier` rank drops |
| `onCourseQuestionCreated` | Firestore | `onDocumentCreated('courses/{cid}/sections/{sid}/lectures/{lid}/questions/{qid}')` | DM the course instructor |
| `deleteAccount` | Callable | `onCall` | Cascade-delete user's data + Auth record (see [§33](#33-account-deletion--legal-docs)) |
| `resolveStreamPlayback` | Callable | `onCall({secrets: [CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID]})` | Resolve a Cloudflare Stream video UID to HLS + DASH URLs. **No auth required** in v1 (guest-browse mode for preview lectures); paywall enforcement is client-side via `BuyCourseButton` + `isAccessible` on the lecture tile |
| `createCloudflareUpload` | Callable | `onCall({secrets: [CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID]})` | Instructor/admin only. Mints a one-time Cloudflare Stream Direct-Creator-Upload URL + UID. The admin course editor uses it to upload video files straight to Cloudflare — the API token never leaves the server. See [§25](#25-video-pipeline-cloudflare-stream) |
| `processRefund` | Callable | `onCall` (admin role required) | Flip `transactions/{id}.status = 'refunded'`, cancel the matching enrollment, notify the student via inbox + push. v1 is bookkeeping-only — no storefront refund integration. See `docs/instructor_revenue.md` |
| `markPayoutPaid` | Callable | `onCall` (admin role required) | Flip `payouts/{id}.status = 'paid'`, stamp `paidAt` + `paidByUid` + `payoutMethod`. v1 bookkeeping-only — process the actual transfer out-of-band |
| `instructorBroadcast` | Callable | `onCall` (instructor or admin) | Fan out a push + inbox row to every student enrolled in the caller's course. Server-side cross-check that the caller owns the course; admin bypasses ownership. Powers the "Message students" button on `/my-students` |

### Shared helpers

- `notifyUser(uid, notification, data)` — fires FCM push and writes `users/{uid}/notifications/{id}` in parallel (`Promise.all`).
- `writeInbox(uid, …)` — server-side inbox mirror (creates are server-only by rule).
- `deleteSubcollection(path)` — batched 200-doc deletes; used by `deleteAccount` to clear `notes`, `wishlist`, `courseProgress`, etc.

### Deployment quirks

The `firebase.json` `functions` block has **no `predeploy`** array — the TypeScript build is manual:

```
cd /Users/thanhminh/Documents/Claude/Projects/ilearnit/ilearnit/functions
npm run build      # compiles src/index.ts → lib/index.js
cd ..
firebase deploy --only functions:resolveStreamPlayback --project ilearnit-dev
```

This worked around a `predeploy` quirk where `cd "$RESOURCE_DIR" && npm run build` resolved `$RESOURCE_DIR` differently depending on the cwd of the `firebase deploy` invocation. To restore an automatic predeploy, run `firebase deploy` from the project root and add `"predeploy": ["npm --prefix \"$RESOURCE_DIR\" run build"]` back to `firebase.json`.

For local testing, the Firebase Functions shell skips the deploy round-trip:

```
firebase functions:shell --project ilearnit-dev
> resolveStreamPlayback({videoId: 'bf53017eb20e5db311c21d30ffb5a075'}, {auth: {uid: 'test'}})
```

---

## 29. Build, run, deploy

### Flavors

`flutter_flavorizr` ships `dev` and `prod`. Each flavor maps to its own Firebase project (`ilearnit-dev` / `ilearnit-31f41`).

```bash
flutter run --flavor dev -t lib/main_dev.dart                            # mobile dev
flutter run --flavor prod -t lib/main_prod.dart                          # mobile prod
flutter run -d chrome -t lib/main_admin.dart --dart-define=FLAVOR=dev    # admin web dev
```

> Flutter web doesn't propagate `--flavor` through to `appFlavor` like mobile, so the admin web entry reads `FLAVOR` via `--dart-define`.

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
flutter build ipa --flavor prod -t lib/main_prod.dart --release --export-options-plist=ios/ExportOptions-AppStore.plist
flutter build web -t lib/main_admin.dart --dart-define=FLAVOR=prod --release
```

Android keystore + iOS signing in `docs/signing_and_publishing.md`.

### Cloud Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions --project ilearnit-dev
```

Secrets (one-time):

```bash
firebase functions:secrets:set CLOUDFLARE_API_TOKEN
firebase functions:secrets:set CLOUDFLARE_ACCOUNT_ID
```

### Firestore

```bash
firebase deploy --only firestore:rules --project ilearnit-dev
firebase deploy --only firestore:indexes --project ilearnit-dev
```

`firebase.json` declares the `firestore` block pointing at `firestore.rules` + `firestore.indexes.json`.

### Hosting

```bash
# Landing page (web/public/)
firebase deploy --only hosting --project ilearnit-prod

# Admin portal (separate target — alias 'admin' configured via firebase target:apply)
flutter build web -t lib/main_admin.dart --dart-define=FLAVOR=prod --release
firebase deploy --only hosting:admin --project ilearnit-prod
```

Setting up the admin Hosting target documented in `docs/admin_portal.md` §Deploy.

### Seed data

```bash
node sample_data/seed_firestore.js          # courses + instructors + songbooks + learning_paths
node sample_data/seed_site_content.js       # landing-page CMS defaults
```

---

## 30. Coding conventions

### Mandatory

1. **Separated state files.** `<feature>_state.dart`, `<feature>_notifier.dart`, `<feature>_providers.dart` — three files, never one.
2. **freezed for entities + models + states** (small hand-rolled states are tolerated for ≤4-field cases).
3. **`Either<Failure, T>`** in every repository return type. Map exceptions in data; UI never sees raw `Exception`.
4. **Network gate before remote calls.** `if (!await _network.isConnected) return const Left(Failure.network());`
5. **Use `t.someKey`** for user-facing strings. Hard-coded English tolerated only in admin chrome and internal filter labels.
6. **Avoid `Platform.isIOS` in code that may compile to web.** Use `defaultTargetPlatform` and gate with `!kIsWeb`.
7. **`autoDispose` on family providers** unless the data must outlive a route push. Stateful keep-alive only for: `purchasesNotifierProvider`, `subscriptionNotifierProvider`, `notificationBootstrapProvider`, `observabilityBootstrapProvider`, `cloudflareStreamServiceProvider`.
8. **Material 3 layout traps in admin** — see [§26](#26-admin-portal). Avoid `Form` + `TextFormField` validators, `DropdownButtonFormField`, `ReorderableListView` + `ListTile`, bare `Material` wrappers, and `FilledButton.icon` next to `Expanded` in a Row without an explicit `SizedBox`. They've all caused "Cannot hit test a render box with no size" floods.

### Encouraged

- `const` constructors everywhere they fit.
- Private widgets (`_Foo`) inside the same file as the page; promote to `widgets/` only when reused.
- Snackbar errors via `context.showSnack` (`core/utils/extensions.dart`).
- One responsibility per provider; compose with `ref.watch(otherProvider)`.
- Color hex literals at the top of the widget file, not inline.
- A single `SkeletonShimmer` at the root of a skeleton subtree (one paint pass, not N).
- For analytics events, add to `analytics_events.dart` + a typed `AnalyticsService` helper, never call `analytics.logEvent(...)` directly from a feature file.

### Discouraged

- Direct Firebase calls from UI widgets (use providers).
- `setState` after `await` without `if (!mounted) return;`.
- Importing `package:firebase_*` outside `lib/{features,admin,core}/.../data/` or `lib/core/observability/`.
- Optional-positional args; use named args beyond 2 positional.

---

## 31. Security model

### Firestore rules

Consolidated at `firestore.rules` (~311 lines). Helpers: `isSignedIn()`, `uid()`, `userDoc()`, `role()`, `isSuspended()`, `isAdmin()`, `isInstructor()`.

Read access:

- **Public**: `courses`, `courses/*/sections`, `…/lectures`, `…/reviews`, `…/questions`, `…/questions/{qid}/replies`, `instructors`, `songbooks`, `songbooks/*/reviews`, `learning_paths`, `site_content/{slug}`.
- **Owner only**: `users/{userId}/{notifications,wishlist,notes,courseProgress,…}`.
- **Owner, owning-instructor, or admin**: `enrollments/{id}` (instructor branch uses a `get(courses/{courseId})` cross-reference).
- **Owner or admin**: `users/{userId}`, `instructor_applications/{userId}`.
- **Owning student, owning instructor, or admin**: `transactions/{txnId}` — reads gated by `studentUid == uid || instructorId == uid || isAdmin()`. Writes are server-only (all mutations funnel through `processRefund` callable for audit trail).
- **Owning instructor or admin**: `payouts/{payoutId}` — reads gated by `instructorUid == uid || isAdmin()`. Writes admin-only.
- **Admin only**: `notification_broadcasts`.

Write access:

- **Owner with field constraints**: `users/{userId}` (carve out `role` + `isSuspended` + `subscription`), `instructor_applications/{userId}` (status must be `pending`), `courses/{id}/reviews/{userId}` (`rating ∈ 1..5`), `notification_broadcasts/{id}` (`createdBy == uid`, `status == 'pending'`), `users/{uid}/notifications/{id}` (`readAt`-only updates; creates server-only).
- **Owner-only writes** (no admin override): `users/{uid}/notes`, `users/{uid}/wishlist`, `users/{uid}/courseProgress`.
- **Instructor (owner of resource)**: `courses/{id}` and nested sections + lectures + questions + replies (Q&A replies enforce the `isInstructor: true` carve-out via course `instructorId` cross-ref).
- **Admin**: everything.

### Storage rules

Mirror Firestore — public read of `courses/*`, `songbooks/*`, `learning_paths/*`; writes restricted to admin or owning instructor via `firestore.get` cross-reference.

### Client-side gates (UX, not security)

- `hasUnlockedAccessProvider(courseId)`: gates "Continue course" CTA + "Write a review" CTA.
- `hasActiveSubscriptionProvider`: gates the trial banner on the Songbooks tab.
- `currentRoleProvider` in admin portal: gates nav items.
- `wishlistToggleNotifier` optimistic overlay: heart icon UX.

### Secret material

- API keys / config in `firebase_options_{dev,prod}.dart` — committed; designed to be public per Firebase guidance.
- IAP signing keys, APNs `.p8`, Google Service Account JSON, Cloudflare API token — **never** committed. Cloudflare lives in Firebase Secrets (see [§25](#25-video-pipeline-cloudflare-stream)). The Cloud Functions runtime reads everything else from Application Default Credentials.
- `android/key.properties` and `*.jks` are gitignored — verify with `git check-ignore -v android/key.properties` before any commit.

---

## 32. Pagination, skeletons, refresh

### Pagination (P1-9)

`CoursesPage` uses a cursor-based infinite scroll. The notifier's state tracks `items`, `isLoading`, `isLoadingMore`, `hasMore`, `nextCursor`, plus two separate failure fields (`failure` for initial/refresh, `loadMoreFailure` for page fetches — never blow away the existing list on a page error). The scroll listener fires `loadNextPage()` at 80% scroll, guarded by `(isLoadingMore || !hasMore || nextCursor == null)`.

UI states wired through `CourseGridSkeleton` + `EmptyView` + `ErrorView` + footer skeleton + inline retry banner + end-of-list sentinel. See `docs/pagination.md`.

### Skeletons + pull-to-refresh (P1-10)

Shared primitives in `lib/core/widgets/skeleton.dart`: `SkeletonShimmer` (root), `SkeletonBox`, `SkeletonText`, `SkeletonAvatar`. Used on Home (carousel skeletons + `featuredCoursesProvider` + 3 `popularByInstrumentProvider` family invalidation), Instructors (6 row skeletons), Songbooks (4-cover carousel skeletons + bestsellers + recently viewed invalidation), Reviews section in course detail.

Course detail itself does **not** have a top-level `RefreshIndicator` — a pull gesture inside a video player would surprise more users than it helps. See `docs/skeletons_and_refresh.md`.

---

## 33. Account deletion + legal docs

### Account deletion (P0-2 — Apple §5.1.1(v))

Profile → Settings → Delete account.

```
DeleteAccountPage (re-auth + type-to-confirm)
  ↓
AuthRepository.deleteAccount()  → httpsCallable('deleteAccount')
  ↓
Cloud Function: deleteAccount
  1. users/{uid}
  2. instructor_applications/{uid}
  3. enrollments where userId == uid (and /progress subcoll)
  4. courses/{*}/reviews/{uid}
  5. songbooks/{*}/reviews where userId == uid
  6. users/{uid}/{notes,wishlist,courseProgress,notifications}
  7. Storage objects under users/{uid}/
  8. admin.auth().deleteUser(uid)     ← last so the function still has Firestore creds
```

A non-dismissible reminder tells the user that App Store / Play subscriptions are **not** canceled by account deletion (Apple + Google review requirement). The `collectionGroup('reviews').where('userId', '==', uid)` query needs the composite index already in `firestore.indexes.json`. See `docs/account_deletion_and_legal.md`.

### Legal documents (P0-3)

Bundled markdown under `assets/legal/`:

- `privacy_policy.md`
- `terms_of_service.md`

Rendered by `LegalDocumentPage` via `flutter_markdown`. Route: `/legal/:slug` (registered above the shell so it's reachable from auth pages; unauthenticated redirect carves out `/legal/*`). Entry points: `LegalAgreementFooter` on Login + Signup, Settings → Privacy Policy / Terms of Service.

Bodies are EN-only for v1; titles + agreement-footer copy are localized to VI. To add a third document, drop a new MD, add a `LegalDocument` enum case, add the localized title key.

App Store / Play Console privacy URLs point at the public Hosting URLs (`https://ilearnit.info/legal/privacy`, `/legal/terms`), not the in-app screen.

---

## 34. Go-live roadmap status

Track changes in `docs/go_live_roadmap.md`. Snapshot:

### Shipped (✅)

| Roadmap | Feature | Doc |
|---|---|---|
| Baseline | Auth (email/pw + Google + Apple) | `social_auth_setup.md` |
| Baseline | Course catalogue + detail + lectures | — |
| Baseline | Per-course IAP (PriceTier) | `iap_setup.md` |
| Baseline | Personal Plan subscription (client-trust) | `subscriptions.md` |
| Baseline | Search (in-memory) | — |
| Baseline | Songbooks tab + detail | `songbooks.md` |
| Baseline | Instructors list + detail | — |
| Baseline | Reviews | — |
| Baseline | i18n EN + VI | `localization.md` |
| Baseline | Themes (vibrant/professional/system) | — |
| Baseline | Firestore + Storage rules | `admin_portal.md` |
| Baseline | Admin portal (courses/instructors/songbooks/applications/subscriptions/notifications) | `admin_portal.md` |
| P0-2 | Account deletion | `account_deletion_and_legal.md` |
| P0-3 | Privacy + Terms screens | `account_deletion_and_legal.md` |
| P0-6 | Crashlytics + Performance + Analytics | `observability.md` |
| P0-7/8 | Lecture progress (Continue learning rail) | `lecture_progress.md` |
| P0-7 | Cloudflare Stream video pipeline | `cloudflare_stream.md` |
| P1-1 | Onboarding | `onboarding.md` |
| P1-4 | Notifications inbox + topic prefs | `notifications_inbox.md` |
| P1-8 | Offline downloads | `offline_downloads.md` |
| P1-9 | Courses pagination | `pagination.md` |
| P1-10 | Skeletons + pull-to-refresh | `skeletons_and_refresh.md` |
| P1-12 | App rating prompt | `app_rating_prompt.md` |
| P2-2 | Wishlist + price-drop notifications | `wishlist.md` |
| P2-3 | Course Q&A | `qa.md` |
| P2-4 | Lecture notes | `notes.md` |
| P2-5 | Learning paths | `learning_paths.md` |
| P2-6 | Practice tools (metronome + tuner) | `practice_tools.md` |
| P2-9 | Revenue + cohort dashboard | `analytics.md` |
| Extra | Dynamic landing-page CMS (now 12 sections incl. Become-an-instructor + Featured courses live query) | `site_content_cms.md` |
| Extra | Admin instructor profile CRUD | — |
| Extra | Instructor revenue & student management (Udemy-style) — read-only revenue, refund-via-bookkeeping, payouts table, broadcast | `instructor_revenue.md` |
| Extra | Cloudflare Stream direct-creator-upload (browse video file in admin → auto-fill UID) | `cloudflare_stream.md` |
| Extra | Guest-browse mode — Splash → Onboarding → Login (skippable, with close-X) → Home. Per-user routes gated via `_requiresAuth`. Action-level guest gates on BuyCourse, Bookmark, Reviews, Q&A, Notes. Preview lectures playable for guests | — |
| Extra | "My learning" page — list every course with progress | — |
| Extra | Songbooks moved out of bottom nav (still deep-linkable) | — |
| Push | 3 → 5 → **11** Cloud Functions; inbox mirror; price-drop; Q&A; refund; broadcast; mark-paid; Cloudflare upload | `push_notifications.md` |

### Not yet shipped (key gaps)

- **P0-1** Server-side IAP receipt verification (`verifyPurchase` callable). Highest fraud-risk gap.
- **P0-4** Email-verification gate.
- **P0-5** Forgot-password flow.
- **P0-9** Final app icons / splash / store assets.
- **P0-10** ATT prompt + Apple Privacy Manifest.
- **P1-2** 7-day free trial on subscription SKUs.
- **P1-3** Restore Purchases UX polish.
- **P1-5** Reviews moderation (profanity filter + reports).
- **P1-6** Suspension UI in admin.
- **P1-7** Server-side review aggregator (move off client-side rescan).
- **P1-11** Accessibility pass (contrast, semantics, text scaler).
- **P1-13** Force-update gate via Remote Config.
- **P1-14** Localization completeness sweep.
- **P1-16** Admin auth hardening (MFA, IP allowlist).
- **P2-1** Quizzes + certificates.
- **P2-7** Referrals; **P2-8** coupons; **P2-10** audit log; **P2-11** support entry point; **P2-12** live classes.
- **Ops-1..8** Tests, CI/CD, staging Firebase, backups, error reporting, composite-index doc, CDN, cost monitoring.

---

## 35. References

Per-feature deep-dives:

| Doc | Covers |
|---|---|
| [`admin_portal.md`](admin_portal.md) | Admin portal architecture, Firestore + Storage rules, build/deploy, first-admin bootstrap |
| [`analytics.md`](analytics.md) | Revenue + cohort dashboard data flow, valuation, scaling escape hatch |
| [`cloudflare_stream.md`](cloudflare_stream.md) | Cloudflare Stream integration, token hygiene, signed URLs, direct-creator-upload via `createCloudflareUpload` |
| [`instructor_revenue.md`](instructor_revenue.md) | Udemy-style instructor revenue + student management — `transactions`, `payouts`, `processRefund`, `instructorBroadcast`, `markPayoutPaid` |
| [`account_deletion_and_legal.md`](account_deletion_and_legal.md) | P0-2 + P0-3 — deletion cascade, legal renderer |
| [`app_rating_prompt.md`](app_rating_prompt.md) | P1-12 rating-sheet gating |
| [`iap_setup.md`](iap_setup.md) | Per-course IAP store setup |
| [`learning_paths.md`](learning_paths.md) | Editorial multi-course sequences |
| [`lecture_progress.md`](lecture_progress.md) | Progress tracking, throttling, rollup |
| [`localization.md`](localization.md) | i18n architecture, add a string, add a language |
| [`notes.md`](notes.md) | Per-lecture personal notes + playback position bus |
| [`notifications_inbox.md`](notifications_inbox.md) | Inbox + topic preferences |
| [`observability.md`](observability.md) | Crashlytics + Performance + Analytics wiring |
| [`offline_downloads.md`](offline_downloads.md) | Encrypted manifest + Dio downloader |
| [`onboarding.md`](onboarding.md) | 3-screen first-run flow |
| [`pagination.md`](pagination.md) | Cursor + skeleton + inline retry |
| [`practice_tools.md`](practice_tools.md) | Metronome + pluggable tuner engine |
| [`push_notifications.md`](push_notifications.md) | FCM + local + Cloud Functions + APNs + POST_NOTIFICATIONS |
| [`qa.md`](qa.md) | Course Q&A threads + verified-instructor badge |
| [`signing_and_publishing.md`](signing_and_publishing.md) | Android signing, iOS signing, store submission |
| [`site_content_cms.md`](site_content_cms.md) | Landing-page CMS data model, hydration, admin editor |
| [`skeletons_and_refresh.md`](skeletons_and_refresh.md) | Skeleton primitives + RefreshIndicator wiring |
| [`social_auth_setup.md`](social_auth_setup.md) | Google + Apple Sign-In for iOS, Android, web |
| [`songbooks.md`](songbooks.md) | Songbooks tab + detail + admin CRUD |
| [`subscriptions.md`](subscriptions.md) | Personal Plan IAP setup + schema |
| [`wishlist.md`](wishlist.md) | Bookmarks + price-drop fan-out |
| [`go_live_roadmap.md`](go_live_roadmap.md) | What's missing before store submission |

External references:

- Firebase docs: <https://firebase.google.com/docs>
- go_router: <https://pub.dev/packages/go_router>
- flutter_riverpod: <https://riverpod.dev>
- freezed: <https://pub.dev/packages/freezed>
- in_app_purchase: <https://pub.dev/packages/in_app_purchase>
- Cloudflare Stream API: <https://developers.cloudflare.com/stream/>
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

## 36. UGC Moderation Kit

Added in response to App Store Guideline 1.2 + Google Play UGC policy: every app surfacing user-generated content must collect affirmative consent, expose reporting, allow blocking, and resolve reports within 24 hours.

**Domain — `lib/features/moderation/`**

- `domain/entities/report.dart` — `Report` (freezed). Carries a snapshot of the reported content so moderators can still see what was reported even if the author deletes or edits the original. `domain/entities/report_reason.dart` enumerates the App-Store-aligned reason buckets (spam, harassment, hate speech, sexual content, violence, self-harm, misinformation, IP, other). `report_status.dart` covers `open / actionTaken / dismissed`. `report_content_type.dart` covers `review / question / answer / note` and adds a `.label` for UI strings.
- `data/models/report_model.dart` — Firestore DTO with `fromDoc` + `toEntity`. Enums are stored as their stable `.id` strings (renaming Dart enum cases is a zero-migration change).
- `data/datasources/reports_datasource.dart` — `submit(...)` (idempotent: a reporter re-flagging the same content returns the existing open id without writing a duplicate), `resolve(...)`, `watchOpen()`, `watchOpenForCourses(courseIds)`, `watchOpenCount()` (reads the aggregate counter).
- `data/datasources/blocks_datasource.dart` — `block / unblock / watch` over `users/{uid}/blocks/{blockedUid}`. Doc-per-block (not an array) so the list grows without write-contention.
- `presentation/providers/moderation_providers.dart` — `blockedUserIdsProvider` (stream of `Set<String>`), `openReportsProvider`, `openReportsCountProvider`, `openReportsForCoursesProvider`.
- `presentation/widgets/ugc_overflow_menu.dart` — three-dots menu (Report / Block / Unblock). Self-hides on the viewer's own content; redirects guests to `/login`. Used inline on every UGC tile.
- `presentation/widgets/report_content_sheet.dart` — modal bottom sheet collecting reason + optional notes.
- `presentation/widgets/block_user_dialog.dart` — confirmation dialog.

**Wired into UGC surfaces**

- `course_reviews_section.dart` — `_ReviewTile` carries `UgcOverflowMenu`. The summary average is computed *after* filtering blocked authors out of the list so a blocked spammer's 5-star review doesn't inflate the rating.
- `lecture_qa_section.dart` — `_QuestionRow` carries the menu. Empty-state copy switches once blocking has emptied the list.
- `question_thread_page.dart` — `_QuestionCard` + `_ReplyTile` carry the menu, with content paths to the deep Firestore docs.
- Notes are owner-only (`users/{uid}/notes/{noteId}`) — no reporting/blocking is needed since the viewer only sees their own.

**Block filter semantics** — Retroactive: past AND future content from blocked authors disappears. Blocking is one-way + private: the blocked user is not notified, and the block list is owner-scoped (no admin read).

**Firestore — `reports/{reportId}` + `users/{uid}/blocks/{blockedUid}`**

`reports/` is a top-level global collection (so moderators can stream open reports with one query). Rules in `firestore.rules`:
- Read: `isModerator()` (true for `moderator` or `admin`).
- Create: signed-in user, `reporterId == uid`, `status == 'open'`.
- Update: `isModerator()` only.
- Delete: `isAdmin()` only (audit-trail by default).

`users/{uid}/blocks/{blockedUid}` is owner-only — no admin read.

**Composite indexes** (added to `firestore.indexes.json`):
- `(status ASC, createdAt DESC)` — admin queue.
- `(status ASC, courseId ASC, createdAt DESC)` — moderator scoped queue.
- `(reporterId ASC, contentPath ASC, status ASC)` — the idempotency lookup in `submit()`.

**Cloud Functions** — `onReportCreated` + `onReportResolved` in `functions/src/index.ts` keep `reports/_aggregates.openCount` in sync. The admin side-nav badge reads this doc; without the aggregate the badge would force a full collection scan on every page render.

**Roles — extended `UserRole`**

`student / instructor / moderator / admin`. The new `moderator` is a trust level distinct from admin: can triage UGC reports for the courses they own (or all reports if also an instructor of every course) without portal-level powers. `UserRole.isModerator` is `true` for moderator OR admin. `firestore.rules` has a parallel `isModerator()` helper.

**Moderator surfaces**

- Admin portal: `/admin/reports` (route name `AdminRoutes.reports`) — `AdminReportsPage`. Side-nav entry with live red badge driven by `openReportsCountProvider`. Three actions per card: Hide content (writes `hidden: true` on the original via `contentPath`), Ban author (writes `isSuspended: true` on the author's user doc), Dismiss. All three close the report atomically and stamp `reviewedBy / reviewedAt / resolutionNotes`.
- In-app: `/moderator` (top-level above the shell, gated by `_requiresAuth` AND a per-page `isModerator` check) — `ModeratorReportsPage`. Admins get the unscoped queue; non-admin moderators get reports scoped to their owned courses via `coursesByInstructor` → `openReportsForCoursesProvider(courseIds)`.

**EULA / Community Guidelines**

- `features/moderation/eula/eula_version.dart` — `kCurrentEulaVersion` (int) + `kCurrentEulaPublishedLabel`. Bump the int when the policy materially changes.
- `features/moderation/eula/eula_acceptance_service.dart` — writes `eulaAcceptedVersion` + `eulaAcceptedAt` to `users/{uid}`.
- `UserModel` + `UserEntity` carry `eulaAcceptedVersion: int` (default 0 = legacy/unaccepted).
- `SignupPage` — required checkbox ("I agree to the Terms and Community Guidelines…") gates the Create-account button. On submit, `auth_remote_datasource.signup()` stamps `eulaAcceptedVersion: kCurrentEulaVersion` into the new user doc.
- `EulaReacceptanceGate` — wraps `ShellScaffold`. When the signed-in user's stored version is older than `kCurrentEulaVersion`, shows a non-dismissible bottom sheet that links to Terms + Community Guidelines and accepts the bump. One prompt per app session per user.
- Community Guidelines doc — `assets/legal/community.md`, surfaced as `LegalDocument.communityGuidelines` at `/legal/community`.

**Deploy checklist**

1. Run `dart run build_runner build --delete-conflicting-outputs` to generate `report_model.g.dart`, `report.freezed.dart`, and the regenerated `user_model.g.dart` / `user_entity.freezed.dart` for the new EULA field.
2. `firebase deploy --only firestore:rules,firestore:indexes` — rules add `isModerator()` + `reports/` block + `users/{uid}/blocks/` block; indexes add the three reports indexes.
3. `firebase deploy --only functions:onReportCreated,functions:onReportResolved` — backed counter for the admin badge.
4. To promote a user to moderator, set their `users/{uid}.role = 'moderator'` via the admin SDK or Firestore console — no admin UI is exposed today (intentional: the bar for moderator promotion is high enough that ad-hoc Firestore writes are appropriate).

---

## 37. Instructor schema refactor (2026-06)

The instructor data model was simplified to a single schema invariant: **`instructors/{id}.id` equals the Firebase Auth UID**. The `instructors/{uid}` doc is the public-facing complement to `users/{uid}` (private auth + role). The two collections are joined by the shared key — no bridge field, no fallback query.

This replaces the earlier setup that used auto-generated Firestore IDs for `instructors/` and a nullable `userId` field as a soft bridge. That setup caused recurring "Instructor not found" bugs because `course.instructorId` (set during course creation to the auth UID) never matched the auto-generated profile IDs, and the `userId` bridge was easy to forget.

**The shape now.**

```
users/{uid}            ← auth + role + private fields
instructors/{uid}      ← public profile (doc id IS the auth UID)
courses/{cid}.instructorId == uid    ← direct point read against instructors/{uid}
```

**Promote-a-user flow.**

There are three entry points that all converge on the same destination — `instructors/{uid}` with `.set(payload, {merge: true})`:

1. **Cloud Function `onUserRoleChanged`** (in `functions/src/index.ts`). Fires when `users/{uid}.role` transitions to `'instructor'`. Materializes (or refreshes) `instructors/{uid}` seeded from the user's `displayName` / `email` / `photoUrl`. Idempotent. This is the long-term auto-creation path — admins shouldn't need to remember to click anything.

2. **Per-row "Create profile" button** on the admin Instructors page (`AdminInstructorsPage`). Calls `AdminInstructorProfilesDataSource.createFromUser(uid, …)` then deep-links into the profile editor so the admin can immediately fill bio / tagline / socials. Used when the function trigger is suppressed (e.g. dev seeds, manual Firestore edits, or the Cloud Function hasn't been deployed yet).

3. **Bulk "Sync all profiles" button** on the same page. Walks every user with `role == 'instructor'` and calls `createFromUser` for each. The recovery action for existing data — one click brings every instructor in line with the schema invariant.

**Legacy auto-id migration.**

Pre-refactor instructor docs use auto-generated Firestore IDs. The admin Instructor Profiles page surfaces a **"Migrate legacy profiles"** button that runs `AdminInstructorProfilesDataSource.migrateLegacyProfiles()`. For each doc whose id isn't already a canonical uid:

  1. Use the legacy `userId` field if set.
  2. Otherwise email-match against the `users` collection (case-insensitive fallback).
  3. Otherwise strict displayName match.

Resolved docs are copied to `instructors/{uid}` and the original deleted. The result dialog reports `Created` / `Already linked` / `Ambiguous` / `No match` / `Errored` so anything stuck is visible.

**Consumer side — direct lookup.**

`InstructorsDataSource.watchById(id)` is a single point read against `instructors/{id}`. No fallback query, no bridge field traversal. `instructorByIdProvider(id)` watches that stream. Mobile course-detail "Taught by …" pushes `/instructors/<course.instructorId>` which lands on `InstructorDetailPage`, which reads `instructors/{course.instructorId}` directly.

**Admin editor — `userId` field removed.**

The instructor profile editor (`InstructorProfileEditorPage`) no longer shows an "Auth user ID" text input. The doc id is rendered as a read-only `_UidBadge` (key icon + monospace selectable text) so the admin can confirm + copy it without being able to edit (because editing it would mean "this profile now belongs to a different user," which is best modeled as Delete + Create).

**`InstructorModel` shape.**

```
required String id;       // == Firebase Auth UID
String? email;            // public-facing contact (mirrors users/{uid}.email on create)
String name;
String photoUrl;
String bio;
String? tagline;
String? primaryInstrument;
List<String> specialties;
int? yearsExperience;
String? country;
double rating;
int reviewCount;
int studentCount;
DateTime? joinedAt;
List<String> featuredCourseIds;
String? websiteUrl;
String? facebookUrl;
String? twitterUrl;
String? youtubeUrl;
String? instagramUrl;
```

Field `userId` is removed.

**Sample data alignment.**

`sample_data/instructors.json` doc keys (`ins_001` … `ins_010`) double as the synthetic uids. A parallel `sample_data/users.json` was added containing one user doc per instructor (`role: 'instructor'`, displayName + email mirroring `instructors.json`). The seed script (`seed_firestore.js`) reads both and writes them under matching keys — so after a clean seed:

  * Admin portal `/admin/instructors` lists all 10 instructor users.
  * Admin portal `/admin/instructor-profiles` lists the same 10 profiles.
  * Mobile `/instructors` shows the 10 public profiles.
  * Mobile course detail "Taught by Antonio Vela" taps through to `instructors/ins_001` and resolves cleanly.

`courses.json` already uses `instructorId: 'ins_XXX'` matching the keys — no changes needed.

**Deploy checklist.**

1. `dart run build_runner build --delete-conflicting-outputs` — regenerates freezed/json for the dropped `userId` field.
2. `firebase deploy --only functions:onUserRoleChanged` — picks up the simpler `.set(merge: true)` implementation.
3. Admin portal: **Instructor profiles → Migrate legacy profiles → Migrate** (only needed once in environments that had pre-refactor data).
4. Admin portal: **Instructors → Sync all profiles → Sync** (catches any instructor user that the Cloud Function trigger hasn't fired for yet).
5. Optional dev refresh: `cd sample_data && node seed_firestore.js --flavor dev --wipe` to regenerate the demo dataset against the new schema.

---

**Last verified:** 2026-06-14. This spec was refreshed against `pubspec.yaml`, `firebase.json` (two-target hosting: landing + admin), `functions/src/index.ts` (14 functions incl. onReportCreated + onReportResolved + onUserRoleChanged), `firestore.rules` (incl. transactions + payouts + reports + blocks), `shell_scaffold.dart` (4-item bottom nav, wrapped in EulaReacceptanceGate), `app_router.dart` (four-branch redirect with guest-browse mode + `_requiresAuth` allow-list incl. `/moderator`), the instructor schema invariant (`instructors/{uid}` mirrors `users/{uid}`), and every doc under `docs/`. When in doubt, the code is newer than the spec — run `git log -- docs/technical_specification.md` to see when this was last touched, and `git log --since="<that date>" -- lib/ functions/` to see what's drifted.
