# Signing & Publishing — iLearnIt

End-to-end guide for shipping **iLearnIt** to the Google Play Store and Apple
App Store. Covers both flavors (`dev`, `prod`).

| Flavor | Android applicationId | iOS bundle ID         | Where it goes              |
| ------ | --------------------- | --------------------- | -------------------------- |
| dev    | `info.ilearnit.app.dev` | `info.ilearnit.app.dev` | Internal testing / TestFlight (internal) |
| prod   | `info.ilearnit.app`     | `info.ilearnit.app`     | Production / TestFlight (external) → public |

> **Golden rule:** generate the upload keystore (Android) and the App Store
> distribution certificate (iOS) **once**, then back them up to a password
> manager / secure cloud storage. Losing them blocks you from updating the
> app and recovery from Google/Apple is slow and limited.

---

## Table of contents

1. [Pre-flight checklist](#1-pre-flight-checklist)
2. [Versioning (both platforms)](#2-versioning-both-platforms)
3. [Android — generate the upload keystore](#3-android--generate-the-upload-keystore)
4. [Android — wire the keystore into Gradle](#4-android--wire-the-keystore-into-gradle)
5. [Android — build the App Bundle](#5-android--build-the-app-bundle)
6. [Android — create the app in Play Console](#6-android--create-the-app-in-play-console)
7. [Android — upload & release tracks](#7-android--upload--release-tracks)
8. [iOS — Apple Developer setup](#8-ios--apple-developer-setup)
9. [iOS — Xcode signing config](#9-ios--xcode-signing-config)
10. [iOS — archive & export the IPA](#10-ios--archive--export-the-ipa)
11. [iOS — TestFlight & App Store submission](#11-ios--testflight--app-store-submission)
12. [In-app purchase products](#12-in-app-purchase-products)
13. [Common release-blocker mistakes](#13-common-release-blocker-mistakes)
14. [Quick-reference commands](#14-quick-reference-commands)

---

## 1. Pre-flight checklist

Run through this once before your first release. After that it's only the
last column that changes between releases.

- [ ] **Tested on a real device** for both flavors — emulators miss IAP, push, deep links
- [ ] **App icon** at all required sizes (`flutter pub run flutter_launcher_icons` already wired via flavorizr)
- [ ] **Launch screens** for `dev` and `prod` look right (`ios/Runner/{dev,prod}LaunchScreen.storyboard`)
- [ ] **Privacy policy URL** is live (`https://ilearnit.info/privacy`) — both stores require it
- [ ] **Support / contact URL** is live (`https://ilearnit.info/contact`)
- [ ] **Firebase prod project (`ilearnit-31f41`)** has Auth, Firestore, Storage, Crashlytics enabled
- [ ] **App Check** registered for prod with real device-attestation providers (Play Integrity, DeviceCheck)
- [ ] **Crashlytics dSYM upload** working on iOS (Xcode → Build Phases)
- [ ] **Sample/test accounts** seeded in prod for store reviewers (Apple *requires* one)
- [ ] **`pubspec.yaml` version** bumped (see §2)

---

## 2. Versioning (both platforms)

Single source of truth: `pubspec.yaml`.

```yaml
version: 1.0.0+1   # ←  marketing version + build number
```

- The part before `+` (`1.0.0`) is `CFBundleShortVersionString` (iOS) and
  `versionName` (Android) — what users see in the store.
- The part after `+` (`1`) is `CFBundleVersion` / `versionCode`. Must be a
  monotonically increasing integer for every upload to either store, even
  if it's a re-upload of the same marketing version.

**Rules of thumb:**

- Bump `+N` for *every* TestFlight / Play upload, even rejected ones.
- Bump `1.0.0 → 1.0.1` for production bug fixes.
- Bump `1.0.0 → 1.1.0` for new user-visible features.
- Bump `1.0.0 → 2.0.0` for breaking redesigns.

---

## 3. Android — generate the upload keystore

You only do this **once** — and *never lose this file*.

```bash
mkdir -p ~/keys
keytool -genkey -v \
  -keystore ~/keys/ilearnit-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias ilearnit-upload
```

You'll be prompted for:

- A **keystore password** and a **key password** (use the same one to keep it simple, store both in 1Password)
- Your name, organizational unit (`iLearnIt`), org (`iLearnIt`), city, state, country code (`VN`)

**Back this up:**

```bash
# Encrypted copy to iCloud Drive or 1Password attachment
cp ~/keys/ilearnit-upload.jks ~/Library/Mobile\ Documents/com~apple~CloudDocs/keystore-backup/
```

> If you ever lose `ilearnit-upload.jks`, you must contact Google to reset
> your "upload key" — possible but takes days. If you *also* lose Google's
> Play App Signing key (which Google manages for you when you enroll), you
> can never update your published app again. **Enroll in Play App Signing**
> (it's the default for new apps) so Google holds the long-term key — you
> only have to safeguard the upload key.

---

## 4. Android — wire the keystore into Gradle

The gradle file is already configured (`android/app/build.gradle.kts`) to
read `android/key.properties`. You just need to create that file:

```bash
cp android/key.properties.template android/key.properties
# Then edit android/key.properties with your real keystore path & passwords
```

`android/key.properties` looks like this (replace placeholders):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=ilearnit-upload
storeFile=/Users/thanhminh/keys/ilearnit-upload.jks
```

**Verify it's gitignored:**

```bash
git check-ignore -v android/key.properties
# → android/.gitignore:18:key.properties    android/key.properties   ✓
```

If `git check-ignore` returns nothing for `key.properties` or `*.jks`,
**stop and add them to `android/.gitignore`** before committing anything.

---

## 5. Android — build the App Bundle

Google Play requires `.aab` (App Bundle), not `.apk`.

```bash
# Production bundle (uploaded to Play Console)
flutter build appbundle --release --flavor prod -t lib/main.dart

# Output:
# build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

For internal/dev testing:

```bash
flutter build appbundle --release --flavor dev -t lib/main.dart
# build/app/outputs/bundle/devRelease/app-dev-release.aab
```

If you ever need a raw APK (sideloading, QA), use `appbundle` → `bundletool`,
or:

```bash
flutter build apk --release --flavor prod -t lib/main.dart --split-per-abi
```

**Verify the AAB is signed with your upload key:**

```bash
jarsigner -verify -verbose -certs \
  build/app/outputs/bundle/prodRelease/app-prod-release.aab
# Should print:  jar verified.   (and show your CN= line)
```

If it says "jar is unsigned" or shows the debug-key CN, your
`key.properties` isn't being picked up — re-check §4.

---

## 6. Android — create the app in Play Console

1. Go to [play.google.com/console](https://play.google.com/console) → **Create app**.
2. **App details:**
   - App name: `iLearnIt`
   - Default language: `English (United States)`
   - App or game: `App`
   - Free or paid: `Free` (IAP makes it free with in-app purchases)
3. Declarations: accept Play policies + US export laws.
4. **Set up your app** — Play walks you through 10–12 tasks. Required ones:
   - **Privacy policy** → `https://ilearnit.info/privacy`
   - **App access** → if any screen requires login, give Google a test account
   - **Ads** → "No, my app does not contain ads"
   - **Content rating** → fill the questionnaire; classical-music app rates `Everyone`
   - **Target audience** → 13+ recommended (educational content)
   - **News app** → No
   - **COVID-19 contact tracing** → No
   - **Data safety** → declare what you collect (email via Firebase Auth, analytics events, purchase records)
   - **Government app** → No
   - **Financial features** → No (IAP is not a "financial feature")
   - **Store listing**: title, short description (80 chars), full description (4000 chars), screenshots, feature graphic (1024×500), icon (512×512)
5. **App pricing & distribution** → Free, pick countries.

---

## 7. Android — upload & release tracks

Play has four tracks. Use them like this:

| Track            | Audience               | Use for                        |
| ---------------- | ---------------------- | ------------------------------ |
| Internal testing | Up to 100 testers, instant | Smoke-test every build         |
| Closed testing   | Allowlisted email lists | Beta / friends & family        |
| Open testing     | Anyone with the link    | Public beta                    |
| Production       | Everyone               | The actual launch              |

**First-ever upload should go to Internal testing**, not Production.

1. Play Console → your app → **Testing → Internal testing → Create new release**.
2. Drag in `app-prod-release.aab`.
3. Fill **Release name** (`1.0.0+1`) and **Release notes** (per locale).
4. Click **Next → Save → Review release → Start rollout**.
5. Add testers (your email + a tester gmail account) under **Testers** tab.
6. They get a Play opt-in link. Install via that link, smoke-test.
7. When ready, promote the release: **Internal → Closed → Open → Production**
   from the same Releases page. Promotion is a one-click action; you don't
   re-upload the AAB.

**First production release usually takes 1–3 days** for Google review.
Subsequent ones are typically a few hours.

---

## 8. iOS — Apple Developer setup

You need an **active Apple Developer Program membership** ($99/year).

1. **Enroll:** [developer.apple.com/programs](https://developer.apple.com/programs/) (individual or organization).
2. **Find your Team ID:** developer.apple.com → Account → Membership → "Team ID" (10-char string). Save it — you'll paste into `ExportOptions.plist`.
3. **Create App IDs** (Identifiers → +):
   - `info.ilearnit.app.dev` (Dev build)
   - `info.ilearnit.app` (Prod build)
   - Enable capabilities: **Push Notifications**, **In-App Purchase**, **Sign in with Apple** (if you support it), **Associated Domains** (for `ilearnit.info` deep links).
4. **Create the app in App Store Connect:**
   - [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → `+` → New App.
   - Platform: iOS. Name: `iLearnIt`. Bundle ID: `info.ilearnit.app`. SKU: `ilearnit-ios`.
   - **Do this for prod only.** The dev bundle ID does not need an App Store Connect record — it's just used for TestFlight internal builds if you choose to.

---

## 9. iOS — Xcode signing config

Open the project in Xcode:

```bash
open ios/Runner.xcworkspace
```

For **each scheme** (`dev`, `prod`):

1. Select the `Runner` target → **Signing & Capabilities** tab.
2. Check **Automatically manage signing**.
3. **Team:** pick your team from the dropdown.
4. **Bundle Identifier:** confirm it matches (`info.ilearnit.app.dev` for the `dev` scheme, `info.ilearnit.app` for `prod`). Flavorizr already set this via `PRODUCT_BUNDLE_IDENTIFIER`.
5. Xcode auto-creates provisioning profiles. If it errors:
   - Open Xcode → Settings → Accounts → your Apple ID → **Download Manual Profiles**.
   - Or pre-create the profile at developer.apple.com → Profiles → +.

**Capabilities** to add (in this same tab, "+ Capability"):

- Push Notifications (if using FCM)
- In-App Purchase
- Sign in with Apple (if used)
- Background Modes → Remote notifications (if using FCM)

Repeat for both schemes. Then commit `ios/Runner.xcodeproj/project.pbxproj` —
the bundle IDs and team ID get baked in.

**Update `ExportOptions-AppStore.plist`:** open `ios/ExportOptions-AppStore.plist`
and replace `YOUR_TEAM_ID` with your actual 10-character Team ID.

---

## 10. iOS — archive & export the IPA

You can archive from Xcode or from the command line. **Use the CLI for reproducibility.**

```bash
# 1. Build the iOS archive
flutter build ipa --release --flavor prod -t lib/main.dart \
  --export-options-plist=ios/ExportOptions-AppStore.plist

# Output:
# build/ios/ipa/ilearnit.ipa
# build/ios/archive/Runner.xcarchive
```

If you hit signing errors, fall back to the two-step approach:

```bash
# Build the .xcarchive only
flutter build ipa --release --flavor prod -t lib/main.dart --no-codesign

# Then archive + export from Xcode UI:
# Product → Archive → Window → Organizer → Distribute App → App Store Connect → Upload
```

**Verify the IPA before uploading:**

```bash
# Confirms code signature, entitlements, and bundle ID
codesign -dvvv --verbose=4 build/ios/iphoneos/Runner.app
```

You should see `Identifier=info.ilearnit.app` and `Authority=Apple Distribution: …`.

---

## 11. iOS — TestFlight & App Store submission

### Upload to App Store Connect

Easiest: use **Apple Transporter** (Mac App Store, free):

1. Open Transporter → drag in `build/ios/ipa/ilearnit.ipa`.
2. Sign in with your Apple ID.
3. Click **Deliver**. Takes 5–20 minutes; you'll get an email when processing finishes.

Or CLI:

```bash
xcrun altool --upload-app -f build/ios/ipa/ilearnit.ipa \
  -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD
```

(App-specific password from [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords.)

### TestFlight

Once the build appears in App Store Connect → **TestFlight** tab (10–60 min after upload):

1. Click the new build → fill **Test Information** (what to test, contact email).
2. **Internal testers** (App Store Connect users): they install instantly via the TestFlight app — no review.
3. **External testers** (anyone via email or public link): requires Apple's quick "Beta App Review" (usually <24 h for the first one, instant for subsequent builds of the same version).

### Submit for App Store review

1. App Store Connect → your app → **App Store** tab → click `+ Version` if not already there.
2. Fill the version page:
   - **Description** (4000 chars), **Keywords** (100 chars), **Support URL** = `https://ilearnit.info/contact`, **Marketing URL** = `https://ilearnit.info`
   - **Screenshots** for required device sizes (6.7", 6.5", 5.5" iPhones; iPad if you support it). Use [screenshots.pro](https://screenshots.pro) or take fresh ones in Simulator.
   - **App Review Information**: demo account (email + password), notes for the reviewer ("Sign in with the provided account → tap any course → tap Unlock — sandbox IAP will trigger")
   - **Version Release**: usually "Manually release this version" so you control the launch moment.
3. Select the build (from TestFlight) → **Save → Add for Review → Submit**.
4. Review usually takes 24–48 h. Common rejection reasons in §13.

---

## 12. In-app purchase products

You already have `docs/iap_setup.md` covering product creation. The condensed
checklist for store-readiness:

- **Play Console** → Monetize → Products → In-app products: create
  `info.ilearnit.tier_basic`, `…tier_standard`, `…tier_premium` as
  **non-consumable managed products** with the right prices. Status must be
  **Active**.
- **App Store Connect** → your app → **Features → In-App Purchases**:
  same three IDs, type **Non-Consumable**. Each one needs a localized
  display name, description, and a screenshot. Status must be **Ready to Submit**.
- IAP products **must be submitted alongside the binary** for the first review
  on App Store Connect — Apple won't approve products separately the first time.

---

## 13. Common release-blocker mistakes

These get apps rejected. Most are 30-second fixes once you know.

**Both stores:**

- **Privacy policy URL returns 404 or is a placeholder.** Test it from an
  incognito window. `https://ilearnit.info/privacy` must load.
- **Demo account doesn't work.** Always test the reviewer credentials yourself
  (sign out, sign in with that exact email/password, verify a course loads).
- **Sample data missing.** Reviewers need to see populated content. Seed prod
  Firestore with the 100 courses + 10 instructors before submitting.

**Play Store:**

- **Data safety form contradicts what the app actually does.** If you collect
  email via Firebase Auth, you must declare it.
- **Target API level too low.** Play requires API 34+ for new apps in 2025+.
  Confirm `compileSdkVersion = 34` (or higher) in gradle.
- **Missing `INTERNET` / `WAKE_LOCK` permissions** the manifest needs (Flutter
  adds these automatically, but custom plugins sometimes don't).
- **64-bit ABI missing.** App Bundles include both 32 + 64 automatically; APKs
  may not. Stick to AAB.

**App Store:**

- **"App lacks lasting value" (Guideline 4.2).** Reviewers want to see real
  content. Make sure the 100 sample courses are visible to the demo account.
- **Sign in with Apple required.** If you offer Google/Facebook login, you
  *must* also offer Sign in with Apple. We use email-only so this doesn't apply.
- **Encryption export compliance** (`ITSAppUsesNonExemptEncryption` in Info.plist).
  Set to `false` if you only use Apple's standard TLS:
  ```xml
  <key>ITSAppUsesNonExemptEncryption</key>
  <false/>
  ```
- **Background modes used without justification** (e.g. audio in background
  when you don't actually need it). Only enable what you use.
- **IAP unlock not testable.** Submit the IAP products in the same build
  submission and use sandbox test users.

---

## 14. Quick-reference commands

### Android

```bash
# Generate upload keystore (once)
keytool -genkey -v -keystore ~/keys/ilearnit-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias ilearnit-upload

# Configure signing
cp android/key.properties.template android/key.properties
# … then edit android/key.properties

# Build & verify
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build appbundle --release --flavor prod -t lib/main.dart

jarsigner -verify -verbose -certs \
  build/app/outputs/bundle/prodRelease/app-prod-release.aab

# Upload: drag .aab into Play Console → Internal testing → Create new release
```

### iOS

```bash
# Open in Xcode once to set Team + capabilities per scheme
open ios/Runner.xcworkspace

# Build the IPA
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
cd ios && pod install --repo-update && cd ..

flutter build ipa --release --flavor prod -t lib/main.dart \
  --export-options-plist=ios/ExportOptions-AppStore.plist

# Verify
codesign -dvvv --verbose=4 build/ios/iphoneos/Runner.app

# Upload via Transporter (drag IPA in) or:
xcrun altool --upload-app -f build/ios/ipa/ilearnit.ipa \
  -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD
```

### Bump version

```bash
# In pubspec.yaml, bump:  version: 1.0.0+1  →  1.0.0+2
sed -i '' -E 's/^(version: [0-9]+\.[0-9]+\.[0-9]+\+)([0-9]+)/echo "\1$((\2+1))"/e' pubspec.yaml
# Or just edit manually — sed magic is fragile
```

---

## Where files live in this repo

```
android/
├── app/
│   ├── build.gradle.kts          # ← reads key.properties, sets up signing
│   └── proguard-rules.pro        # ← R8/ProGuard keep rules
├── key.properties.template       # ← copy to key.properties (gitignored)
└── .gitignore                    # ← already excludes key.properties + *.jks

ios/
├── ExportOptions-AppStore.plist  # ← App Store distribution config
└── ExportOptions-AdHoc.plist     # ← Ad-hoc / TestFlight internal config

docs/
├── signing_and_publishing.md     # ← this file
└── iap_setup.md                  # ← IAP product creation
```

That's the whole pipeline. Every subsequent release reduces to: bump version,
`flutter build` for the right flavor, drag the artifact into Play Console /
Transporter.
