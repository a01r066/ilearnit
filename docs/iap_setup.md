# In-App Purchases — store setup

The app uses three flat price tiers instead of one SKU per course. Each
course's `priceTier` field maps to one of these products:

| Tier      | Product ID                       | Suggested price (USD) |
| --------- | -------------------------------- | --------------------- |
| basic     | `info.ilearnit.course_tier_basic`       | $9.99                 |
| standard  | `info.ilearnit.course_tier_standard`    | $19.99                |
| premium   | `info.ilearnit.course_tier_premium`     | $39.99                |

All three are **consumable**. One tier product is shared by many courses,
and a non-consumable can only be bought once per store account, so the
store can't be the source of truth for ownership. Instead the
`verifyPurchase` Cloud Function (functions/src/iap.ts) validates each
transaction and writes `users/{uid}/purchases/{courseId}`; ownership
follows the iLearnIt account across devices. On Android the server
consumes the Play token after granting.

> Product types can't be changed after creation. If the old
> `info.ilearnit.tier_*` non-consumables exist in the consoles, leave
> them inactive and create the new `course_tier_*` consumables.

## iOS — App Store Connect

1. Sign in at https://appstoreconnect.apple.com.
2. App → **iLearnIt** → **Features → In-App Purchases → +**.
3. Pick **Consumable**. Create each of the three product IDs above.
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
2. Type: **In-app product** (consumed server-side after verification).
3. Product ID: must match exactly (`info.ilearnit.course_tier_basic`, etc).
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

## Server-side verification

Implemented in `functions/src/iap.ts` (+ `store/apple.ts`, `store/google.ts`):

- `createPurchaseIntent` — records the course before the store sheet opens.
- `verifyPurchase` — course tiers. iOS: App Store Server API *Get
  Transaction Info* (JWS verified to Apple's root CA). Android: Play
  `purchases.products`. Idempotent per store transaction, checks the paid
  tier equals the course's `priceTier`, consumes Play tokens.
- `verifySubscription` — Personal Plan. iOS: *Get All Subscription
  Statuses*; Android: `purchases.subscriptionsv2`. Binds a store
  subscription to one account.
- `appStoreNotifications` / `playRtdn` (`storeNotifications.ts`) — renewals,
  expirations, refunds and revocations applied without the app open.

### Configuration

Secrets:

```
firebase functions:secrets:set APPLE_IAP_KEY_ID        # In-App Purchase key id
firebase functions:secrets:set APPLE_IAP_ISSUER_ID     # App Store Connect issuer id
firebase functions:secrets:set APPLE_IAP_PRIVATE_KEY   # contents of the .p8 file
firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT   # full JSON key
```

- Apple key: App Store Connect → Users and Access → Integrations →
  In-App Purchase → generate key (download the .p8 once).
- Play service account: Play Console → Users and permissions → invite
  the account with "View financial data" + "Manage orders and subscriptions".

Params (non-secret) live in `functions/.env.dev` / `functions/.env.prod`:
`ANDROID_PACKAGE_NAME`, `APPLE_BUNDLE_ID`, `APPLE_APP_ID` (numeric Apple
ID — required to verify Production data).

Apple root certificates: put `AppleRootCA-G3.cer`, `AppleRootCA-G2.cer`,
`AppleIncRootCertificate.cer` in `functions/certs/` (see README there).

### Server notifications

- **Apple**: App Store Connect → App → App Information → App Store Server
  Notifications → Version 2, Production and Sandbox URLs =
  `https://<region>-<project>.cloudfunctions.net/appStoreNotifications`
  (or the Cloud Run URL shown after deploy).
- **Google**: create Pub/Sub topic `play-billing`; grant
  `google-play-developer-notifications@system.gserviceaccount.com` the
  *Pub/Sub Publisher* role on it; Play Console → Monetization setup →
  Real-time developer notifications → topic
  `projects/<project>/topics/play-billing`. Use "Send test notification".
