# Notifications Inbox + Preferences

Implements **P1-4** from `docs/go_live_roadmap.md` — an in-app inbox so
users who disable OS notifications still see their account-related events,
plus per-topic toggles in Settings.

---

## 1. Why an in-app inbox?

System push is the *delivery* channel, not the *record*. If the user
disables OS notifications (or the push is lost in transit, or they
dismiss the banner), the event is gone forever. We mirror every 1:1 push
into `users/{uid}/notifications/{id}` so the app can show a persistent
list — same content, same tap target.

This also unblocks future product moves:
- Marking notifications as read once seen in-app.
- "What did I miss" pages for inactive users.
- Per-channel preferences (push vs. inbox vs. email) without touching the
  send pipeline.

---

## 2. Data model

```
users/{uid}/notifications/{notificationId}
  ├── type           string  (NotificationType.id — application_approved | …)
  ├── title          string
  ├── body           string
  ├── payload        map     ({ type, route, courseId, … } — same as FCM data)
  ├── readAt         timestamp?  (null while unread)
  └── createdAt      timestamp   (server-side)

users/{uid}
  └── subscribedTopics  array<string>  (mirror of FCM subscriptions)
```

### Why `subscribedTopics` on the user doc?

The FCM SDK doesn't expose a "list my topics" API — subscriptions are
write-only from the client. We mirror them on the user doc so:
1. The Settings page can render the right switch state without an extra
   round-trip.
2. The state survives reinstalls — FCM token rotation would otherwise
   stop pushes silently.
3. A future Cloud Function can re-reconcile subscriptions on token
   refresh by reading the mirror.

---

## 3. Architecture

```
Cloud Function trigger
       │
       ▼ notifyUser(uid, notification, data)
  ┌────────────┬───────────────┐
  │ sendToUser │ writeInbox    │   (Promise.all — fire in parallel)
  └────────────┴───────────────┘
       │              │
       ▼              ▼
   FCM device   users/{uid}/notifications/{id}
                       │
                       ▼ live snapshot
              NotificationsInboxDataSource.watchInbox
                       │
                       ▼
              notificationsInboxProvider (StreamProvider)
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   NotificationBell  NotificationsInboxPage
   (unread badge)    (list + mark read + clear)
```

Topic preferences flow:

```
SwitchListTile toggled
       │
       ▼
TopicTogglesNotifier.setSubscribed(topic, true/false)
       │
       ▼ FCM first (so errors surface before we lie in Firestore)
       │  ↳ NotificationPreferencesDataSource.subscribe / unsubscribe
       │
       ▼ then mirror
       │  users/{uid}.subscribedTopics arrayUnion / arrayRemove
       │
       ▼ stream re-emits with new state
       UI re-renders with updated switch positions
```

---

## 4. Files added

| Path | Role |
|---|---|
| `lib/core/notifications/domain/notification_item.dart` | Freezed entity + `isUnread` / `route` getters |
| `lib/core/notifications/data/models/notification_item_model.dart` | Freezed + JsonSerializable model with `fromDoc` |
| `lib/core/notifications/data/datasources/notifications_inbox_datasource.dart` | watchInbox, watchUnreadCount, markRead, markAllRead, delete, clearAll |
| `lib/core/notifications/data/datasources/notification_preferences_datasource.dart` | watchSubscribedTopics, subscribe, unsubscribe |
| `lib/core/notifications/presentation/inbox_providers.dart` | Datasources + stream providers + `TopicTogglesNotifier` |
| `lib/core/notifications/presentation/widgets/notification_bell.dart` | Bell IconButton + unread-count badge |
| `lib/core/notifications/presentation/pages/notifications_inbox_page.dart` | List + relative date + swipe-to-dismiss + overflow menu |
| `lib/core/notifications/presentation/pages/notification_preferences_page.dart` | SwitchListTile per topic with busy state |
| `docs/notifications_inbox.md` | This file |

## 5. Files changed

