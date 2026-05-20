# In-App Purchases — store setup

The app uses three flat price tiers instead of one SKU per course. Each
course's `priceTier` field maps to one of these products:

| Tier      | Product ID                       | Suggested price (USD) |
| --------- | -------------------------------- | --------------------- |
| basic     | `info.ilearnit.tier_basic`       | $9.99                 |
| standard  | `info.ilearnit.tier_standard`    | $19.99                |
| premium   | `info.ilearnit.tier_premium`     | $39.99                |

All three are **non-consumable** — the user owns the course forever once
purchased. Restore-purchases support is built in (Profile → "Restore
purchases").

## iOS — App Store Connect

1. Sign in at https://appstoreconnect.apple.com.
2. App → **iLearnIt** → **Features → In-App Purchases → +**.
3. Pick **Non-Consumable**. Create each of the three product IDs above.
4. Fill in:
   - **Reference Name** (internal, e.g. "Tier — Basic")
   - **Product ID** (must match exactly)
   - **Cleared for Sale** ✓
   - Pricing tier (1 = $0.99, 10 = $9.99, etc.)
   - Localizations: at minimum English; display name + description.
5. Repeat for `_standard` and `_premium`.
6. **Important — sandbox testing**:
   - App Store Connect → Users and Access → Sandbox Testers → add one.
   - Sign out of the App Store on the test device, then run the app and
     tap a Buy button. The system will prompt to sign in with the sandbox
     account.
7. **StoreKit configuration file** (optional, for offline local testing):
   - In Xcode → New File → StoreKit Configuration File → "StoreKit.storekit".
   - Add the same product IDs and prices.
   - Edit your scheme → Run → Options → StoreKit Configuration → pick the
     file. Sandbox sign-in is no longer required for purely UI testing.

## Android — Google Play Console

1. https://play.google.com/console → app → **Monetize → Products →
   In-app products → Create product**.
2. Type: **Managed product** (= non-consumable).
3. Product ID: must match exactly (`info.ilearnit.tier_basic`, etc).
4. Fill in name, description, default price.
5. Activate.
6. **Important — internal testing**:
   - The app must be published to at least the Internal testing track.
   - Add a test account to the tester list.
   - The package name signing the test build must match the published one
     (so `info.ilearnit.app` for prod). The dev flavor (`info.ilearnit.app.dev`)
     needs its own app entry in Play Console if you want to test there.
7. Install the build from the internal testing link on a real device
   (emulators usually don't have Play Billing).

## Server-side receipt verification (recommended)

The app currently trusts the platform's purchase stream. For production
you'll want a Cloud Function that:

1. Receives the receipt (`PurchaseDetails.verificationData.serverVerificationData`).
2. Calls Apple's `verifyReceipt` endpoint (or App Store Server API) /
   Google Play Developer API.
3. On success, writes `users/{uid}/purchases/{courseId}` server-side and
   the client only reads it.

That keeps a jailbroken client from forging an "owned" status by writing
to Firestore directly. The repo is already structured so this is an
isolated change: swap the client-side `upsertPurchase` in
`PurchasesRepositoryImpl.purchaseUpdates()` for a Cloud-Function call.

## Firestore security rules

Without server-side verification, lock writes to the purchases subcollection
behind a Cloud Function (preferred) **or** at minimum prevent the user from
toggling `status` themselves:

```javascript
match /users/{uid}/purchases/{courseId} {
  allow read: if request.auth.uid == uid;
  // Block client writes once the server-side verifier is wired up.
  allow write: if false;
}
```

## Smoke-test checklist

- [ ] Tap "Unlock for $X.XX" on a course → sandbox purchase sheet appears.
- [ ] Complete purchase → button changes to "Continue course".
- [ ] Force-kill the app, re-open → button still says "Continue".
- [ ] Sign out → button reverts to "Unlock" (Firestore stream emits empty).
- [ ] Sign back in → button shows "Continue" again.
- [ ] On a fresh install: Profile → "Restore purchases" → owned courses
      come back without re-paying.
- [ ] Disable network → Buy button is disabled / shows a clear error.
