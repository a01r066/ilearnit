---
name: flutter-l10n-a11y
description: Localization (gen-l10n ARB workflow, multiple languages, plurals, dates, enum labels, localized error messages, translated legal documents) and accessibility (screen-reader labels, tooltips, Semantics, text scaling, tap targets) for Flutter apps. Use this skill whenever the user adds a language, adds or edits user-visible strings, asks to translate the app, sees untranslated text or English errors in another language, writes widgets with icon buttons / gesture detectors / images, or prepares for store review or an accessibility audit — even if they only say "add Vietnamese" or "make this button work with VoiceOver".
---

# Flutter localization and accessibility

Both are cheap if done while writing a widget and expensive to retrofit.
The rules below keep every string translatable (including ones produced
outside widgets) and every control reachable by screen readers.

## 1. Setup (once)

- `pubspec.yaml`: `flutter_localizations: {sdk: flutter}`, `intl`,
  `flutter: generate: true`.
- `l10n.yaml` from `templates/l10n.yaml`: output into
  `lib/l10n/generated/` with `synthetic-package: false`, and **commit the
  generated files** (CI and teammates build without regenerating; string
  changes show in diffs).
- `templates/lib/l10n/l10n.dart`: `context.l10n` shorthand and
  `L10n.current` for code without a `BuildContext`.
- In `MaterialApp.builder`: `L10n.update(AppLocalizations.of(context))`
  — keeps `L10n.current` and `Intl.defaultLocale` (DateFormat,
  NumberFormat) on the app's language. See
  `templates/lib/app_builder_snippet.dart`.
- Optional in-app language picker: store the choice in prefs, feed
  `MaterialApp.locale` (null = follow device).
- iOS `Info.plist` `CFBundleLocalizations` must list every language.

## 2. Writing strings

- Every user-visible string goes in `app_en.arb` (template) and every
  other `app_<lang>.arb`. Run `flutter gen-l10n` after editing.
- Key naming: `<feature><Thing>` (`checkoutPayButton`, `errNoInternet`);
  shared verbs as `action*`. Add `@key` descriptions for anything
  ambiguous — translators see only the string.
- Placeholders: `{count}` with types; plurals with ICU
  (`{count, plural, =0{…} =1{…} other{…}}`); dates with
  `"type": "DateTime", "format": "yMMMd"`. Never concatenate translated
  fragments — word order differs between languages.
- Prices: use the store's formatted `ProductDetails.price` as a String
  placeholder; never format currency yourself.
- Languages without plural forms (e.g. Vietnamese, Japanese) may write
  a plain string for an ICU plural key; that's valid.
- Strings outside widgets — error mappers, validators, repository
  messages, enum labels, notifications built on device — use
  `L10n.current.key`. A Failure created in English stays English.
- Enums keep three faces: `wire` (storage), `englishLabel` (logs/admin
  exports), `label` (UI via `L10n.current`).
- Server-generated text (push titles, emails) is localized on the
  server using a `locale` field saved on the user doc.

## 3. Legal and long-form content

Markdown assets per language with English fallback:
`assets/legal/privacy_policy.md` + `privacy_policy_<lang>.md`. Loader in
`templates/lib/app_builder_snippet.dart` (`loadLocalizedAsset`). Put a
note at the top of translations that the English version prevails, and
have translations reviewed by a native speaker / lawyer before release.

## 4. Verify

```bash
python3 -I <skill-dir>/scripts/arb_check.py <app-root> [--exclude lib/admin]
```

Reports missing/extra keys per locale, placeholder mismatches, ICU
messages without `other`, untranslated-looking values, unused keys, and
likely hard-coded UI strings (`Text('…')`, `tooltip: '…'`, `label: '…'`).
Exclude internal tools (admin portals) that are intentionally
English-only. Then run the app in each language and check truncation —
Vietnamese and German run ~30% longer than English.

## 5. Accessibility rules

- **Icon-only buttons** need `tooltip:` (it doubles as the screen-reader
  label). Exception: widgets above the Navigator (`MaterialApp.builder`)
  have no Overlay — use `Semantics(label:, button: true)` instead.
- **Custom tappables** (`GestureDetector`, `InkWell` around an icon or
  image) → wrap in `Semantics(button: true, label: …)` (or `link: true`
  for navigation to external pages). If the child has visible text,
  `MergeSemantics` is enough.
- **Images**: content images get `semanticLabel`; decorative ones
  `excludeFromSemantics: true`. Thumbnails next to a title are decorative.
- **Composite values** (star ratings, progress) → one `Semantics(label:
  l10n.a11yRatingStars(4.5))` with children excluded; interactive star
  pickers label each star ("Rate 3 of 5") and expose `selected`.
- **Text scaling**: don't disable it; test at 200%. Use `Flexible`,
  `maxLines` + `overflow`, and avoid fixed heights around text.
- **Tap targets** ≥ 48×48 dp (`IconButton` already is; custom ones use
  `ConstrainedBox(minWidth/minHeight: 48)`).
- **Contrast** ≥ 4.5:1 for body text; don't convey state by colour alone
  (add an icon or text).
- **Order and grouping**: `MergeSemantics` for list rows, `ExcludeSemantics`
  for duplicated info, `Semantics(header: true)` for section titles.
- Localize every semantic label — they are user-visible strings.

```bash
python3 -I <skill-dir>/scripts/a11y_scan.py <app-root>
```

Flags icon buttons without tooltips, unlabeled tappables, unlabeled
images, disabled text scaling and tooltips above the Navigator. Then do
a manual pass with TalkBack and VoiceOver on the main flows (sign-in,
browse, purchase, playback, settings).

## 6. Adding a new language — checklist

- [ ] `app_<lang>.arb` with all keys (`arb_check.py` shows 0 missing).
- [ ] `flutter gen-l10n`; generated files committed.
- [ ] `CFBundleLocalizations` updated; store listing translated.
- [ ] Legal docs `<name>_<lang>.md` (reviewed) or explicit English fallback.
- [ ] Language picker option + `Intl` date/number output checked.
- [ ] Server-sent notifications/emails localized or deliberately English.
- [ ] Screens checked for overflow at large text sizes in the new language.
