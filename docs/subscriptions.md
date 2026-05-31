# Subscriptions — Personal Plan

iLearnIt ships an **auto-renewing subscription** ("Personal Plan") that unlocks every course on the platform. It coexists with per-course IAP — non-subscribers can still buy individual courses through the existing `PriceTier` flow.

## Architecture

```
Profile → Subscription → Checkout
                            │ tap Start subscription
                            ▼
SubscriptionNotifier.buy(plan)
   └─ IapRemoteDataSource.buyNonConsumable(productId)
        ▼ (purchaseStream emits purchased | restored)
SubscriptionNotifier._onPurchaseUpdates
   ├─ filter to SubscriptionPlan product ids
   └─ SubscriptionFirestoreDataSource.recordPurchase
        → users/{uid}.subscription = {
            planId, productId, startedAt, expiresAt, autoRenew,
            platform, originalTransactionId
          }
        ▼ (live stream)
SubscriptionNotifier.state.status updates → UI flips to "active"
        ▼
hasActiveSubscriptionProvider → hasUnlockedAccessProvider(courseId)
        → BuyCourseButton renders "Continue course" instead of "Unlock for $X"
```

Trust model: **client writes the entitlement after a successful purchase.** Firestore rules let users write their *own* subscription map. A future server-side verifier would replace `recordPurchase` with a callable function that validates the App Store / Play Store receipt.

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

The mobile app writes to `users/{uid}.subscription`. Add to your existing user rule:

```javascript
match /users/{userId} {
  // ... existing rules ...

  // Allow the owner to write their own subscription map. Admins can write
  // any user's subscription (for support / refunds).
  allow update: if isSignedIn()
    && uid() == userId
    && request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['subscription', 'fcmTokens']);
}
```

This carves out a narrow allow-rule so users can't sneak edits to `role` or `email` while touching `subscription`.

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
    "originalTransactionId": "GPA.xxxx-xxxx-xxxx-xxxxx"
  }
}
```

The client treats `isActive` as `expiresAt > now` — auto-renew off but still in the paid period counts as active.

## 5. Course gate integration

`hasUnlockedAccessProvider(courseId)` returns `true` if **either** the user has bought the course individually **or** has an active subscription. `BuyCourseButton` reads this — when the user has a subscription it shows "Continue course" + a small "Included in your Personal Plan" affordance under the CTA.

The per-course purchase flow continues to work for users without a subscription — nothing else changed.

## 6. Smoke testing

1. Configure sandbox tester accounts (App Store Connect → Users → Sandbox Testers; Play Console → License Testing).
2. Run mobile app, sign in.
3. Profile → Subscription → Start subscription → choose Yearly → Start.
4. The store sheet appears; sign in with the sandbox account and confirm.
5. Within ~5 s the page should re-render with the active card. Check Firestore → `users/{uid}` for the `subscription` map.
6. Navigate to a paid course → BuyCourseButton should show "Continue course" + "Included in your Personal Plan" caption.
7. Cancel the subscription in the OS settings (Settings → Apple ID → Subscriptions on iOS) and confirm the next launch reflects `autoRenew: false` after the store re-emits the purchase.

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| "Product not available" snackbar | SKUs not approved yet (iOS) | Wait for App Review or use sandbox |
| Prices show fallback only | `fetchProducts` failed silently | Check device locale supports the SKU; check store config |
| Subscription unlocks but reverts on relaunch | Firestore write was denied | Check rule allows owner write on `subscription` field |
| Restored purchase doesn't unlock UI | `_persistEntitlement` ran with `null` user | Sign in first, then tap Restore from Profile |
| "Continue course" never appears after purchase | `subscriptionNotifierProvider` not eagerly read | Verify `bootstrap.dart` reads it |

## 8. Files

- Domain
  - `lib/features/subscriptions/domain/entities/subscription_plan.dart`
  - `lib/features/subscriptions/domain/entities/subscription_status.dart`
- Data
  - `lib/features/subscriptions/data/models/subscription_model.dart`
  - `lib/features/subscriptions/data/datasources/subscription_firestore_datasource.dart`
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
