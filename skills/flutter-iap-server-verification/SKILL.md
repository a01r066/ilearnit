---
name: flutter-iap-server-verification
description: Design and implement in-app purchases for a Flutter app (in_app_purchase plugin) with server-side verification in Firebase Cloud Functions — consumable price tiers, non-consumables, auto-renewable subscriptions, App Store Server API + JWS verification, Google Play Developer API, purchase intents, idempotent grants, Play consumption, restore, refunds via App Store Server Notifications v2 and Play RTDN. Use this skill whenever the user wants to sell anything inside a mobile app (courses, content packs, premium, subscriptions, unlocks), touches purchase/receipt/entitlement code, sets up products in App Store Connect / Play Console, or asks why purchases are lost, duplicated or not restored — even if they don't say "server verification".
---

# Flutter IAP with server verification

**Rule zero:** the app never grants itself anything. The client buys,
hands the store's proof to a callable, and the server — after asking
Apple/Google — writes the entitlement. Firestore rules deny client
writes to entitlement paths (`firebase-backend-security`).

Templates (copy, then rename `items` / `com.example.app.` to your domain):

| File | Purpose |
|---|---|
| `templates/functions/src/iap.ts` | catalogue, `createPurchaseIntent`, `verifyPurchase` (tiers), `verifyNonConsumable`, `verifySubscription`, `applySubscription`, `revokePurchase` |
| `templates/functions/src/store/apple.ts` | App Store Server API client + `SignedDataVerifier` (env fallback Production → Sandbox) |
| `templates/functions/src/store/google.ts` | Play Developer API (service-account JWT, no extra deps) |
| `templates/functions/src/store_notifications.ts` | `appStoreNotifications` (ASSN v2), `playRtdn` (Pub/Sub) |
| `templates/functions/src/app_check.ts` | `requireAppCheck` |
| `templates/functions/env.example`, `certs/README.md` | params, secrets, Apple root certs |
| `templates/lib/purchase_verification_datasource.dart` | callable client + retryable error classification |
| `templates/lib/purchase_stream_handler.dart` | the purchase-stream state machine for consumable tiers |

Store console setup, testing and go-live: `references/store_setup.md`.

## 1. Pick the product model first

| You sell | Product type | Why |
|---|---|---|
| Many items at a few price points (courses, lessons, packs) | **Consumable tiers** `…tier_basic/standard/premium`, shared by all items | Store catalogues can't hold thousands of products; tiers keep review simple. Needs an intent to map payment → item and server-side consume. |
| A handful of permanent unlocks (songbooks, "pro" unlock, themes) | **Non-consumable** per item `…item.<id>` | Store restores it; key it by iOS `originalTransactionId` / Play token. |
| Access to everything for a period | **Auto-renewable subscription** | Bind one store subscription chain to one account. |

Consumables are not restored by StoreKit, so **ownership must live on the
account server-side** — that's also what makes access follow the user
across devices and platforms.

## 2. Consumable tier flow

```
tap Buy ─▶ createPurchaseIntent(itemId)
             server: item published? not owned? → productId from item.priceTier
             writes purchase_intents/{uid}_{productId}
        ─▶ buyConsumable(productId, autoConsume: false, applicationUserName: uid)
        ─▶ purchaseStream: purchased
        ─▶ verifyPurchase({platform, productId, transactionId, receipt, itemId hint})
             1. ask the store (no writes on failure)
             2. itemId = hint ?? intent
             3. Firestore txn: _iap_transactions/{sha(platform:txnKey)} sentinel
                (same uid or reject; refunded → reject; replay → alreadyGranted)
                tier paid == item tier? → purchase doc + ledger (or 'duplicate')
             4. Android: consume token server-side
        ─▶ client: completePurchase unless server consumed
```

Why each piece exists:

- **Server-chosen product**: a stale or modified client can't pay the
  basic tier for a premium item; the grant re-checks it.
- **Intent**: if the app dies between payment and verification, the
  re-delivered transaction carries no item id — the intent supplies it.
- **Sentinel keyed by store transaction id**: makes verification
  idempotent and binds a payment to exactly one account (no replaying a
  receipt on a second account).
