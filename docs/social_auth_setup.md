# Social Sign-In Setup — Google & Apple

iLearnIt supports three authentication methods through Firebase Auth: **email + password** (already wired), **Google Sign-In**, and **Sign in with Apple** (iOS only). The Dart side is fully wired; this doc covers the native + Firebase Console configuration you must do **once per environment** (dev + prod).

## Architecture summary

```
LoginPage / SignupPage
        │  tap "Continue with Google" / "Continue with Apple"
        ▼
AuthNotifier.signInWithGoogle() / .signInWithApple()
        ▼
AuthRepository (network gate + token persistence)
        ▼
AuthRemoteDataSource
   ├── Google: GoogleSignIn → FirebaseAuth.signInWithCredential(GoogleAuthProvider…)
   └── Apple:  SignInWithApple (nonce + sha256) → FirebaseAuth.signInWithCredential(OAuthProvider("apple.com")…)
        ▼
Firestore `users/{uid}` — upserted on first social sign-in (existing docs are preserved)
```

User cancellation is mapped to `Failure.auth(code: 'cancelled')` and the notifier swallows it, so the snackbar doesn't fire when the user just dismisses the picker.

## 1. Firebase Console — enable both providers

For **both `iLearnIt-Dev` and `iLearnIt-Prod`** projects:

1. Firebase Console → **Authentication → Sign-in method**.
2. Enable **Google** — fill in the Project support email.
3. Enable **Apple** — leave the optional fields empty for the iOS-only flow.

## 2. Android — SHA fingerprints (Google Sign-In)

Google Sign-In on Android needs your app's signing fingerprints registered in Firebase, otherwise `GoogleSignIn().signIn()` returns `null` silently.

```bash
# debug fingerprint — for development on your machine
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  -storepass android -keypass android

# release fingerprint — for production builds
keytool -list -v -alias upload \
  -keystore android/app/upload-keystore.jks
```

In **Firebase Console → Project Settings → General → Your apps → Android app**:
- Add the **debug SHA-1** to the dev project.
- Add the **release SHA-1** *and* **SHA-256** to the prod project.
- After saving, re-download `google-services.json` and replace `android/app/src/dev/google-services.json` and `android/app/src/prod/google-services.json`.

No code changes — `flutter_flavorizr` already maps each flavor to its own `google-services.json`.

## 3. iOS — URL scheme for Google Sign-In

Google Sign-In on iOS needs the **reversed client ID** registered as a URL scheme. The value lives in your `GoogleService-Info.plist` under `REVERSED_CLIENT_ID` and looks like:

```
com.googleusercontent.apps.123456789012-abcdef…
```

Open `ios/Runner/Info.plist` and add (per flavor — see below for the flavorized variant):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- PASTE the REVERSED_CLIENT_ID from your GoogleService-Info.plist here -->
      <string>com.googleusercontent.apps.XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXX</string>
    </array>
  </dict>
</array>
```

> Because we ship two flavors (`dev`, `prod`), each has its own `GoogleService-Info.plist` and therefore its own reversed client ID. If you use a single `Info.plist`, list **both** schemes inside the same `CFBundleURLSchemes` array — iOS will match the right one at runtime. If you ship two `Info-Dev.plist` / `Info-Prod.plist`, paste the per-flavor value into each.

## 4. iOS — Sign in with Apple capability

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities** → **+ Capability** → **Sign in with Apple**.
3. Repeat for any per-flavor target (e.g. `Runner-Dev`, `Runner-Prod`) if you split targets.
4. Apple Developer Console → **Certificates, Identifiers & Profiles → Identifiers → your App ID**.
5. Enable **Sign in with Apple** for the App ID. Save.
6. Regenerate provisioning profiles if Xcode prompts you.

If you ship to **TestFlight / App Store**, your bundle identifier must match the App ID you enabled "Sign in with Apple" on. The capability auto-adds an `aps-environment`-style entry to `Runner.entitlements` — let Xcode manage that file.

## 5. Android — Apple Sign-In (not enabled)

By design (see `LoginPage` & `SignupPage`), the Apple button only renders on iOS:

```dart
final showAppleButton = !kIsWeb && Platform.isIOS;
```

Android users sign in with Google or email. If you later need Apple on Android, you'll need to add a Service ID in Apple Developer Console, configure the redirect URL to `https://<your-firebase-app>.firebaseapp.com/__/auth/handler`, and switch the Dart-side `Platform.isIOS` gate to allow Android — the existing `_remote.signInWithApple()` already uses `OAuthProvider("apple.com")` which works on both platforms.

## 6. Verifying

1. `flutter pub get` (pulls `google_sign_in`, `sign_in_with_apple`, `crypto`).
2. Run `flutter run --flavor dev -t lib/main_dev.dart`.
3. **Google**: tap "Continue with Google" → native picker → account chosen → land on Home, signed in.
4. **Apple** (iOS only): tap "Continue with Apple" → Face/Touch ID prompt → land on Home.
5. **Firestore**: a new `users/{uid}` doc should exist with `email`, `displayName`, `photoUrl`, `createdAt` populated.
6. **Cancel test**: tap "Continue with Google", then dismiss the sheet — no error snackbar should appear, you should stay on the Login screen.

## 7. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `signIn()` returns `null` instantly on Android | SHA-1 missing in Firebase Console | Add debug+release SHA-1, re-download `google-services.json` |
| iOS Google picker shows "redirect URI mismatch" | URL scheme missing in `Info.plist` | Paste the `REVERSED_CLIENT_ID` value from `GoogleService-Info.plist` |
| Apple button hangs after Face ID | Capability missing in App ID | Enable Sign in with Apple in Apple Developer Console + Xcode |
| First Apple login returns no name on second login | Apple only returns name on first authorization | We persist `displayName` to Firestore on first sign-in (see `_upsertSocialUser`) — re-test after deleting the Firebase user |
| `invalid-credential` from Apple | Stale nonce | Don't reuse credentials; each `signInWithApple()` generates a fresh nonce |
| Builds fail with `error: undefined symbol AuthenticationServices` | iOS deployment target too low | Set iOS deployment target ≥ 13.0 in `ios/Podfile` |

## 8. Files touched by this feature

- **Code**
  - `pubspec.yaml` — added `google_sign_in`, `sign_in_with_apple`, `crypto`
  - `lib/features/auth/domain/repositories/auth_repository.dart` — `signInWithGoogle/Apple` + `AuthCancellation.code`
  - `lib/features/auth/data/datasources/auth_remote_datasource.dart` — provider flows + Firestore upsert + nonce helpers
  - `lib/features/auth/data/repositories/auth_repository_impl.dart` — shared `_runSocial` envelope
  - `lib/features/auth/presentation/providers/auth_notifier.dart` — `signInWithGoogle/Apple` (cancel-aware)
  - `lib/features/auth/presentation/widgets/social_sign_in_button.dart` — branded buttons
  - `lib/features/auth/presentation/pages/login_page.dart`, `signup_page.dart` — picker UI
- **i18n**
  - `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` — `authOrContinueWith`, `authContinueWithGoogle`, `authContinueWithApple`
- **Docs**
  - `docs/social_auth_setup.md` — this file
