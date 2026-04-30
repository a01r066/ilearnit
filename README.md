# iLearnIt

Online classical music lessons, courses, and instructors — Guitars, Piano, Violin.
Inspired by Tonebase.

## Stack

- **State**: `flutter_riverpod` (StateNotifier + State in separated files) + `freezed`
- **Backend**: Firebase (Firestore / Auth / Storage) — separate **DEV** and **PROD** projects
- **Networking**: `dio` + `pretty_dio_logger` + `AuthInterceptor`
- **Storage**: `flutter_secure_storage` (tokens) + `shared_preferences`
- **Routing**: `go_router` with `ShellRoute` + bottom nav
- **Connectivity**: `connectivity_plus`
- **Charts**: `fl_chart`
- **Flavors**: `flutter_flavorizr` (dev / prod)
- **Errors**: `dartz` `Either<Failure, T>` + `Failure` sealed class (freezed)

**Package names**

| Flavor | Application ID            |
| ------ | ------------------------- |
| dev    | `info.ilearnit.app.dev`   |
| prod   | `info.ilearnit.app`       |

## Project layout

```
lib/
├── main.dart                       # Default entry (delegates to dev)
├── main_dev.dart                   # Dev flavor entry
├── main_prod.dart                  # Prod flavor entry
├── app/
│   ├── app.dart                    # Root MaterialApp.router
│   └── flavor_config.dart          # Flavor enum + runtime config
├── core/
│   ├── constants/                  # App-wide constants
│   ├── error/                      # Failure (freezed) + Exceptions
│   ├── network/                    # DioClient + AuthInterceptor + NetworkInfo
│   ├── routing/                    # go_router + ShellRoute scaffold
│   ├── storage/                    # SecureStorage + Prefs services
│   ├── theme/                      # Colors / typography / theme
│   ├── utils/                      # Extensions + validators
│   └── widgets/                    # Shared atoms (loading, error views)
├── features/
│   ├── auth/                       # data / domain / presentation
│   ├── courses/
│   ├── home/
│   ├── instructors/
│   └── profile/
└── shared/
    └── providers/                  # Riverpod providers (firebase, dio, etc.)
```

Each feature follows clean architecture:

```
feature/
├── data/
│   ├── datasources/                # Remote + local
│   ├── models/                     # JSON-serializable DTOs
│   └── repositories/               # Repository implementations
├── domain/
│   ├── entities/                   # Pure Dart entities
│   ├── repositories/               # Repository contracts
│   └── usecases/                   # Optional use cases
└── presentation/
    ├── providers/                  # state + notifier in separate files
    ├── pages/                      # Screens
    └── widgets/                    # Feature-specific widgets
```

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

# 5. Codegen for freezed / json / riverpod
dart run build_runner build --delete-conflicting-outputs
```

## Run

```bash
flutter run --flavor dev  -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
```

## Codegen workflow

```bash
# One-shot
dart run build_runner build --delete-conflicting-outputs

# Watch
dart run build_runner watch --delete-conflicting-outputs
```
