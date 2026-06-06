# Account Deletion + Legal Documents

This doc covers the implementation of two go-live blockers:

- **P0-2 Account deletion** (Apple App Store §5.1.1(v) requirement).
- **P0-3 Privacy Policy + Terms of Service** screens.

See `docs/go_live_roadmap.md` for the broader release checklist.

---

## 1. Account deletion

### Architecture

```
UI:    DeleteAccountPage (Settings → Delete account)
          │
          ▼  re-auth (password / Google / Apple)
       AuthRepository.reauthenticate*
          │
          ▼  confirm
       AuthRepository.deleteAccount()
          │  (via cloud_functions httpsCallable)
          ▼
       Cloud Function: `deleteAccount`  (functions/src/index.ts)
          │
          ▼ deletes
          ├── users/{uid}
          ├── instructor_applications/{uid}
          ├── enrollments where userId == uid (and /progress subcoll)
          ├── courses/{*}/reviews/{uid}
          ├── songbooks/{*}/reviews where userId == uid
          ├── Storage objects under users/{uid}/
          └── Auth user record (admin.auth().deleteUser)
```

### Files added

| Path | Role |
|---|---|
| `lib/features/profile/presentation/pages/delete_account_page.dart` | UI: warning card + re-auth + type-to-confirm dialog |
| `lib/features/profile/presentation/providers/delete_account_state.dart` | Plain immutable state (no freezed) |
| `lib/features/profile/presentation/providers/delete_account_notifier.dart` | `StateNotifier` driving the flow |
| `lib/features/profile/presentation/providers/delete_account_providers.dart` | Riverpod wiring |
| `functions/src/index.ts` (extended) | Cloud Function `deleteAccount` + cascading delete helpers |

### Files changed

- `lib/features/auth/domain/repositories/auth_repository.dart` — added
  `reauthenticateWithPassword`, `reauthenticateWithGoogle`,
  `reauthenticateWithApple`, `deleteAccount`.
- `lib/features/auth/data/datasources/auth_remote_datasource.dart` — added
  matching implementations and a `FirebaseFunctions` field on the impl.
- `lib/features/auth/data/repositories/auth_repository_impl.dart` — wired
  the new methods through with the network gate + failure mapper.
- `lib/features/profile/presentation/pages/settings_page.dart` — appended
  a danger-zone "Delete account" tile.
- `lib/core/routing/route_names.dart` + `lib/core/routing/app_router.dart`
  — added a nested route under `/profile`.
- `pubspec.yaml` — added `cloud_functions: ^6.0.0`.

### Re-auth branching

Firebase Auth rejects `deleteUser()` with `requires-recent-login` if the
auth token is older than ~5 minutes. The page therefore re-authenticates
the user first, branching on
`FirebaseAuth.currentUser.providerData[*].providerId`:

- `password` — render an obscured password field; submit calls
  `reauthenticateWithCredential` with `EmailAuthProvider.credential`.
- `google.com` — re-run the Google picker via `GoogleSignIn().signIn()`
  (or `signInWithPopup` on web), then `reauthenticateWithCredential`.
- `apple.com` — re-run Apple's authorization flow with a fresh nonce.

`AuthCancellation.code` is mapped to a silent no-op so dismissing the
picker doesn't show a snackbar.

### Subscription disclosure

The page surfaces a non-dismissible reminder that App Store / Google Play
subscriptions are **not** canceled by account deletion. Users must cancel
the subscription themselves via the respective store. This wording is
required by both Apple's and Google's review guidelines.

### Cloud Function deployment

```bash
cd functions
npm install                      # installs firebase-admin / firebase-functions
npm run deploy                   # firebase deploy --only functions
```

The function uses `firebase-admin/auth`, `firebase-admin/firestore`, and
`firebase-admin/storage`. The latter requires the default bucket to be
configured (it is, via `firebase init storage` from the Firebase Console).

The function fans out batched deletes:

- Top-level `users/{uid}` + `instructor_applications/{uid}` are deleted in
  one Firestore batch.
- Enrollments are fetched by `where('userId', '==', uid)`, and each
  enrollment's `/progress` subcollection is iteratively deleted in batches
  of 200.
- Reviews are matched via a `collectionGroup('reviews')` query filtered
  by `userId == uid`; the helper routes between course-review deletion
  and songbook-review deletion based on the parent path prefix.
- Storage cleanup uses `bucket.deleteFiles({prefix: 'users/${uid}/'})`
  and is best-effort — failures are logged but don't abort the deletion.
- The Auth user is deleted **last** so the function still has Firestore
  access for the earlier steps.

### Required Firestore index

