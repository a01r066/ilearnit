# Localization (i18n) — English & Vietnamese

iLearnIt supports two languages out of the box: **English (`en`)** and **Tiếng Việt (`vi`)**.
The user can switch language at runtime from **Settings → Language**; the choice is persisted in `SharedPreferences` and survives app restarts.

## Architecture

```
l10n.yaml                                  ← codegen config
lib/l10n/
├── app_en.arb                             ← English source of truth
├── app_vi.arb                             ← Vietnamese translations
└── generated/                             ← AUTO-GENERATED, gitignore-able
    ├── app_localizations.dart
    ├── app_localizations_en.dart
    └── app_localizations_vi.dart

lib/features/profile/presentation/providers/
├── locale_state.dart                      ← freezed LocaleState + AppLanguage enum
├── locale_notifier.dart                   ← StateNotifier, persists to PrefsService
└── locale_provider.dart                   ← Riverpod StateNotifierProvider
```

The pattern mirrors `theme_state.dart` / `theme_notifier.dart` / `theme_provider.dart` so the two settings work the same way.

## How it's wired

1. `pubspec.yaml` has `generate: true` under `flutter:` — this turns on `flutter gen-l10n`.
2. `l10n.yaml` points at `lib/l10n/*.arb` and emits Dart code into `lib/l10n/generated/`.
3. `lib/app/app.dart` adds three things to `MaterialApp.router`:
   - `locale: localeState.language.locale` (driven by the notifier)
   - `localizationsDelegates: AppLocalizations.localizationsDelegates`
   - `supportedLocales: AppLocalizations.supportedLocales`
4. `PrefsService` already exposes `locale` get/set backed by `SharedPreferences`, so no changes were needed in storage.

## Generating the Dart code

Run **once after pulling** and **any time you edit an `.arb` file**:

```bash
flutter pub get          # auto-runs gen-l10n when generate: true
# or, explicitly:
flutter gen-l10n
```

Output lands in `lib/l10n/generated/`. You can add `lib/l10n/generated/` to `.gitignore` if you prefer not to commit generated code — the build step regenerates it from the ARBs.

## Using a string in a widget

```dart
import 'package:ilearnit/l10n/generated/app_localizations.dart';

@override
Widget build(BuildContext context) {
  final t = AppLocalizations.of(context);
  return Text(t.homeBrowseByInstrument);
}
```

Strings with placeholders are typed methods:

```dart
Text(t.homeWelcomeNamed('Thanh'));        // "Hello, Thanh 👋"
Text(t.purchaseBuyForPrice('\$9.99'));    // "Buy for $9.99"
```

## Adding a new string

1. Add the key + English value to `lib/l10n/app_en.arb`. If the string takes a placeholder, also add the `@key` metadata block with `placeholders` so the generator emits a typed method.
2. Add the Vietnamese translation under the same key in `lib/l10n/app_vi.arb`.
3. Run `flutter gen-l10n` (or just `flutter pub get`).
4. Use `t.yourNewKey` in your widget.

> Keep both ARBs in lockstep — `flutter gen-l10n` warns about missing translations, and untranslated keys fall back to the template (English).

## Adding a new language

1. Create `lib/l10n/app_<code>.arb` with the same keys (e.g. `app_ja.arb` for Japanese).
2. Add a new value to the `AppLanguage` enum in `locale_state.dart`:
   ```dart
   ja(Locale('ja')),
   ```
3. Add a label key to `app_en.arb` / every other ARB (e.g. `"languageJapanese": "日本語"`).
4. Map it in `_languageLabel` inside `settings_page.dart`.
5. `flutter gen-l10n` — done. The settings picker will show the new entry automatically because it iterates `AppLanguage.values`.

## Where strings still need translating

The current ARB covers the high-traffic surfaces: navigation, Home, Settings, Auth labels, common actions, purchases, and lecture lock messages. The following pages still contain hardcoded English `Text(...)` and should be migrated:

- `features/courses/presentation/pages/courses_page.dart`
- `features/courses/presentation/pages/course_detail_page.dart`
- `features/courses/presentation/pages/lecture_player_page.dart`
- `features/instructors/presentation/pages/instructors_page.dart`
- `features/instructors/presentation/pages/instructor_detail_page.dart`
- `features/auth/presentation/pages/login_page.dart`
- `features/auth/presentation/pages/signup_page.dart`
- `features/auth/presentation/pages/splash_page.dart`
- `core/widgets/error_view.dart`, `empty_view.dart`

Migration recipe per file:
1. Find every literal `'...'` inside `Text(...)`, `SnackBar`, `AppBar(title: ...)`, dialog titles, hint text, button labels, etc.
2. Add a key to `app_en.arb` (and the matching translation to `app_vi.arb`).
3. `final t = AppLocalizations.of(context);` at the top of the build method.
4. Replace the literal with `t.yourKey`.

## Gotchas

- **Don't import from `package:flutter_gen/...`.** This project uses `synthetic-package: false` (set in `l10n.yaml`), so the generated code lives in your own `lib/` tree. Import from `package:ilearnit/l10n/generated/app_localizations.dart`.
- **`AppLocalizations.of(context)` returns non-null** because `nullable-getter: false` is set in `l10n.yaml`. No `!` needed.
- **Vietnamese uses no spaces before `:` and `?`** — Vietnamese typography. The current ARB respects this; keep it that way when editing.
- **Plurals** (e.g. "1 course" / "5 courses") aren't used yet — when you need them, use ICU `{count, plural, =0{...} one{...} other{...}}` syntax in the ARB and the generator handles it.
