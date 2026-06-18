# iLearnIt — Production Migration Runbook

End-to-end procedure for moving iLearnIt from the dev Firebase project + dev flavor builds to a live, public-facing production deployment.

**Read first.** This doc complements three other runbooks. Open them in side tabs:

- [`signing_and_publishing.md`](signing_and_publishing.md) — Android keystore + iOS Xcode signing flow. Referenced in §6 and §7 below; not duplicated.
- [`go_live_roadmap.md`](go_live_roadmap.md) — feature-readiness checklist (P0/P1/P2). Use it to make sure you're not shipping with anything still in beta.
- [`technical_specification.md`](technical_specification.md) — system reference. Source of truth for the schema and the 14 Cloud Functions.

**Time estimate.** A clean migration with zero surprises is ~3 working days. Bake in 5 working days for the first release; Apple's review queue alone burns 24–48h.

---

## 0. Architecture map (what's deploying where)

| Component | Lives in | Deploys to | Tooling |
|---|---|---|---|
| Mobile app (iOS + Android) | `lib/`, `ios/`, `android/` | App Store + Play Store | Flutter + flutter_flavorizr |
| Admin web portal | `lib/admin/` (same Flutter project, web target) | Firebase Hosting (target `admin`) | `flutter build web --flavor prod` |
| Landing page | `web/public/` (static HTML+JS) | Firebase Hosting (target `landing`) | None — `firebase deploy --only hosting:landing` |
| Cloud Functions | `functions/src/index.ts` (14 functions) | Firebase Functions (us-central1) | `cd functions && npm run deploy` |
| Firestore rules | `firestore.rules` | Firebase Firestore | `firebase deploy --only firestore:rules` |
| Firestore indexes | `firestore.indexes.json` | Firebase Firestore | `firebase deploy --only firestore:indexes` |
| Storage rules | `storage.rules` | Firebase Storage | `firebase deploy --only storage` |
| Video media | Cloudflare Stream | Cloudflare account | Admin portal "Upload video" + `createCloudflareUpload` function |

Every layer has a **dev** and **prod** twin. They are wired by flavor:

```
flutter run --flavor dev          → dev Firebase project + Cloudflare dev token
flutter run --flavor prod         → prod Firebase project + Cloudflare prod token
flutter build web --flavor prod   → admin portal targeting prod
```

If you remember nothing else: **never let a single artifact talk to a mixed pair of backends**. The bug where the landing page CMS pointed at half-dev-half-prod Firebase config was a direct symptom of mixing.

---

## 1. Pre-flight checks

Before any prod resources are touched, verify the dev environment is in a healthy state. A broken dev environment migrates into a broken prod environment.

```bash
# 1) Repo state
git status                                          # must be clean
git log --oneline -5                                # know what you're about to ship

# 2) Flutter toolchain
flutter doctor -v                                   # all green
flutter --version                                   # match CI's pinned version (see CLAUDE.md)

# 3) Code generation
dart run build_runner build --delete-conflicting-outputs   # no leftover stale .g.dart

# 4) Analyzer + tests
flutter analyze
flutter test

# 5) Cloud Functions build
cd functions && npm install && npm run build && cd ..

# 6) Dev flavor smoke test on a physical device
flutter run --flavor dev -t lib/main_dev.dart
# Walk: sign up → buy a course → play a lecture → write a review
#       → check moderator queue → open admin portal in browser
```

If any of those red-light, fix before continuing. Migration is not the time to find out the build is broken.

---

## 2. Firebase production project

iLearnIt uses **two completely separate Firebase projects** per CLAUDE.md — `ilearnit-dev` and `ilearnit-prod` (your names may differ). Treat them as different accounts.

### 2.1 Create the prod project