The `collectionGroup('reviews').where('userId', '==', uid)` query needs
a Firestore index. Deploy will prompt you on first call; preempt it by
adding to `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Then run `firebase deploy --only firestore:indexes`.

### Firestore rules

The existing rules allow the function to write because the Admin SDK
bypasses rules. No rule changes needed.

### Testing checklist

| Scenario | Expected outcome |
|---|---|
| Email/pw account, correct password, confirm DELETE | User signed out, routed to `/login`, all data gone |
| Email/pw account, wrong password | Snackbar with Firebase error, page stays on re-auth |
| Google account, completes re-auth picker | Reaches confirm step |
| Google account, dismisses picker | Silent no-op (no error toast) |
| Apple account on Android device | Shows "only on Apple devices" message |
| Triggered while offline | "No internet connection" snackbar |
| Cloud Function throws | "We could not delete your account…" snackbar; state moves to `failed`; user can retry |
| Function partially fails (Storage empty) | Still completes — Storage failures are best-effort |

---

## 2. Privacy Policy + Terms of Service

### Architecture

```
assets/legal/privacy_policy.md
assets/legal/terms_of_service.md
        │
        ▼  bundled assets (registered in pubspec.yaml)
   LegalDocumentPage(document: LegalDocument.X)
        │
        ▼  rendered with flutter_markdown
   Top-level route /legal/:slug
        │
        ▲ entry points:
        ├── LegalAgreementFooter on Login + Signup
        ├── Settings → "Privacy Policy" / "Terms of Service"
```

### Files added

| Path | Role |
|---|---|
| `assets/legal/privacy_policy.md` | Source markdown |
| `assets/legal/terms_of_service.md` | Source markdown |
| `lib/features/legal/presentation/pages/legal_document_page.dart` | Renderer + `LegalDocument` enum + slug routing |
| `lib/features/legal/presentation/widgets/legal_agreement_footer.dart` | "By continuing you agree to..." RichText with tappable links |

### Files changed

- `pubspec.yaml` — added `flutter_markdown: ^0.7.4` and registered
  `assets/legal/` under `flutter.assets`.
- `lib/core/routing/route_names.dart` — added `legal` name + path
  (`/legal/:slug`).
- `lib/core/routing/app_router.dart` — registered the top-level route
  (above the shell so it's reachable from auth pages) and relaxed the
  unauthenticated-user redirect to allow `/legal/*`.
- `lib/features/auth/presentation/pages/login_page.dart` and
  `signup_page.dart` — embedded `LegalAgreementFooter` after the
  switch-to-other-page row.
- `lib/features/profile/presentation/pages/settings_page.dart` — added
  Privacy Policy + Terms of Service tiles under a "Legal" section.

### Adding a new document

1. Drop a new markdown file under `assets/legal/`.
2. Add a new case to the `LegalDocument` enum (`assetPath`, `slug`,
   `titleFor(t)`).
3. Add the localized title key to `app_en.arb` + `app_vi.arb` and the
   generated `app_localizations*.dart` files.
4. Wire a route or entry point.

### Web hosting

The same markdown is exposed at `https://ilearnit.info/legal/privacy`
and `/legal/terms` via Firebase Hosting (see `public/`). The App Store
Connect "Privacy Policy URL" and the Play Console "Privacy Policy URL"
fields should point at the public URL, not the in-app screen.

### Required store metadata

- App Store Connect → App Privacy: declare data categories matching the
  policy above (Account → email, name; Identifiers → device ID, FCM
  token; Usage Data; Purchases).
- Play Console → Data safety: matching declarations.
- App Store Connect → Privacy Policy URL: `https://ilearnit.info/legal/privacy`.
- Play Console → Privacy Policy URL: same.

### Localization

The legal document bodies themselves are EN-only for v1 — the screen
titles + agreement-footer copy are localized for VI. Vietnamese
translations of the bodies can be added later as `_vi.md` variants;
extend `LegalDocument.assetPath` to read the active locale.

---

## 3. Required follow-up actions for you

The Flutter / TypeScript code is in place. To go fully green, you also need
to:

1. Run `flutter pub get` to pick up the new dependencies
   (`flutter_markdown`, `cloud_functions`).
2. `cd functions && npm install` (no new packages, but a sanity check).
3. Deploy the Cloud Function: `firebase deploy --only functions`.
4. Add the `reviews` collection-group index (see §1 above) and
   `firebase deploy --only firestore:indexes`.
5. Confirm `https://ilearnit.info/legal/privacy` and `/legal/terms` serve
   the same markdown — they're already linked from the app, but the App
   Store + Play Console need public URLs.
6. Fill in App Store Connect → App Privacy + Play Console → Data Safety.
7. Smoke-test the deletion flow per the checklist in §1.
