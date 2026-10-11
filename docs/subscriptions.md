# Subscriptions — Personal Plan

iLearnIt ships an **auto-renewing subscription** ("Personal Plan") that unlocks every course on the platform. It coexists with per-course IAP — non-subscribers can still buy individual courses through the existing `PriceTier` flow.

## Architecture

```
Profile → Subscription → Checkout
                            │ tap Start subscription
                            ▼
SubscriptionNotifier.buy(plan)
   └─ IapRemoteDataSource.buyNonConsumable(productId)   // in_app_purchase uses
        ▼ (purchaseStream emits purchased | restored)   // this call for subs
SubscriptionNotifier._onPurchaseUpdates
   ├─ filter to SubscriptionPlan product ids
   └─ PurchaseVerificationDataSource.verifySubscription(p)
        → Cloud Function `verifySubscription` (functions/src/iap.ts)
            iOS:     App Store Server API — Get All Subscription Statuses
            Android: Play Developer API — purchases.subscriptionsv2
            binds the store subscription to ONE uid (_iap_subscriptions/{hash})
            writes users/{uid}.subscription (Admin SDK)
        ▼ only after the server answers → completePurchase(p)
SubscriptionFirestoreDataSource.watch(uid)  (read-only live stream)
        ▼
SubscriptionNotifier.state.status → hasActiveSubscriptionProvider
        → hasUnlockedAccessProvider(courseId) → BuyCourseButton shows "Continue course"
```

**Trust model: the server writes the entitlement.** `firestore.rules`
forbid clients from creating or changing `users/{uid}.subscription`; only
`verifySubscription` and the store notification handlers (Admin SDK) write
it. The client never computes `expiresAt` — it comes from the store.

**Renewals, cancellations, refunds** reach the server without the app being
open through store notifications (`functions/src/storeNotifications.ts`):

- `appStoreNotifications` — App Store Server Notifications v2 (HTTPS). The
  signed payload is verified to Apple's root CA, then the latest status is
  re-read with the App Store Server API.
- `playRtdn` — Google Play Real-time Developer Notifications (Pub/Sub topic
  `play-billing`). State is re-read from `subscriptionsv2`; upgrades carry
  the account binding over via `linkedPurchaseToken`.

A refund / revocation sets `expiresAt` to now and `autoRenew: false`.
Setup steps for both are in `docs/iap_setup.md` → "Server notifications".

**Cancel from the app**: `SubscriptionNotifier.openManageSubscription()`
opens the App Store / Play subscription page. The store tells the server
(`autoRenew` flips to false via the notification); the app never writes it.

## Plans

Two SKUs, both auto-renewing subscriptions on the same subscription group:

| Plan | Product ID | Period | Default VND | Default USD |
|---|---|---|---|---|
| Monthly | `info.ilearnit.personal_monthly` | 1 month | ₫800.000 | $9.99 |
| Yearly | `info.ilearnit.personal_yearly` | 12 months | ₫3.000.000 | $79.99 |

Fallback prices are shown until the platform returns localized `ProductDetails` — once that lands, the in-memory `priceByProductId` map overrides everything on screen.

Locale switch: VND for `vi`, USD for `en` (and any other locale by default). Configured in `SubscriptionPlan.fallbackLabelFor(localeCode)`.

## 1. App Store Connect

1. App Store Connect → your app → **In-App Purchases**.
2. Create an **Auto-Renewable Subscription Group** called `Personal Plan` (any name; the group is what makes the two SKUs upgrade/downgrade between each other).
3. Inside the group, create two subscriptions:
   - `info.ilearnit.personal_monthly` — 1 Month duration
   - `info.ilearnit.personal_yearly` — 1 Year duration
4. Set the **localized prices** in every market you ship to. The Vietnamese App Store needs VND, the US store needs USD, etc.
5. Fill in localized **display name** + **description** for each subscription.
6. Submit the subscription group for review the **same time** as your first build that contains the subscription code — App Review evaluates them together.

## 2. Google Play Console

1. Play Console → your app → **Monetize → Subscriptions**.
2. Create one subscription with **two base plans**:
   - Base plan `monthly` → 1 month, auto-renewing, with offer matching the iOS price.
   - Base plan `yearly` → 1 year, auto-renewing, yearly price.
3. Set per-region prices (VND for VN, USD for US, etc.).
4. Make sure the **product IDs** match the iOS ones: `info.ilearnit.personal_monthly` and `info.ilearnit.personal_yearly`. (Play allows different naming, but matching them keeps the Dart code simple — one `productId` constant works for both stores.)

## 3. Firestore rules

`users/{uid}.subscription` is server-owned. From `firestore.rules`:

```javascript
match /users/{userId} {
  // New accounts can't arrive with privileges or a subscription.
  allow create: if isSignedIn()
    && uid() == userId
    && request.resource.data.get('role', 'student') == 'student'
    && request.resource.data.get('isSuspended', false) == false
    && !('subscription' in request.resource.data);

  // Owners may edit their profile, never role / isSuspended / subscription.
  allow update: if isSignedIn()
    && uid() == userId
    && !(request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['role', 'isSuspended', 'subscription']));
}

// Account binding for store subscriptions — server-only.
match /_iap_subscriptions/{id} { allow read, write: if false; }
```

