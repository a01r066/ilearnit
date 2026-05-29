# Push Notifications — Setup & Deploy

iLearnIt uses **Firebase Cloud Messaging (FCM)** for transactional pushes (application approval, course enrollment) and admin-authored topic broadcasts. The send side runs on **Cloud Functions for Firebase** (TypeScript, under `functions/`). The client side is shared between the mobile app and the admin web portal.

## Architecture

```
┌─ Mobile app ──────────────────────────────────────────────────────────┐
│  bootstrap.dart                                                       │
│    ├─ FirebaseMessaging.onBackgroundMessage(handler)                  │
│    └─ container.read(notificationBootstrapProvider) ─┐                │
│                                                       │                │
│  NotificationBootstrap                                ▼                │
│    ├─ LocalNotificationsService.init()                                 │
│    ├─ FcmService.init()                                                │
│    │     • requestPermission                                           │
│    │     • subscribe `all_users`                                       │
│    │     • forward onMessage → local.show()                            │
│    │     • emit onMessageOpenedApp → taps stream                       │
│    └─ on auth user change:                                             │
│         • bindUser → users/{uid}.fcmTokens (arrayUnion)                │
│         • reconcileTopicsForUser(role, instrument)                     │
└────────────────────────────────────────────────────────────────────────┘

┌─ Admin portal (Flutter web) ──────────────────────────────────────────┐
│  bootstrap_admin.dart — same notification bootstrap                   │
│  AdminNotificationsPage → writes notification_broadcasts/{id}         │
└────────────────────────────────────────────────────────────────────────┘

┌─ Cloud Functions (functions/src/index.ts) ────────────────────────────┐
│  onApplicationDecision    Firestore trigger on                        │
│                            instructor_applications/{uid}              │
│                            status changes → sendToUser                │
│  onEnrollmentCreated      Firestore trigger on                        │
│                            enrollments/{id} → sendToUser              │
│  onNotificationBroadcast  Firestore trigger on                        │
│                            notification_broadcasts/{id} → sendToTopic │
│                                                                       │
│  All three speak the shared payload format documented below.          │
└────────────────────────────────────────────────────────────────────────┘
```

## Topic catalogue

Topics live in **two** places that must stay in sync — `lib/core/notifications/domain/notification_topics.dart` (client subscription) and `functions/src/index.ts` (server send).

| Topic | Who's on it | Used by |
|---|---|---|
| `all_users` | Every device on launch | Admin broadcasts (default target) |
| `instrument_guitar` / `_piano` / `_violin` | Users with matching `primaryInstrument` | Per-instrument announcements |
| `admins` | Users with `role: 'admin'` | Platform alerts |

The reconciler runs every time the auth user changes (`reconcileTopicsForUser`) — so updating `primaryInstrument` or promoting someone to admin automatically rebalances their topic subscriptions on the next session.

## Payload format

All pushes follow this shape so the client knows where to deep-link on tap:

```jsonc
{
  "notification": {
    "title": "You're approved!",
    "body": "You can now author courses…"
  },
  "data": {
    "type": "application_approved",     // discriminator
    "route": "/",                       // optional explicit deep-link
    "courseId": "<id>",                 // for enrollment pushes
    "broadcastId": "<id>"               // for broadcasts
  }
}
```

Client-side parsing lives in `NotificationPayload.fromData` and the discriminator enum is `NotificationType`. The router-level handler is `App._handleTap` (mobile) — falls back to a per-type default if `route` is absent.

## 1. Firebase project setup

Both dev and prod Firebase projects:

1. Firebase Console → Project settings → **Cloud Messaging** → confirm "Firebase Cloud Messaging API (V1)" is enabled.
2. The legacy "Server key" is no longer required — Functions use Application Default Credentials.

## 2. iOS — APNs key

Apple Push Notification service is the bridge between FCM and your iOS users.

1. Apple Developer → **Keys** → `+` → "Apple Push Notifications service (APNs)" → download the `.p8`.
2. Firebase Console → Project settings → **Cloud Messaging** → upload the `.p8` together with the Key ID and Team ID.
3. Xcode → Runner target → **Signing & Capabilities** → `+ Capability` → **Push Notifications**.
4. Same tab → `+ Capability` → **Background Modes** → enable **Remote notifications**.
5. Confirm your `Bundle Identifier` matches the App ID you enabled push on.

If you ship multiple flavors (Runner-Dev / Runner-Prod), repeat for each target.

## 3. Android