- **Consume after grant, on the server**: if the client consumed first
  and verification failed, the user paid for nothing and the token is gone.
- **`unassigned` records**: a valid payment with no item is kept for
  support instead of being silently lost.

## 3. Client purchase-stream rules

Encoded in `purchase_stream_handler.dart`:

1. Subscribe to `purchaseStream` **once, at startup** (eager provider in
   bootstrap). Each handler skips product ids it doesn't own.
2. `pending` → show waiting; don't complete.
3. `canceled` / `error` → `completePurchase` (iOS keeps failed transactions
   queued and they block re-buying).
4. `purchased` / `restored` → wait for `authStateChanges().first` on cold
   start; if signed out, leave the transaction open.
5. Verify. Success → complete (skip on Android if server consumed).
   Retryable error (`unavailable`, `internal`, `unauthenticated`,
   `deadline-exceeded`) → leave **open** so it replays. Permanent error →
   iOS complete (avoid infinite loop), Android leave unacknowledged (Play
   auto-refunds after 3 days).
6. UI reads ownership from Firestore (`users/{uid}/purchases`), never from
   the purchase event.
7. Require sign-in before purchase (App Review allows this for
   account-bound content); guests see the price and a "Sign in to buy" CTA.

## 4. Non-consumables

- `verifyNonConsumable` maps product → item from **your** data
  (`items where productId == …`), keys the sentinel by the stable id, and
  is idempotent so "Restore purchases" just re-runs it.
- Show a **Restore purchases** button (App Review 3.1.1 requires it when
  you sell restorable products).

## 5. Subscriptions

- `verifySubscription`: iOS → *Get All Subscription Statuses* by any
  transaction id; Android → `subscriptionsv2.get`. Bind
  `originalTransactionId`/token → uid in `_iap_subscriptions` (reject a
  second account). Write `users/{uid}.subscription` with `expiresAt`.
- Access check everywhere is just `subscription.expiresAt > now`
  (server: `hasAccess`; rules: `hasActiveSubscription()`).
- Renewals, expiry, refunds arrive via notifications (§6) — don't rely on
  the app being opened.
- Paywall must show price, period, trial terms, auto-renew text, links to
  Terms and Privacy, and a manage-subscription link (App Review 3.1.2).

## 6. Store notifications

- **Apple ASSN v2** → `appStoreNotifications` (HTTPS). The body is
  unauthenticated: verify the JWS with `SignedDataVerifier` and Apple root
  certs before trusting it. For subscriptions, re-read the latest status
  rather than trusting one (possibly out-of-order) notification. REFUND /
  REVOKE → `revokePurchase` or `revoked: true`.
- **Play RTDN** → Pub/Sub topic → `playRtdn`. Messages carry only a token;
  re-read state from the Play API. `linkedPurchaseToken` carries the uid
  binding across upgrades. `voidedPurchaseNotification` → revoke.
- Return 5xx on processing errors so Apple retries; both handlers must be
  idempotent.

## 7. Configuration checklist

- Secrets: `APPLE_IAP_KEY_ID`, `APPLE_IAP_ISSUER_ID`,
  `APPLE_IAP_PRIVATE_KEY` (.p8 contents), `GOOGLE_PLAY_SERVICE_ACCOUNT`
  (JSON; grant the account *View financial data* + *Manage orders* in
  Play Console).
- Params in `functions/.env.<alias>`: `APPLE_BUNDLE_ID`, `APPLE_APP_ID`
  (numeric; required to verify Production data), `ANDROID_PACKAGE_NAME`.
- `functions/certs/AppleRootCA-G3.cer` (+ G2).
- `npm i @apple/app-store-server-library`.
- Product ids identical in: App Store Connect, Play Console, server
  catalogue, client constants. Keep one source list and grep for drift.

## 8. Testing matrix

Sandbox/TestFlight + Play license testers: buy each tier; kill the app
mid-purchase and relaunch; buy while signed out; buy on account A then
replay on account B (must reject); refund (Apple: sandbox refund request;
Play: Order management → refund) and confirm access is revoked; restore
non-consumables on a fresh install; subscription renew/expire with
accelerated sandbox time; Ask to Buy (pending).