## 4. Sample doc shape

```jsonc
// users/abc123
{
  "id": "abc123",
  "email": "thanh@example.com",
  "role": "student",
  "subscription": {
    "planId": "yearly",                                  // "monthly" | "yearly"
    "productId": "info.ilearnit.personal_yearly",
    "startedAt": "2026-05-30T10:23:14Z",
    "expiresAt": "2027-05-30T10:23:14Z",
    "autoRenew": true,
    "canceledAt": null,
    "platform": "ios",
    "originalTransactionId": "2000000123456789",   // iOS original txn id / Play purchase token
    "verifiedAt": "2026-05-30T10:23:20Z"           // last server verification
  }
}
```

The client treats `isActive` as `expiresAt > now` — auto-renew off but still in the paid period counts as active. Server checks (`hasCourseAccess` in `functions/src/iap.ts`, the reviews rule in `firestore.rules`) use the same definition.

## 5. Course gate integration

`hasUnlockedAccessProvider(courseId)` returns `true` if **either** the user has bought the course individually **or** has an active subscription. `BuyCourseButton` reads this — when the user has a subscription it shows "Continue course" + a small "Included in your Personal Plan" affordance under the CTA.

The per-course purchase flow continues to work for users without a subscription — nothing else changed.

## 6. Smoke testing

1. Configure sandbox tester accounts (App Store Connect → Users → Sandbox Testers; Play Console → License Testing).
2. Run mobile app, sign in.
3. Profile → Subscription → Start subscription → choose Yearly → Start.
4. The store sheet appears; sign in with the sandbox account and confirm.
5. Within a few seconds the page should re-render with the active card. Check Firestore → `users/{uid}.subscription` (note `verifiedAt`) and the `verifySubscription` logs.
6. Navigate to a paid course → BuyCourseButton should show "Continue course" + "Included in your Personal Plan" caption.
7. Cancel the subscription in the store (Settings → Apple ID → Subscriptions on iOS). The store notification should flip `autoRenew` to `false` within minutes (sandbox) — check the `appStoreNotifications` / `playRtdn` logs.
8. Try the same store account with a second iLearnIt account → verification fails with "linked to another iLearnIt account".

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| "Product not available" snackbar | SKUs not approved yet (iOS) | Wait for App Review or use sandbox |
| Prices show fallback only | `fetchProducts` failed silently | Check device locale supports the SKU; check store config |
| "We could not confirm your subscription" | `verifySubscription` failed | Check function logs: Apple secrets / `APPLE_APP_ID` / root certs, or Play service-account permissions |
| "Linked to another iLearnIt account" | Store subscription already bound to a different uid | Expected — one store subscription per account. Support can delete the `_iap_subscriptions` doc to re-bind |
| Renewal / cancel not reflected | Store notifications not configured | Register the Apple URL + Play RTDN topic (docs/iap_setup.md) |
| Restored purchase doesn't unlock UI | No signed-in user when the stream emitted | Sign in, then tap Restore purchases in Profile (transaction stays open until verified) |
| "Continue course" never appears after purchase | `subscriptionNotifierProvider` not eagerly read | Verify `bootstrap.dart` reads it |

## 8. Files

- Domain
  - `lib/features/subscriptions/domain/entities/subscription_plan.dart`
  - `lib/features/subscriptions/domain/entities/subscription_status.dart`
- Data
  - `lib/features/subscriptions/data/models/subscription_model.dart`
  - `lib/features/subscriptions/data/datasources/subscription_firestore_datasource.dart` (read-only)
  - `lib/features/purchases/data/datasources/purchase_verification_datasource.dart` (calls the verifiers)
- Server
  - `functions/src/iap.ts` (`verifySubscription`, `applySubscription`)
  - `functions/src/store/apple.ts`, `functions/src/store/google.ts`
  - `functions/src/storeNotifications.ts` (`appStoreNotifications`, `playRtdn`)
- State + providers
  - `lib/features/subscriptions/presentation/providers/subscription_state.dart`
  - `lib/features/subscriptions/presentation/providers/subscription_notifier.dart`
  - `lib/features/subscriptions/presentation/providers/subscription_providers.dart`
- UI
  - `lib/features/subscriptions/presentation/pages/subscription_page.dart`
  - `lib/features/subscriptions/presentation/pages/subscription_checkout_page.dart`
- Integrations
  - `lib/features/purchases/presentation/providers/purchases_providers.dart` (added `hasUnlockedAccessProvider`)
  - `lib/features/purchases/presentation/widgets/buy_course_button.dart` (subscription bypass)
  - `lib/features/profile/presentation/pages/profile_page.dart` (Subscription tile)
  - `lib/core/routing/{route_names,app_router}.dart`
  - `lib/bootstrap.dart` (eager init)
- i18n
  - `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
  - `lib/l10n/generated/app_localizations*.dart` (patched)
- Docs
  - `docs/subscriptions.md` (this file)
