---
name: flutter-store-release-readiness
description: Get a Flutter + Firebase app through App Store and Google Play review and safe for production — iOS privacy manifest, entitlements, Info.plist usage strings, Sign in with Apple, Android permission stripping, Data safety, backup exclusion for offline files, FCM notification icon and permission timing, Firebase App Check, Remote Config force-update gate, account deletion, hiding unfinished features (Guideline 2.1), versioning and signing. Use this skill whenever the user is preparing a release, submitting to TestFlight / App Store / Play, got a rejection email, asks "is my app ready to publish", adds a permission or native capability, or sets up push notifications, App Check or forced updates — even if they don't mention review.
---

# Flutter store release readiness

Most rejections are predictable. Run the scanner first, then work through
the sections it flags:

```bash
python3 -I <skill-dir>/scripts/release_check.py <flutter-app-root>
```

It prints FAIL/WARN/OK for ~30 checks (manifest, entitlements, usage
strings, permissions, notification icon, account deletion, restore,
server verification, App Check, force update, placeholder UI). It is a
heuristic — confirm each finding in code. The complete list with
guideline numbers is in `references/review_checklist.md`.

## 1. iOS

- **Privacy manifest** `ios/Runner/PrivacyInfo.xcprivacy`, added to the
  Runner target's Copy Bundle Resources. Declare what *your* app
  collects (account email/name, user id, purchases, UGC, analytics,
  crash data) and required-reason APIs your code uses (UserDefaults →
  `CA92.1`, file timestamps → `C617.1`). SDKs ship their own. Keep it
  consistent with the App Privacy questionnaire and your privacy policy —
  mismatches are a common rejection. Template: `templates/ios/PrivacyInfo.xcprivacy`.
- **Entitlements** `Runner.entitlements` with `CODE_SIGN_ENTITLEMENTS`
  set in **every** Runner build configuration (each flavor × Debug /
  Profile / Release) and matching capabilities on every App ID:
  push (`aps-environment`), Sign in with Apple, App Attest.
- **Sign in with Apple** is mandatory when you offer Google/Facebook
  login (4.8).
- **Usage strings** for every permission a plugin can trigger
  (`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, …),
  written as a concrete reason ("to record your practice and compare it
  to the lesson"), localized.
- `CFBundleLocalizations` lists every app language, or iOS shows system
  UI and the store listing in English only.
- `ITSAppUsesNonExemptEncryption = false` if you only use HTTPS.
- `UIBackgroundModes`: `audio` for background playback;
  `remote-notification` only for silent pushes.

## 2. Android

- Strip merged permissions you don't use with `tools:node="remove"`:
  `READ_MEDIA_*` / `READ_EXTERNAL_STORAGE` (Play rejects without a core
  media use; use the Photo Picker), `AD_ID` and AdServices (otherwise
  declare advertising ID use). Template: `templates/android/AndroidManifest.snippet.xml`.
- `targetSdk` meets Play's current minimum (check the Play Console
  policy page — it rises every August).
- Release builds signed with the upload key (never the debug key);
  Play App Signing enabled.
- **Data safety** form matches the privacy manifest and policy.

## 3. Offline files and backups

Re-downloadable or paid files go to Application Support, never
Documents, and are excluded from backups — Apple's storage guideline
(2.23) rejects re-downloadable data in iCloud backup, and a restored
backup would carry paid files to another device/account.

- `templates/lib/offline_storage.dart` — `OfflineStorage.dir(name)`
  creates and excludes; `wipe(name)` on sign-out.
- `templates/ios/AppDelegate.swift` — method channel setting
  `isExcludedFromBackup` (uses `FlutterImplicitEngineDelegate`; on older
  Flutter templates register the channel in `didFinishLaunching`).
- `templates/android/res/xml/data_extraction_rules.xml` + `backup_rules.xml`.

## 4. Push notifications

- Never request permission at launch. Use a soft-ask card in context
  (end of onboarding, enabling reminders) and call the OS prompt only
  when the user taps "Turn on". Template: `templates/lib/notification_soft_ask.dart`.
- Android small icon must be monochrome (alpha only) or it renders as a
  white square: `templates/android/res/drawable/ic_notification.xml`
  + `default_notification_icon` / `_color` meta-data.
- Remove the device token from the user doc before sign-out; delete the
  FCM token after (see `firebase-backend-security` §8).
- Admin/web portals: request browser notification permission from a
  visible banner/button, not on page load.

## 5. Firebase App Check

- Activate right after `Firebase.initializeApp`
  (`templates/lib/app_check_bootstrap.dart`): Play Integrity, App Attest
  with DeviceCheck fallback, reCAPTCHA v3 on web; debug providers in dev
  builds (register the debug token in the console).
- Rollout: monitor in console → enforce Firestore/Storage → flip
  `ENFORCE_APP_CHECK=true` for callables. Ship and wait for adoption
  before enforcing, or old builds break.
- Play Integrity needs the app linked in Play Console and the SHA-256 of
  the **app signing** key (from Play Console) in Firebase.

## 6. Force-update gate

Remote Config keys per platform: `min_build_ios/android` (block),
`recommended_build_*` (dismissible banner), `store_url_*`. Compared
against the pubspec build number; fails open when offline.
Templates: `templates/lib/app_update_service.dart`,
`templates/lib/app_update_gate.dart` (wrap in `MaterialApp.builder`;
no tooltips there — no Overlay). Raise `min_build` whenever a backend
change (rules, signed URLs, server IAP) would break old builds.

## 7. App Review behaviours

- **Account deletion in-app** if accounts can be created (5.1.1(v)) —
  a visible Settings → Delete account flow that actually deletes (see
  `firebase-backend-security` §6).
- **Guest access** to non-account features; don't force sign-up to
  browse (5.1.1).
- **Hide unfinished features** — buttons that do nothing, "coming soon"
  screens, dead share actions are 2.1 rejections. Remove or hide them.
- **Purchases**: digital content only via IAP; Restore button; paywall
  shows price/period/renewal terms + Terms & Privacy links (3.1.1/3.1.2).
- **UGC**: report, block, moderation and terms acceptance (1.2).
- **Demo account** in review notes with sample purchases/data if content
  is behind login; mention where IAPs are.
- Privacy policy URL in the store listing and inside the app; Terms
  (EULA) for subscriptions.

## 8. Versioning and release

- Bump `version: x.y.z+BUILD` every upload; BUILD is what the
  force-update gate compares.
- `flutter build ipa --flavor prod -t lib/main.dart` /
  `flutter build appbundle --flavor prod`.
- Obfuscate and upload symbols (`--obfuscate --split-debug-info`, then
  Crashlytics symbol upload).
- Staged rollout on Play; phased release on iOS.