[Firebase Console → Add project](https://console.firebase.google.com/):

1. Project name: `iLearnIt` (display only — used in emails). Set the Project ID to something stable like `ilearnit-prod` (you can't rename it later).
2. Enable Google Analytics for Firebase — pick or create an Analytics account. Used by Firebase Analytics + Crashlytics linking.
3. Choose your billing account. **Blaze plan required** — Cloud Functions, Storage downloads, and any outbound networking need it. Spark plan won't let you deploy.
4. Region: pick once and stick to it. `us-central` is the default for Functions; choose Firestore region to match (Firestore region cannot be changed after creation — pick **`nam5`** unless you have a specific reason).

### 2.2 Register apps under the project

Under Project Settings → Your apps:

```
+ iOS app
  iOS bundle ID:        info.ilearnit.app   (the prod flavor — see signing_and_publishing.md §1)
  App nickname:         iLearnIt iOS
  App Store ID:         (leave blank — filled in after first App Store Connect record)

+ Android app
  Android package name: info.ilearnit.app
  App nickname:         iLearnIt Android
  Debug signing SHA-1:  (leave blank for now; required later for Sign in with Google on Android)

+ Web app
  App nickname:         iLearnIt Admin
  Also set up Firebase Hosting: NO (we configure hosting manually for two-target setup)
```

For each registered app, download the config:

| Platform | File | Destination |
|---|---|---|
| iOS | `GoogleService-Info.plist` | `ios/Runner/Firebase/Prod/GoogleService-Info.plist` (or wherever your `flutter_flavorizr` setup puts the prod variant) |
| Android | `google-services.json` | `android/app/src/prod/google-services.json` |
| Web | (config snippet) | Paste into `web/public/assets/js/cms.js` `FIREBASE_CONFIGS.prod` (and `lib/firebase_options.dart` if you use that path) |

**Verify** by inspecting the bundled files:

```bash
plutil -p ios/Runner/Firebase/Prod/GoogleService-Info.plist | grep PROJECT_ID
# Expected: "PROJECT_ID" => "ilearnit-prod"

jq '.project_info.project_id' android/app/src/prod/google-services.json
# Expected: "ilearnit-prod"
```

If those don't say prod, the next `flutter run --flavor prod` will silently talk to dev. This is the single most common migration footgun.

### 2.3 Authentication providers

Project Settings → Authentication → Sign-in method.

**Email/password** — Enable.

**Google** — Enable. Set the support email to a monitored alias. For Android you also need the SHA-1 + SHA-256 of your **upload keystore AND the Play App Signing key** registered under Project Settings → Your Android app → Add fingerprint. (Apps signed by Play App Signing have a DIFFERENT SHA than the upload keystore — both must be present or Google sign-in works in TestFlight but fails on a Play install.)

**Sign in with Apple** — Enable. Configure under Service ID, Apple Team ID, Key ID + Private Key (.p8). Walk: Apple Developer → Certificates, Identifiers & Profiles → Identifiers → register a Service ID → enable Sign in with Apple → configure Return URLs (`https://ilearnit-prod.firebaseapp.com/__/auth/handler`). Then generate a Sign in with Apple key (.p8 file), record the Key ID, paste into Firebase. The .p8 file is single-download — store it in a password manager.

**Anonymous** — Enable. Required if you build any "guest browse → sign in later" flow that needs to migrate anonymous user data. iLearnIt's current guest mode does NOT use Firebase anonymous auth (it's literally an unauthenticated browse), so this is optional today. Leave it off until you need it.

**Authorized domains** — add the production landing domain (e.g. `ilearnit.app`) and the admin domain (e.g. `admin.ilearnit.app`). Without these, OAuth redirects from sign-in flows fail with `auth/unauthorized-domain`.

### 2.4 Firestore — rules + indexes + bootstrap data

The repo holds the source of truth. The console is read-only.

```bash
# Switch the CLI to the prod project
firebase use --add ilearnit-prod         # nickname this alias `prod`
firebase use prod                        # confirm `firebase use` shows prod is active

# Deploy rules
firebase deploy --only firestore:rules

# Deploy composite indexes (also single-field index overrides if any)
firebase deploy --only firestore:indexes
```

Indexes build asynchronously (minutes to hours depending on data size). Watch them under Firestore → Indexes. Anything stuck in `Building` for >2h means contention with another write; raise a support ticket.

**Bootstrap data.** Production should start with empty content collections (no sample courses/instructors). Run only the admin-bootstrap step:

```bash
cd sample_data
# Edit seed_firestore.js comment block to read --only=users would be acceptable here,
# but for prod we INSERT ONE bootstrap admin user manually instead of seeding.
```

Manually create the first admin user:

1. Sign up via the prod app once with the founder's real email (`founder@ilearnit.app`). This creates `users/{uid}` with `role: 'student'`.
2. Firebase Console → Firestore → `users/{uid}` → edit `role: 'admin'`.
3. Sign out and back in on the admin portal — confirm you can reach `/admin/dashboard`.

Don't seed sample instructors or courses into prod. The admin portal's own UI is the canonical way to add them.

### 2.5 Cloud Functions — secrets + deploy

The prod Cloudflare credentials are different from dev. Set the secrets before the first functions deploy or `resolveStreamPlayback` will return 401 on prod.

```bash
firebase use prod

# Cloudflare Stream — prod token (account-scoped, write permission)
firebase functions:secrets:set CLOUDFLARE_API_TOKEN
firebase functions:secrets:set CLOUDFLARE_ACCOUNT_ID

# If you've added any other secrets (Stripe live keys, SendGrid prod, etc.),
# set them the same way. Verify what's expected by grepping functions/src:
grep -rn "defineSecret" functions/src/
```

**Rotate the dev token.** The dev Cloudflare token has been pasted into chat logs and shared assets in this project; per the security notes in CLAUDE.md, rotate it before prod. Mint a fresh dev token, set `firebase use dev && firebase functions:secrets:set CLOUDFLARE_API_TOKEN`, then revoke the old one in the Cloudflare dashboard.

**Deploy the functions.**

```bash
cd functions
npm install
npm run build                          # tsc → lib/index.js
firebase use prod
firebase deploy --only functions
```

Watch the deploy log. Each of the 14 functions should print `✔ functions[…] Successful upsert`. If any of them errors (typically because a secret isn't set, or quotas haven't been raised), the deploy continues with the others — re-run after fixing.

**Function-by-function smoke test.** After the first deploy, exercise each function once from the prod app or admin portal:

| Function | Trigger | Verify |
|---|---|---|
| `onApplicationDecision` | Admin approves a fake instructor application | DM lands in the user's inbox |
| `onEnrollmentCreated` | Buy a free-tier course | "Welcome to <course>" DM lands |
| `onNotificationBroadcast` | Admin → Notifications → Send to `all_users` | Push arrives on a connected device |
| `onUserRoleChanged` | Admin promotes a user to instructor | `instructors/{uid}` doc appears within seconds |
| `onReportCreated` / `onReportResolved` | Submit a UGC report from mobile | Admin nav badge count ticks up; resolving decrements |
| `onCourseQuestionCreated` | Ask a question on a lecture | DM lands at the course's instructor |
| `onCoursePriceDrop` | Admin lowers a course price | Wishlisted users get a push |
| `resolveStreamPlayback` (callable) | Open a Cloudflare-backed lecture | HLS URL returns + plays |
| `createCloudflareUpload` (callable) | Admin uploads a video | Returns upload URL + uid |
| `processRefund` (callable) | Admin refunds a transaction | Transaction.status flips to `refunded` |
| `markPayoutPaid` (callable) | Admin marks a payout paid | Payout.status flips |
| `instructorBroadcast` (callable) | Instructor sends a course-wide message | Enrolled users receive it |
| `deleteAccount` (callable) | User taps "Delete my account" | Auth user + PII purged |

Each one not exercised is a function you'll discover broken under load.

### 2.6 Storage rules

Storage rules are deployed separately from Firestore rules:

```bash
firebase deploy --only storage
```

Inspect what's allowed:

```bash
grep -nE "match /|allow " storage.rules
```

If you've added any signed-URL flows (e.g. course PDF downloads), confirm the prod bucket name in the URLs matches the prod project (`ilearnit-prod.appspot.com`). The bucket name is in the storage console under Bucket settings.

### 2.7 Hosting — landing + admin (two targets)

iLearnIt hosts two sites from one Firebase project: a marketing landing page and the admin web app. They're configured as named targets in `.firebaserc` + `firebase.json`.

```bash
# Inspect the target config
cat .firebaserc | jq .
cat firebase.json | jq '.hosting'
```

If targets aren't set up for prod yet:

```bash
firebase use prod
firebase target:apply hosting landing ilearnit-31f41
firebase target:apply hosting admin ilearnit-admin
# (Use the actual site names you created in the Firebase Hosting console.)
```

**Build the admin portal (Flutter web, prod flavor).**

`flutter build web` does not accept `--flavor` on web. The project works around this with environment variables baked at build time. Check what the project actually uses:

```bash
grep -rn "String.fromEnvironment" lib/ | head
```

Typical command (adapt to your actual env vars):

```bash
flutter build web --release \
  --dart-define=FLAVOR=prod \
  --target lib/main_admin.dart
```

That writes to `build/web/`. Deploy to the admin target:

```bash
firebase deploy --only hosting:admin
```

**Build the landing page.** The landing page is static HTML — no Flutter build step. The CMS layer reads from Firestore at runtime, so it picks up content the admin enters via `/admin/landing-page`.

```bash
firebase deploy --only hosting:landing
```

**Verify both sites in prod.**

```bash
firebase hosting:channel:list           # both targets listed under prod project
```

Open in browser:

- Landing: `https://ilearnit-landing-prod.web.app` — verify "Featured courses" carousel pulls from prod Firestore (it should be empty on first deploy).
- Admin: `https://ilearnit-admin-prod.web.app` — sign in with the bootstrap admin user. Navigate every sidebar entry.

### 2.8 App Check (production hardening)

App Check is **strongly recommended** before public launch. Without it, an attacker who reverse-engineers your Firebase config (which is bundled into every app) can hit Firestore/Functions/Storage as if they were a real user. App Check binds every request to a verified app instance.

Firebase Console → App Check:

1. Enable for Firestore, Functions, Storage (one toggle each — start in "monitor" mode first, not "enforce", so you can spot dev/admin/test devices missing tokens before they're locked out).
2. iOS — register the **DeviceCheck** provider (no separate setup) and **App Attest** (iOS 14+). The latter requires the App Attest capability under the App ID — see §6.2.
3. Android — register the **Play Integrity** provider. Requires the SHA-256 of the upload keystore in the App Check page (separate from the auth SHA registration).
4. Web (admin portal) — register **reCAPTCHA v3 Enterprise**. Get a site key from Google Cloud → reCAPTCHA Enterprise. Paste into App Check.

Add the App Check init to `main_prod.dart`:

```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
  webProvider: ReCaptchaV3Provider('<your site key>'),
);
```

Run the prod app, watch the **App Check → Requests** dashboard. After 7 days of monitoring with >98% of requests passing, switch to **enforce**.

### 2.9 Cloud Messaging (FCM) — APNs cert for iOS

Push notifications work on Android out of the box once the app is registered. iOS requires an **APNs Authentication Key** (preferred over .p12 certificates — never expires).

Apple Developer → Keys → "+" → name "iLearnIt APNs" → enable Apple Push Notifications service → register → download the .p8 file. Note the Key ID + your Team ID.

Firebase Console → Project Settings → Cloud Messaging → Apple app configuration → APNs Authentication Key → upload the .p8 + Key ID + Team ID.

Send a test push from Firebase Console → Cloud Messaging → "Send your first message" to verify before launch.

---

## 3. Cloudflare Stream — production setup

iLearnIt's video pipeline is Cloudflare Stream. See [`cloudflare_stream.md`](cloudflare_stream.md) for the full architecture.

For prod:

1. **Cloudflare account.** Either reuse the same Cloudflare account as dev (and use separate API tokens for scope isolation) or create a brand-new account for prod (cleaner blast-radius isolation, slightly more management overhead). Recommended: separate accounts.

2. **Generate a prod API token.** Cloudflare dashboard → My Profile → API Tokens → "+ Create Token" → Custom token. **Critical settings**:
   - Permissions: `Account → Stream:Edit`, `Account → Account Settings:Read`.
   - Account Resources: **Include → your prod account specifically**. Don't leave it as "All accounts" — that was the bug that caused the 9106 "Authentication failed" error earlier in this project.
   - Client IP Address Filtering: (leave blank).
   - TTL: 1 year (calendar a renewal).

3. **Set the secrets in Firebase Functions** (§2.5 above).

4. **Test the round trip:**
   - Admin portal → Courses → pick one → Upload a lecture video.
   - Confirm the upload completes and a video UID appears.
   - Mobile app → open the lecture → confirm `resolveStreamPlayback` returns an HLS URL and the video plays.
   - Watch Cloudflare Dashboard → Stream → Videos for the new entry.

5. **Allowed origins** (Cloudflare → Stream → Settings → Allowed Origins). Restrict playback to your prod domains: `https://ilearnit.app, https://admin.ilearnit.app, https://ilearnit-prod.web.app, https://ilearnit-prod.firebaseapp.com`. Plus `null` if you need playback inside the iOS/Android apps (WebView origin). Without this restriction, your video bandwidth bill is exposed to embed abuse.

6. **Watermark + signed URLs.** Optional. Both reduce piracy at non-trivial cost in playback complexity. Defer unless legal team specifically asks.

---

## 4. Domain + SSL + DNS

Apex domain (`ilearnit.app`) and subdomain (`admin.ilearnit.app`) need to land on Firebase Hosting.

1. **Buy / point the domain.** If you've registered through Cloudflare, Squarespace, Namecheap, etc., make sure you control DNS for it (or at least can add A / CNAME / TXT records).

2. **Connect each hosting site:**
   - Firebase Console → Hosting → `ilearnit-landing-prod` → Add custom domain → `ilearnit.app` (and `www.ilearnit.app`).
   - Firebase Console → Hosting → `ilearnit-admin-prod` → Add custom domain → `admin.ilearnit.app`.
   - Firebase shows the DNS records you need (typically A records pointing to two Google IPs, plus a TXT record for ownership).

3. **Add the DNS records** at your registrar. Propagation is anywhere from minutes to 48h.

4. **Wait for SSL.** Once DNS resolves, Firebase auto-provisions a Let's Encrypt certificate. The hosting console shows status `Connected` when it's done.

5. **Verify.**
   ```bash
   curl -I https://ilearnit.app                       # 200 from Firebase Hosting
   openssl s_client -connect ilearnit.app:443 \
     -servername ilearnit.app </dev/null 2>/dev/null \
     | openssl x509 -noout -dates                     # cert validity
   ```

6. **Update auth authorized domains** (§2.3) to include the custom domains.

7. **Update CSP / CORS** if any. The mobile app doesn't enforce CSP; the admin and landing pages do via `firebase.json` headers. Confirm prod domains are allowed origins.

---

## 5. iOS — App Store deployment

See [`signing_and_publishing.md`](signing_and_publishing.md) §8–§11 for the deep dive on certificates and profiles. This section is the **production-specific** workflow that wraps around it.

### 5.1 App Store Connect record

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → "+ New App".
2. Platform: iOS. Bundle ID: `info.ilearnit.app` (must already exist as an App ID under Apple Developer). Name: "iLearnIt". Primary language: English (U.S.). SKU: `iLearnIt-iOS-001` (internal — doesn't matter).

### 5.2 Capabilities (Apple Developer → Identifiers → your App ID → Configure)

Enable on the App ID:

- **Push Notifications** — needed by FCM (APNs).
- **Sign In with Apple** — required if Google sign-in is offered (Guideline 4.8). iLearnIt offers Google, so this is mandatory.
- **Associated Domains** — only if you implement universal links. Defer.
- **App Attest** — required if you turn on Firebase App Check with AppAttest provider (§2.8). Enable.
- **Background Modes** — already declared in `Info.plist` as `audio` (mini-player). No App ID config needed; this one lives entirely in Info.plist.

### 5.3 Privacy manifest (`PrivacyInfo.xcprivacy`)

Apple requires every iOS app submitted after May 2024 to declare its data collection + the reason it uses certain "required reason" APIs (`UserDefaults`, `FileManager`, `SystemBootTime`, etc.). The privacy manifest lives at `ios/Runner/PrivacyInfo.xcprivacy`.

If you don't have one yet, create it:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <!-- Match the App Privacy nutrition labels in App Store Connect EXACTLY. -->
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeEmailAddress</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
        <!-- Add entries for: Name, User ID, Purchase History, Product Interaction,
             Crash Data, Performance Data, Other Diagnostic Data. -->
    </array>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
        <!-- Add entries for: FileTimestamp (C617.1), SystemBootTime (35F9.1),
             DiskSpace (E174.1) — most apps need all four. -->
    </array>
</dict>
</plist>
```

Also generate manifests for **third-party SDKs** if they don't ship their own. Anthropic-side note: Firebase, GoogleSignIn, AppleSignIn, just_audio, video_player, chewie all ship privacy manifests as of mid-2025. The build will warn if any are missing.

### 5.4 Verify Info.plist for prod

The prod variant of `Info.plist` is what gets bundled in the App Store build. Confirm:

- `CFBundleIdentifier` = `info.ilearnit.app` (set by build config, not literal).
- `UIBackgroundModes` contains `audio` (already done — mini-player).
- `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription` — present + meaningful only if you actually use them. **Apple rejects empty or stock usage strings.**
- `CFBundleURLSchemes` — has BOTH the dev and prod REVERSED_CLIENT_ID? Actually no — the prod build should bundle ONLY the prod scheme. If both are listed, Google sign-in still works but App Store reviewers may ask why.
- `NSAppTransportSecurity` — no global `NSAllowsArbitraryLoads: true`. If you have it for dev, remove it for prod.

### 5.5 App Privacy nutrition labels (App Store Connect → App Privacy)

Manually enter every data type the app collects. Must match `PrivacyInfo.xcprivacy` exactly or Apple rejects.

For iLearnIt (typical answers):

| Data type | Collected? | Linked to user? | Used for tracking? | Purpose |
|---|---|---|---|---|
| Email address | Yes | Yes | No | App Functionality, Account |
| Name (displayName) | Yes | Yes | No | App Functionality |
| User ID | Yes | Yes | No | App Functionality, Analytics |
| Purchase history | Yes | Yes | No | App Functionality |
| Product interaction (Firebase Analytics events) | Yes | Yes | No | Analytics |
| Crash data | Yes | No | No | App Functionality (Crashlytics) |
| Performance data | Yes | No | No | App Functionality (Perf SDK) |
| Other diagnostic data | Yes | No | No | App Functionality |

If you've added Mixpanel / Segment / Amplitude / Branch, each adds more rows. Keep this in sync with what's actually in `pubspec.yaml`.

### 5.6 Build + archive the prod IPA

Per [`signing_and_publishing.md`](signing_and_publishing.md) §9–§10. Quick version:

```bash
# Bump version
# pubspec.yaml: version: 1.0.0+1  →  1.0.0+1 (or 1.0.1+2 for subsequent builds)

# Clean
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Build the IPA via Xcode (recommended — it handles signing best)
flutter build ipa --release --flavor prod --target lib/main_prod.dart \
  --export-options-plist=ios/ExportOptions.plist
# Or open ios/Runner.xcworkspace, switch scheme to Runner-prod, Product → Archive → Distribute App.
```

Upload to App Store Connect via **Transporter** or `xcrun altool --upload-app`. Wait 5–15 min for processing.

### 5.7 TestFlight (internal first, then external)

Internal testing first — add your team's Apple IDs under TestFlight → Internal Testing → Internal Testers. Walk the same 20-minute regression you did on dev: sign up, buy, play, review, moderate.

External testing requires "Beta App Review" (lighter than full review, ~24h turnaround). Beta App Review needs:

- Test account credentials (an account that's a paid subscriber or has a course unlocked).
- Beta description: 1–2 lines about what's new in this build.
- Demo notes: "Tap any course on the home tab to see purchase flow. The instrument tutorials are the main user journey."

### 5.8 Submit for App Store review

App Store Connect → App Store → Prepare for Submission. Required:

- **Screenshots** (6.5" iPhone, 5.5" iPhone fallback, 12.9" iPad if iPad-supported). Minimum 3, maximum 10. Take from a real device or use the simulator.
- **Promotional text** (170 chars) — changeable any time, doesn't trigger re-review.
- **Description** (4000 chars) — the long form.
- **Keywords** (100 chars, comma-separated).
- **Support URL** + **Marketing URL** (the latter is optional).
- **Age rating** — answer the questionnaire. iLearnIt likely 4+ (no objectionable content). If you have classical music with mild lyrical themes, 9+. Anything else, recheck.
- **App Review Information** — **provide a test account** (email + password) with full access. Without it Apple will reject within an hour.
- **Notes for the reviewer** — explain anything non-obvious. For iLearnIt: "This is a course marketplace. Tap a course → preview → purchase via IAP. Q&A and reviews are user-generated content; the Report and Block actions are accessible via the three-dot menu on each item per Guideline 1.2."
- **Export compliance** — uses HTTPS only → "Yes, my app uses standard encryption." Answer the questionnaire. The annual self-classification report is required if you use anything beyond standard HTTPS.

Common rejections specific to iLearnIt's surface area (also see `go_live_roadmap.md` companion checklist):

1. **3.1.1 In-app purchase**. If your iOS prod build still uses Stripe for course purchases (instead of StoreKit IAP), this is the highest-risk reject. Use StoreKit, OR fall back to a reader-app model (no in-app purchase, all content unlock happens on the web), OR remove paid purchase from iOS entirely.
2. **1.2 UGC moderation**. Required: Report button on every UGC item (done via UgcOverflowMenu), block-user flow (done), EULA accepted at signup (done), in-app moderation queue that responds within 24h (done — `/moderator`). Reviewer will tap the three-dot menu to check.
3. **5.1.1(v) Account deletion**. Must be reachable in-app (Profile → Delete account). Verify it actually deletes both Auth + Firestore data — Apple has been known to file deletion via a test account and check 30 days later.
4. **4.8 Sign in with Apple**. Required when Google sign-in is offered.

Submit. Watch App Store Connect → My Apps → Activity → Review history for status updates.

---

## 6. Android — Play Store deployment

See [`signing_and_publishing.md`](signing_and_publishing.md) §3–§7 for the keystore + Gradle wiring. This section is the **launch-specific** wrap.

### 6.1 Play Console app record

[play.google.com/console](https://play.google.com/console) → Create app.

- App name: iLearnIt
- Default language: English
- App or game: App
- Free or paid: Free (purchases happen inside the app)
- Declarations: confirm content policy, US export laws, etc.

### 6.2 App Signing (Play App Signing — recommended)

Play App Signing means Google holds the production signing key. You upload AABs signed with your **upload key**; Google re-signs with the **app signing key** before serving them. If your upload key is ever lost, you can reset it — without Play App Signing, a lost key blocks all updates forever.

`signing_and_publishing.md` §4 explains how to enrol. Critical: **register BOTH the upload SHA-256 and the app signing SHA-256 with Firebase Auth** (§2.3) — they're different.

### 6.3 Build the prod AAB

```bash
flutter clean
flutter pub get
flutter build appbundle --release --flavor prod \
  --target lib/main_prod.dart \
  --build-name=1.0.0 --build-number=1
# Output: build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

Verify the AAB before uploading:

```bash
# Confirm the upload key signed it
$ANDROID_HOME/build-tools/<version>/apksigner verify --print-certs \
  build/app/outputs/bundle/prodRelease/app-prod-release.aab

# Confirm the applicationId
unzip -p build/app/outputs/bundle/prodRelease/app-prod-release.aab \
  base/manifest/AndroidManifest.xml | strings | grep package
# Expected: info.ilearnit.app (no .dev suffix)
```

### 6.4 Internal testing track first

Play Console → Testing → Internal testing → Create new release → upload the AAB. Add your team's Google accounts under Testers → email list. Share the opt-in URL.

The first build also has to clear:

- **App content** section (left sidebar) — each toggle (Privacy policy URL, App access, Ads, Content rating, Target audience, News, COVID-19, Data safety, Government apps, Financial features, Health) needs an answer or "Not applicable." Half-filled = no release.

### 6.5 Data Safety form

[The single most common Play rejection in 2024-2026.](https://support.google.com/googleplay/android-developer/answer/10787469) The form must match what your code actually does.

For iLearnIt (typical answers):

| Question | Answer |
|---|---|
| Does your app collect or share any user data? | Yes |
| Data types — Personal info → Name | Collected, Shared with Firebase, Encrypted in transit, Required, Account management |
| Data types — Personal info → Email | Collected, Shared with Firebase, Encrypted in transit, Required, Account management + Communications |
| Data types — Personal info → User IDs | Collected, Shared with Firebase, Encrypted in transit, Required, App functionality + Analytics |
| Financial info — Purchase history | Collected, Encrypted in transit, Required, App functionality |
| App activity — App interactions | Collected, Encrypted in transit, Optional, Analytics |
| App info and performance — Crash logs | Collected, Encrypted in transit, Optional, App functionality |
| App info and performance — Diagnostics | Collected, Encrypted in transit, Optional, App functionality |
| Is all of the user data collected by your app encrypted in transit? | Yes |
| Do you provide a way for users to request that their data be deleted? | Yes — link to the in-app account deletion path |

If you've added Mixpanel / Adjust / Branch / Sentry / etc., each pulls its own row.

### 6.6 Content rating, target audience, ads, etc.

Content rating: complete the IARC questionnaire. iLearnIt as a music-education app is normally PEGI 3 / ESRB Everyone unless you have explicit lyrics.

Target audience: 18+ (or 13+ if you want kids). If kids: COPPA scope applies and SDK allowlist gets strict. Avoid.

Ads: No (iLearnIt isn't ad-supported).

### 6.7 Production track

After ~5 days of clean internal testing and at least one external tester running through the flows, promote to production.

- Play Console → Production → Create new release → "Promote release from Internal testing" → pick the latest build.
- Release notes: short, user-facing.
- **Staged rollout**: start at 5%. Increases by 25% / 50% / 100% over a week as crash-free rate holds above 99.5%.

Submit. Play review usually clears in 4–24h (faster than App Store).

---

## 7. Web — landing + admin deployment

Already covered in §2.7. The launch-day variant adds:

- **Cache-busting** — the existing `firebase.json` headers cache `assets/css/**` and `assets/js/**` for a year but mark `**/*.html` as `max-age=0, must-revalidate`. That means deploying a new landing page is instant for HTML and ~5 minutes for the bundled JS (CDN edge nodes need to revalidate). Don't deploy 30 seconds before a marketing email blast.

- **Admin build invalidation** — the Flutter web build hashes its bundles by content. As long as the HTML wrapper has `max-age=0`, new admin builds propagate without a stale-cache window.

- **Cross-environment guard** — verify the deployed admin actually points at prod Firebase:

  ```js
  // In browser devtools on https://admin.ilearnit.app
  firebase.app().options.projectId
  // Expected: "ilearnit-prod"
  ```

  Same check on the landing page (cms.js reads `window.location.hostname` to pick the right config).

---

## 8. Monitoring & alerting

The launch is when you find out what your monitoring actually covers. Set this up BEFORE launch, not after the first incident.

### 8.1 Crashlytics

Should already be wired (per `pubspec.yaml`). Verify in prod:

1. Cause a deliberate test crash on a TestFlight / Internal-testing build: `FirebaseCrashlytics.instance.crash();` behind a hidden debug menu.
2. Watch Firebase Console → Crashlytics → Issues for the entry to appear within ~5 minutes.
3. Set up Slack / email alerts: Crashlytics → "+ Notification" → on "New issue" + "Velocity alert (1% of sessions affected in 1h)".

### 8.2 Cloud Functions logs + alerts

Cloud Logging → Log Router → Sinks → create a sink that forwards `severity >= ERROR` from Cloud Functions to a Pub/Sub topic. Subscribe a Slack webhook to that topic. ~10 min of setup; saves hours during the first incident.

Also create a budget alert: GCP Console → Billing → Budgets & alerts → $50/day soft cap initially. Email when 50% / 90% / 100% hit.

### 8.3 Firestore usage

Watch the Firestore Usage tab during the first week. The Wishlist + My Learning + Reviews flows are the read-heaviest paths in iLearnIt. If reads/sec spike unexpectedly, the most common cause is a missing `.limit()` in a query — search `lib/` for `.snapshots()` without `.limit()`.

### 8.4 Cloud Functions cold starts

The 14 Cloud Functions run on Cloud Functions v2. Cold starts on v2 are ~300–1500ms. For the user-facing callables (`resolveStreamPlayback`, `processRefund`, `deleteAccount`), this is acceptable. For Firestore triggers, cold starts don't block users.

If cold starts impact UX, enable **minimum instances** on the callables:

```typescript
export const resolveStreamPlayback = onCall(
  { minInstances: 1, secrets: [CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID] },
  async (request) => { /* ... */ }
);
```

Costs ~$5/month per warm instance. Cheaper than the lost-purchase user that gave up after a 3-second video resolve delay.

### 8.5 Analytics

`docs/analytics.md` lists the event catalog. After launch, verify the top funnels report in Firebase Analytics:

- Signups per day (auth screen → sign up → home)
- Purchase funnel (course detail → buy → confirmed)
- D1 retention (signed up today → opened tomorrow)

If `purchase_completed` events stop firing, you have a wiring bug that's invisible from Crashlytics. Set up a manual alert: GCP Console → Monitoring → Alerting → custom metric "purchase_completed count over 1h" — alert if drops below typical baseline.

---

## 9. Cost & quotas

iLearnIt's marginal cost per user is dominated by:

1. **Cloudflare Stream minutes-delivered** — by far the biggest. Each user watching a 20-minute lecture in 1080p costs ~$0.01–0.03 in delivery. Watch this hourly during launch week.
2. **Firestore reads** — second-biggest. ~3-5M reads/day per 1k active users is typical.
3. **Cloud Functions invocations** — third. Free tier covers thousands of users; pay-as-you-go after that.
4. **Storage** — small unless you store videos in Firebase Storage instead of Cloudflare (you don't — confirm Storage holds only thumbnails + Songbook PDFs).

Quotas worth pre-raising before launch:

- **Firebase Auth daily new users** — default is 100/day or so on a new project. Request raise to 1k/day via Firebase Support if you expect launch-day spike.
- **Cloud Functions concurrent executions** — default 1000. Fine for launch-day.
- **Firestore writes/sec** — default 10k/sec. Fine.

---

## 10. Backup & disaster recovery

Firestore is replicated within its region by Google. That covers hardware failure but not "we deleted a collection by mistake." Set up scheduled exports.

```bash
# Once-off: create a GCS bucket for exports in the same region
gcloud storage buckets create gs://ilearnit-prod-firestore-backups \
  --location=us-central1 \
  --uniform-bucket-level-access

# Schedule daily exports (Cloud Scheduler + Firestore export API)
# Easiest: use Firebase CLI's built-in scheduled export feature.
gcloud scheduler jobs create http nightly-firestore-export \
  --schedule="0 4 * * *" \
  --time-zone="Asia/Ho_Chi_Minh" \
  --uri="https://firestore.googleapis.com/v1/projects/ilearnit-prod/databases/(default):exportDocuments" \
  --http-method POST \
  --oauth-service-account-email firestore-backups@ilearnit-prod.iam.gserviceaccount.com \
  --message-body='{"outputUriPrefix":"gs://ilearnit-prod-firestore-backups/$(date +%Y%m%d)"}'
```

Lifecycle rule on the bucket: delete exports older than 30 days, archive 30-365 days.

**Restore drill** — do this once before launch. Pick a non-critical collection (e.g. `reviews`), delete a doc, restore from yesterday's export via `gcloud firestore import gs://…`. Confirm the doc is back. Knowing the restore flow works is more valuable than the backups themselves.

---

## 11. Launch-day runbook

The actual sequence on the day you flip the switch. Step-by-step so anyone can execute.

### T-7 days

- [ ] `signing_and_publishing.md` followed; release-signed prod builds successfully install.
- [ ] App Store: app record submitted, reviewed, **status `Pending Developer Release`** (so it doesn't auto-release the moment Apple approves).
- [ ] Play Store: internal track green, production release prepared but **not yet rolled out**.
- [ ] Custom domain DNS propagated; landing + admin reachable via prod URLs.
- [ ] Crashlytics test crash visible.
- [ ] Cloud Functions logs alert wired.
- [ ] Firestore nightly backup ran at least once successfully.
- [ ] Press / launch comms drafted; social cards verified to fetch from prod landing.

### T-1 day

- [ ] Final tag: `git tag v1.0.0 && git push origin v1.0.0`
- [ ] Deploy refresh: `firebase deploy` (re-runs functions, rules, indexes, hosting) — confirms nothing has drifted.
- [ ] Smoke test once more on a clean device install: sign up → buy → play → review.
- [ ] Confirm the bootstrap admin account password is in 1Password and at least two team members can reach it.

### Launch day (T-0)

Time-ordered. Adjust to your timezone preference.

**08:00 — final verification**
- [ ] Firebase Console: no overnight alerts, no quota near-hits.
- [ ] Cloudflare Stream: bandwidth headroom (your projection ÷ Cloudflare's "Stream Free 1000 minutes" allowance).
- [ ] Test account on TestFlight + Internal Testing track: open, complete a fresh purchase, confirm Crashlytics receives the session.

**09:00 — App Store release**
- [ ] App Store Connect → version → Release → confirm.
- [ ] Wait ~30 min for global rollout to complete.
- [ ] Spot-check: `xcrun altool --list-apps` shows current version. Open the App Store on a real device, search "iLearnIt," confirm version.

**09:30 — Play Store rollout to 100%**
- [ ] Play Console → Production → "Increase release to all users."
- [ ] Wait ~10 min. Spot-check on a clean Android device.

**10:00 — landing page CTA flip**
- [ ] Admin portal → Landing page → toggle "Download apps" CTAs from `coming soon` to `App Store` + `Play Store` links.
- [ ] `firebase deploy --only hosting:landing` (only needed if CTAs are static; if they're CMS-backed, save in the admin portal suffices).

**10:15 — announce**
- [ ] Social posts, email blast, etc.

**10:15 to 18:00 — watch hour**
- [ ] Firebase Console open in one tab.
- [ ] Crashlytics open in another.
- [ ] Cloudflare Stream dashboard in a third.
- [ ] Cloud Functions logs filtered to `severity >= WARNING`.
- [ ] Watch for: signup rate, purchase completion rate, crash-free sessions, function error rate.

**Day-end retrospective**
- [ ] Compare actual numbers to projections.
- [ ] Capture any incident learnings into a tag on this doc.

### Rollback plan

If a P0 issue surfaces in the first 24h:

- **Mobile app** — you can't pull a release from the stores instantly, but you can:
  - Push a server-side fix via Cloud Functions / Firestore rules (fastest).
  - Use Remote Config to flag-off the broken feature.
  - Submit an expedited App Review (24–72h) for a hotfix build.
- **Cloud Functions** — `firebase functions:delete <name>` to disable; redeploy a previous version with `firebase deploy --only functions:<name>` after a `git checkout`.
- **Firestore rules** — `firebase deploy --only firestore:rules` after reverting `firestore.rules` to the last-known-good commit.
- **Hosting** — `firebase hosting:rollback` (each deploy is a snapshot; one-click revert).

---

## 12. Post-launch (first 30 days)

| Day | Task |
|---|---|
| +1 | Read through every Crashlytics issue from launch day. File JIRA tickets, not P0 fixes. |
| +3 | Review App Store + Play Store user reviews. Reply to anything actionable. |
| +7 | Bump Play Store staged rollout to 100% if held at <100%. |
| +7 | Lift Firebase App Check from monitor → enforce (assuming >98% requests had tokens). |
| +14 | First post-launch retrospective. What broke, what surprised, what to keep monitoring. |
| +30 | Subscription auto-renewal cohorts mature — check churn vs. forecast. |
| +30 | Cloudflare bandwidth bill arrives — verify it matches model. |

---

## Appendix A: Credential / account checklist

These are the credentials you need access to (or to delegate to someone with continuity). Lose any of them and recovery is slow. Store in 1Password / Bitwarden — never in the repo.

- [ ] Firebase prod project — Owner role on at least two team members' accounts.
- [ ] GCP billing account — Billing Account Administrator on at least two accounts.
- [ ] Apple Developer account (Account Holder) — must be a real human; cannot be transferred easily.
- [ ] App Store Connect (Admin role) — separate from the Apple Developer account; assign to ≥2 people.
- [ ] Google Play Console (Owner role) — assign to ≥2 people.
- [ ] Cloudflare prod account — at least two Super Administrators.
- [ ] Domain registrar — at least two accounts with control panel access.
- [ ] Sign In with Apple .p8 key — single-download, can't re-issue easily.
- [ ] APNs Authentication Key (.p8) — same.
- [ ] Android upload keystore + password — backed up in two physical locations.
- [ ] Play Upload Certificate (post-Play App Signing) — backed up.
- [ ] Stripe / payment processor live keys — backed up.
- [ ] Email forwarding for `support@`, `legal@`, `privacy@`, `security@` — at minimum, all four are required by App Store legal pages.

---

## Appendix B: Common App Store / Play rejection causes specific to iLearnIt

Tracked against this codebase. If a reviewer cites one, this is where to look.

| Rejection code | Where it likely surfaces in iLearnIt | Fix path |
|---|---|---|
| iOS Guideline 3.1.1 (IAP) | Course purchase flow on iOS using Stripe instead of StoreKit | See `iap_setup.md`; switch to StoreKit OR adopt reader-app model |
| iOS Guideline 1.2 (UGC) | Missing Report button on a UGC item, or moderator queue 24h SLA unclear | Verify `UgcOverflowMenu` is wired on every UGC tile; document 24h SLA in submission notes |
| iOS Guideline 5.1.1(v) (Account deletion) | Delete account doesn't purge Firestore PII | Verify `deleteAccount` Cloud Function nukes `users/{uid}` + subcollections + `reviews` where userId == uid + reports filed by user |
| iOS Guideline 4.8 (Sign in with Apple) | Google sign-in present, SIWA missing | Already implemented — confirm it's still wired in prod build |
| iOS Guideline 5.1.2 (Data collection) | Privacy manifest missing or doesn't match labels | Sync `PrivacyInfo.xcprivacy` with App Privacy nutrition labels |
| iOS Guideline 2.1 (Crash on launch) | Reviewer's device has no network mid-flow | Test offline / slow-network on the lecture player + sign-in path |
| Play — Data safety mismatch | Form says "no data shared" but app sends to Firebase | Update Data safety form; this is the #1 Play rejection |
| Play — Target API level | Flutter target SDK behind Play's annual minimum | `flutter build appbundle` uses the SDK pinned in `android/app/build.gradle.kts`; bump |
| Play — Permissions disclosure | App requests `BLUETOOTH_CONNECT`/`POST_NOTIFICATIONS` without explanation | Add Permissions Declaration to Play Console listing |

---

## Appendix C: Day-of-launch contact list template

Fill this in before launch and pin in the team channel.

```
On-call mobile dev      : <name> / <phone> / <email>
On-call backend dev     : <name> / <phone> / <email>
On-call admin           : <name> / <phone> / <email>
Apple Developer Account : <name>
Google Play Console     : <name>
Firebase prod billing   : <name>
Cloudflare prod billing : <name>
Domain registrar        : <name>
Security incident       : security@ilearnit.app
```

---

**Last updated:** 2026-06-14. Update whenever a new service joins the production stack (Stripe, Sentry, RevenueCat, Apple Search Ads attribution, etc.).