- `lib/core/routing/route_names.dart` + `app_router.dart` —
  `/notifications` registered top-level (above the shell so the bell on
  every tab pushes a consistent modal). Preferences nested under
  `/profile/settings/notifications`.
- `lib/features/profile/presentation/pages/settings_page.dart` — new
  "Notifications" row between Language and Legal.
- `lib/features/home/presentation/pages/home_page.dart` + Songbooks page
  — replaced placeholder bell buttons with the live
  `NotificationBell`.
- `firestore.rules` — owner-only read + delete + `readAt`-only update on
  `users/{uid}/notifications/{id}`. Creates are server-only (Cloud
  Functions write via Admin SDK).
- `functions/src/index.ts` — added `writeInbox` helper + `notifyUser`
  wrapper. Both 1:1 triggers (`onApplicationDecision`,
  `onEnrollmentCreated`) now mirror their pushes into the inbox.
- `lib/l10n/app_en.arb`, `app_vi.arb` + generated localizations — 14 new
  keys.

## 6. Broadcast triggers — why no inbox mirror yet

Topic broadcasts can't enumerate recipients at send-time — FCM does the
fan-out server-side. To mirror a broadcast into 10 000 inboxes we'd need
either:
- A separate Cloud Function that walks `users where subscribedTopics
  arrayContains topic`, batching 200 writes per request — costs ~100ms
  per chunk and one Firestore read + one Firestore write per recipient.
- Aurora-style "send to me" fan-out where each device writes its own
  inbox doc on first display — but that misses recipients who weren't
  active when the push went out.

For v1 we accept the limitation: broadcasts land as a push toast only.
Account-related (1:1) events make up the bulk of "things you'd miss",
and those are covered. Filed as future work.

## 7. Security rules

```firestore
match /users/{userId}/notifications/{notificationId} {
  allow read: if isSignedIn() && uid() == userId;
  allow update: if isSignedIn()
    && uid() == userId
    && request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['readAt']);
  allow delete: if isSignedIn() && uid() == userId;
  allow create: if false;   // server-only
}
```

The `affectedKeys().hasOnly(['readAt'])` carve-out prevents a malicious
client from rewriting a notification's title/body/payload — they can
only mark it read.

## 8. Testing checklist

| Scenario | Expected |
|---|---|
| Cloud Function fires `notifyUser` | FCM push delivered AND `users/{uid}/notifications/{id}` row created |
| Open Home with unread items | Bell shows red badge with count |
| Tap bell | Inbox page opens, items sorted newest-first |
| Tap an unread item | `readAt` stamped server-side; badge decrements; routed to `data.route` |
| Swipe an item right-to-left | Item deleted; badge decrements |
| Tap "Mark all as read" | All items read; badge → 0 |
| Tap "Clear all" → Confirm | Inbox emptied |
| Settings → Notifications | Switches reflect current subscriptions; loading spinner shows during FCM call |
| Toggle a topic OFF | `FcmService.unsubscribeFromTopic` + `users/{uid}.subscribedTopics` arrayRemove |
| Toggle a topic ON | Reverse — FCM subscribe + arrayUnion |
| FCM call fails | Snackbar; switch stays in old position; mirror not updated |
| Sign out | Inbox stream + badge stream emit empty + 0 |
| Sign in as different user | Streams re-subscribe under new uid |

## 9. Required follow-up

- `firebase deploy --only functions` (rebuilds Cloud Function with the
  inbox mirror).
- `firebase deploy --only firestore:rules` (publishes the new
  `notifications` subcollection rule).
- Run `flutter pub get` then
  `dart run build_runner build --delete-conflicting-outputs` to
  regenerate `notification_item_model.freezed.dart` + `.g.dart`.

## 10. Future work

- Broadcast inbox fan-out (see §6).
- Server-side notification grouping ("3 new enrollments today").
- Notification grouping by date sections in the inbox UI.
- "Snooze for a day" overflow action per item.
- Push preferences split out from inbox preferences — currently both are
  controlled by the same topic toggles, but a user might want to
  receive inbox-only updates without push wake-ups.
