# iLearnIt

Online classical music lessons, courses, and instructors — Guitars, Piano, Violin.
Inspired by Tonebase.

## Stack

- **Apps**: Flutter mobile app (iOS / Android) + Flutter **web admin portal** (`lib/main_admin.dart`)
- **State**: `flutter_riverpod` (StateNotifier + State in separate files) + `freezed`
- **Backend**: Firebase (Auth / Firestore / Storage / Functions / FCM / Hosting / Crashlytics / Analytics) — separate **DEV** (`ilearnit-dev`) and **PROD** (`ilearnit-31f41`) projects
- **Server code**: Cloud Functions v2, TypeScript (`functions/`)
- **Video**: Cloudflare Stream (signed HLS URLs)
- **Payments**: `in_app_purchase` — consumable course tiers + Personal Plan subscription, verified server-side (App Store Server API / Play Developer API)
- **Routing**: `go_router` with `StatefulShellRoute` + bottom nav
- **Localization**: `flutter gen-l10n` — English + Vietnamese (`lib/l10n/*.arb`)
- **Flavors**: `flutter_flavorizr` (dev / prod)
- **Errors**: `dartz` `Either<Failure, T>` + `Failure` sealed class (freezed)

**Package names**

| Flavor | Application / bundle ID   | Firebase project |
| ------ | ------------------------- | ---------------- |
| dev    | `info.ilearnit.app.dev`   | `ilearnit-dev`   |
| prod   | `info.ilearnit.app`       | `ilearnit-31f41` |

## Project layout

```
lib/
├── main.dart                       # Mobile entry — flavor from --flavor (appFlavor)
├── bootstrap.dart                  # Firebase init (default app from flavor options),
│                                   #   observability, IAP + notification + session wiring
├── main_admin.dart / bootstrap_admin.dart   # Web admin portal entry
├── flavors.dart                    # F.appFlavor + per-flavor URLs / ids
├── firebase_options_{dev,prod}.dart  # flutterfire output (gitignored)
├── app/
│   ├── app.dart                    # MaterialApp.router (+ L10n sync in builder)
│   └── session_cleanup.dart        # Wipes per-user local state on sign-out
├── admin/                          # Admin / instructor web portal (feature folders)
├── core/
│   ├── constants/ error/ network/ theme/ typedefs/ utils/ widgets/
│   ├── notifications/              # FCM + local notifications + inbox
│   ├── observability/              # Crashlytics / Analytics / Performance
│   ├── routing/                    # go_router + shell scaffold
│   ├── security/                   # App Check activation
│   ├── session/                    # BeforeSignOutHooks
│   ├── update/                     # Remote Config force-update gate
│   └── storage/                    # Prefs, secure storage, OfflineStorage
├── features/                       # app_rating, auth, courses, downloads, home,
│                                   # instructors, learning_paths, legal, mini_player,
│                                   # moderation, notes, onboarding, practice, profile,
│                                   # progress, purchases, qa, search, songbooks,
│                                   # subscriptions, wishlist
├── l10n/                           # app_en.arb, app_vi.arb, l10n.dart, generated/
└── shared/providers/               # firebase, dio, storage, connectivity

functions/src/
├── index.ts                        # Triggers + callables (notifications, Cloudflare,
│                                   #   moderation, refunds, reviews aggregate, …)
├── iap.ts                          # Purchase intents, verifyPurchase, verifySubscription,
│                                   #   verifySongbookPurchase, entitlement helpers
├── media.ts                        # Signed URLs for paid Storage files + songbook PDFs
├── appCheck.ts                     # requireAppCheck (ENFORCE_APP_CHECK param)
├── storeNotifications.ts           # App Store Server Notifications v2 + Play RTDN
└── store/{apple,google}.ts         # Store API clients

firestore.rules · storage.rules · firestore.indexes.json · docs/
```

Each feature follows a data / domain / presentation split:

```
feature/
├── data/          datasources/ · models/ (DTOs) · repositories/
├── domain/        entities/ · repositories/ (contracts)
└── presentation/  providers/ (state + notifier, separate files) · pages/ · widgets/
```

## Security model (summary)

Clients never grant themselves anything. Course ownership
(`users/{uid}/purchases/*`), enrollments, transactions, subscriptions and
roles are written only by Cloud Functions (Admin SDK) after server-side
checks; `firestore.rules` deny those client writes. Paid video and files
are served through short-lived signed URLs minted after an entitlement
check. Details: [`docs/security_model.md`](docs/security_model.md).

## Documentation

| Topic | Doc |
|---|---|
| Security model / entitlements | [`docs/security_model.md`](docs/security_model.md) |
| Go-live runbook (Firebase, stores, rollout order) | [`docs/production_migration.md`](docs/production_migration.md) |
| In-app purchases + server verification | [`docs/iap_setup.md`](docs/iap_setup.md), [`docs/subscriptions.md`](docs/subscriptions.md) |
| Video | [`docs/cloudflare_stream.md`](docs/cloudflare_stream.md) |
| Offline downloads + paid Storage files | [`docs/offline_downloads.md`](docs/offline_downloads.md) |
| Push notifications | [`docs/push_notifications.md`](docs/push_notifications.md) |
| Sign-in (Google / Apple), per-flavor iOS config | [`docs/social_auth_setup.md`](docs/social_auth_setup.md) |
| Localization | [`docs/localization.md`](docs/localization.md) |
| Signing & publishing | [`docs/signing_and_publishing.md`](docs/signing_and_publishing.md) |
| Full spec | [`docs/technical_specification.md`](docs/technical_specification.md) |

## First-time setup

```bash
# 1. Create native platform folders (this scaffold has only lib/ + config)
flutter create . --org info.ilearnit.app --project-name ilearnit \
  --platforms=ios,android

# 2. Install deps
flutter pub get

# 3. Set up flavors (creates Android product flavors + iOS schemes)
flutter pub run flutter_flavorizr

# 4. Configure Firebase for both flavors (run twice)
dart pub global activate flutterfire_cli
flutterfire configure \
  --project=ilearnit-dev \
  --out=lib/firebase_options_dev.dart \
  --ios-bundle-id=info.ilearnit.app.dev \
  --android-package-name=info.ilearnit.app.dev

flutterfire configure \
  --project=ilearnit-prod \
  --out=lib/firebase_options_prod.dart \
  --ios-bundle-id=info.ilearnit.app \
  --android-package-name=info.ilearnit.app

# 5. Codegen for freezed / json / riverpod + localizations
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# 6. Cloud Functions
cd functions && npm install && npm run build && cd ..
```

iOS bundles **no** `GoogleService-Info.plist` — keep any file that
`flutterfire configure` writes there out of the Runner target (see
`docs/social_auth_setup.md` §3).

## Run

```bash
flutter run --flavor dev
flutter run --flavor prod
```

## Codegen workflow

```bash
# One-shot
dart run build_runner build --delete-conflicting-outputs

# Watch
dart run build_runner watch --delete-conflicting-outputs
```
***Build prod flavor***

```
flutter build ios --flavor prod -t lib/main.dart (or add --no-tree-shake-icons if error)
flutter build apk --flavor prod -t lib/main.dart (or add --no-tree-shake-icons if error) (.apk)
flutter build appbundle --flavor prod -t lib/main.dart
```

# Acknowledgements

Inspired by ***Tonebase***'s ideas.