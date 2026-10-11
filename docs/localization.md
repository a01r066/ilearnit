# Localization (i18n) — English & Vietnamese

iLearnIt supports two languages out of the box: **English (`en`)** and **Tiếng Việt (`vi`)**.
The user can switch language at runtime from **Settings → Language**; the choice is persisted in `SharedPreferences` and survives app restarts.

## Architecture

```
l10n.yaml                                  ← codegen config
lib/l10n/
├── app_en.arb                             ← English source of truth
├── app_vi.arb                             ← Vietnamese translations
├── l10n.dart                              ← context.l10n + L10n.current helpers
└── generated/                             ← AUTO-GENERATED (committed)
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
5. `MaterialApp.builder` (mobile `app.dart` and admin `admin_app.dart`) calls `L10n.update(AppLocalizations.of(context))`, which also sets `Intl.defaultLocale` so `DateFormat` / `NumberFormat` without an explicit locale follow the app language.
6. iOS `Info.plist` declares `CFBundleLocalizations` = `en`, `vi`. Without it iOS treats the app as English-only (system dialogs, share sheet, StoreKit stay English and the device locale `vi` never reaches Flutter).

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
import '../../../../l10n/l10n.dart';   // exports AppLocalizations + helpers

@override
Widget build(BuildContext context) {
  final t = context.l10n;              // == AppLocalizations.of(context)
  return Text(t.homeBrowseByInstrument);
}
```

Older files use `AppLocalizations.of(context)` directly — equivalent.
Remember to drop `const` from any widget subtree that now contains a
localized string.

## Using a string without a BuildContext

Error mapping, validators, data-layer messages and enum labels use
`L10n.current` (defaults to English before the first frame):

```dart
throw ServerException(message: L10n.current.errLoadFailed);

enum CourseLevel { …
  String get label => switch (this) {
        CourseLevel.beginner => L10n.current.levelBeginner, … };
}
```

Localized enums keep their stable English text as `englishLabel`
(`InstrumentCategory`, `CourseLevel`, `LectureType`, `ReportReason`).
Never persist `label` — persist `id`.

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

## Coverage

All user-facing strings in the **mobile app** come from the ARBs
(~515 keys), including errors surfaced from the data layer, validators,
enum labels, accessibility tooltips and the Android notification channel.

> The theme picker uses keys `settingsThemeSystem`, `settingsThemeVibrant`, and `settingsThemeProfessional` (the old `settingsThemeLight` / `settingsThemeDark` keys were removed when the theme system was refactored to `{system, vibrant, professional}`).

Not localized (by design or pending):

- **Admin web portal** (`lib/admin/**`) — English only.
- **Legal documents** — Vietnamese drafts exist (`assets/legal/*_vi.md`,
  each marked as a reference translation where English prevails).
  `LegalDocumentPage` loads `<name>_<lang>.md` for the app language and
  falls back to English. Have them reviewed by a lawyer before release.
- **Search suggestions** (`search_remote_datasource.dart`) — English on
  purpose: they must match English course titles.
- Server error messages from Cloud Functions are mapped to localized
  client messages by error code (purchases, subscriptions); raw server
  text is not shown.

The Vietnamese strings added in the localization pass are draft
translations — have a native speaker review `app_vi.arb`.

When adding UI, the recipe is:
1. Add a key to `app_en.arb` (placeholders need an `@key` block) and the
   translation to `app_vi.arb`.
2. `flutter gen-l10n`.
3. Use `context.l10n.yourKey` (or `L10n.current.yourKey` outside widgets).

## Gotchas

- **Don't import from `package:flutter_gen/...`.** This project uses `synthetic-package: false` (set in `l10n.yaml`), so the generated code lives in your own `lib/` tree. Import from `package:ilearnit/l10n/generated/app_localizations.dart`.
- **`AppLocalizations.of(context)` returns non-null** because `nullable-getter: false` is set in `l10n.yaml`. No `!` needed.
- **Vietnamese uses no spaces before `:` and `?`** — Vietnamese typography. The current ARB respects this; keep it that way when editing.
- **Plurals**: a few keys use ICU plurals (`wishlistSubtitleCount`, `learningPathCourseCount`, `qaReplyCount`, `notesMoreInProfile`). Newer keys pass counts as `String` placeholders and pick singular/plural keys in code (e.g. `reviewsCountOne` / `reviewsCountMany`); prefer ICU plurals for new strings.
- **Generated files are committed.** Always run `flutter gen-l10n` after editing ARBs so `lib/l10n/generated/` matches.
