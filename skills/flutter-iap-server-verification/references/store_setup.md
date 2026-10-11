# Store setup and go-live

## App Store Connect
1. Agreements, Tax, and Banking → Paid Apps agreement **active** (products
   stay "Missing Metadata"/unavailable otherwise).
2. App → Monetization → In-App Purchases: create consumable tiers /
   non-consumables; Subscriptions: one group, monthly + yearly, same
   level. Each needs a localized display name, description, price and a
   review screenshot.
3. Users and Access → Integrations → In-App Purchase → generate key →
   download `.p8` once; note Key ID + Issuer ID → Functions secrets.
4. App Information → App Store Server Notifications → Production and
   Sandbox URL = `appStoreNotifications` URL, Version 2.
5. First IAPs must be submitted **with** an app version.
6. Sandbox testers: Users and Access → Sandbox. Subscriptions renew on
   an accelerated schedule.

## Google Play Console
1. Payments profile + merchant account.
2. Upload an AAB with the `com.android.vending.BILLING` permission
   (the plugin adds it) to any track before products can be created.
3. Monetize → Products → In-app products (tiers / non-consumables);
   Subscriptions with base plans.
4. Google Cloud: create a service account; Play Console → Users and
   permissions → invite it with *View financial data* and *Manage orders
   and subscriptions*. JSON → `GOOGLE_PLAY_SERVICE_ACCOUNT` secret.
   Permissions can take up to 24 h to propagate (401/403 meanwhile).
5. Pub/Sub topic `play-billing`; grant
   `google-play-developer-notifications@system.gserviceaccount.com`
   Publisher; Monetization setup → Real-time developer notifications →
   topic; "Send test notification".
6. License testers: Setup → License testing (test cards, fast renewals).

## Common failures
- iOS products empty → agreement not active, bundle id mismatch, or
  product not "Ready to Submit".
- Android "item unavailable" → app not installed from Play (internal
  track) or tester not opted in.
- `verifyPurchase` 404 from Apple in dev → `APPLE_APP_ID` empty means
  Sandbox only (expected); production TestFlight builds verify in Sandbox.
- Play 401 → service account not invited / not propagated.
- Purchases stuck → client completing before verification, or not
  completing failed transactions.