Most config comes through the `google-services.json` you already ship per flavor. Two extras:

1. **Android 13+ runtime permission**: handled automatically by `firebase_messaging.requestPermission()` — it prompts the user. Make sure your `android/app/src/main/AndroidManifest.xml` declares:

   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
   ```

2. **Default notification icon / color** (optional, but the default is a generic white square):

   ```xml
   <meta-data
     android:name="com.google.firebase.messaging.default_notification_icon"
     android:resource="@drawable/ic_notification" />
   <meta-data
     android:name="com.google.firebase.messaging.default_notification_color"
     android:resource="@color/notification_color" />
   ```

## 4. Cloud Functions — deploy

```bash
cd functions
npm install              # firebase-admin + firebase-functions + typescript
npm run build            # tsc → lib/
firebase deploy --only functions --project ilearnit-dev   # or -prod
```

The first deploy will prompt you to enable required Google Cloud APIs (Cloud Build, Cloud Run, Eventarc, etc.) — click through.

## 5. Firestore security rules

The admin `AdminNotificationsPage` writes to `notification_broadcasts/{id}`. The `enrollments/{id}` collection is written by the mobile app on IAP success. Add to `firestore.rules`:

```javascript
// ---------- enrollments ----------
match /enrollments/{enrollmentId} {
  allow read:   if isSignedIn() && (resource.data.userId == uid() || isAdmin());
  allow create: if isSignedIn() && request.resource.data.userId == uid();
  allow delete: if isAdmin();
}

// ---------- notification_broadcasts ----------
match /notification_broadcasts/{broadcastId} {
  allow read:  if isAdmin();
  allow create: if isAdmin()
    && request.resource.data.createdBy == uid()
    && request.resource.data.status == 'pending';
  allow update: if false;    // only the Function writes after creation
  allow delete: if isAdmin();
}

// ---------- users.fcmTokens (already covered) ----------
// The existing /users/{userId} rule lets users write their own fcmTokens
// because the client uses SetOptions(merge: true) on their own doc.
```

## 6. Smoke testing

1. **Run the mobile app**, sign in, accept the notification permission prompt. Check Firestore — `users/{uid}.fcmTokens` should contain one token.
2. **Trigger transactional**: sign in to the admin portal, approve a pending instructor application. The applicant's device should get a "You're approved!" push within ~5 s.
3. **Trigger broadcast**: in the admin portal go to **Notifications**, send to topic `all_users`. Any device on `all_users` (every device, after first launch) should receive it.
4. **Trigger enrollment**: complete an IAP purchase in the mobile app. Verify a doc lands in `enrollments/` and that the device receives the "You're enrolled" push.

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| No push on iOS device | APNs key not uploaded | Step 2 above |
| No push on Android 13+ device | Runtime permission denied | Settings → Notifications → enable for app |
| Push received but tap does nothing | `data.route` empty + no `type` match | Verify Cloud Function payload, see `App._handleTap` |
| `users/{uid}.fcmTokens` empty | `bindUser` ran before auth resolved | Should be fine on next session; if persistent, check `currentUserProvider` |
| `notification_broadcasts/{id}` stuck on `status: pending` | Cloud Function not deployed | Run `firebase deploy --only functions` |
| `messaging/registration-token-not-registered` errors in logs | Stale token left after uninstall | Functions auto-prune via `arrayRemove` — wait one cycle |
| Push works on debug build but not release on iOS | APNs production environment | Confirm in Xcode that `aps-environment` is `production` |

## 8. Files

- Client
  - `lib/core/notifications/domain/notification_topics.dart`
  - `lib/core/notifications/domain/notification_payload.dart`
  - `lib/core/notifications/data/local_notifications_service.dart`
  - `lib/core/notifications/data/fcm_service.dart`
  - `lib/core/notifications/presentation/notification_providers.dart`
  - `lib/bootstrap.dart` / `lib/bootstrap_admin.dart` (hooks)
  - `lib/app/app.dart` / `lib/admin/admin_app.dart` (tap router)
- Admin UI
  - `lib/admin/notifications/data/notification_broadcast_datasource.dart`
  - `lib/admin/notifications/presentation/admin_notifications_page.dart`
  - `lib/admin/routing/admin_route_names.dart` + `admin_router.dart`
- Cloud Functions
  - `functions/package.json`, `functions/tsconfig.json`, `functions/.gitignore`
  - `functions/src/index.ts`
- Docs
  - `docs/push_notifications.md` (this file)
