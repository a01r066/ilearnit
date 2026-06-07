# Wishlist ("Saved courses")

Implements **P2-2** from `docs/go_live_roadmap.md` — bookmark courses for
later + email/push the user when a saved course gets cheaper.

---

## 1. Data model

```
users/{uid}/wishlist/{courseId}
  ├── courseId         string  (denormalized — equals doc id)
  ├── title            string  (denormalized course title)
  ├── thumbnailUrl     string? (denormalized)
  ├── instructorName   string  (denormalized)
  ├── priceTier        string  ('basic' | 'standard' | 'premium')
  └── savedAt          timestamp  (server-side)
```

### Why doc id == course id?

Toggle / dedup is the hot path. Reading
`users/{uid}/wishlist/{courseId}.exists` for the bookmark icon is O(1)
and gives perfect deduplication without a write-side query.

### Why denormalize title + thumbnail + instructor + priceTier?

The Saved page is mostly scrolled while flying around the catalogue.
Without denormalization every row would N+1 read `courses/{id}` — a
24-course wishlist becomes 24 extra Firestore reads on every scroll
back. The price-drop Cloud Function (see §4) keeps `priceTier` in sync
when the source course changes.

---

## 2. Architecture

```
CourseCard / CourseDetailPage / SearchResultTile
   │
   ▼ ←──── reads effectiveWishlistedProvider(courseId)
BookmarkButton (heart icon, animated swap on toggle)
   │
   ▼ on tap
WishlistToggleNotifier.toggle(course, wasOnWishlist)
   │
   ▼ optimistic in-memory flip   ┐
   │                              │ Server-truth + optimistic overlay
   ▼ WishlistDataSource.add/remove│ together drive every bookmark icon
users/{uid}/wishlist/{courseId}   ┘
   │
   ▼ snapshot updates
wishlistedIdsStreamProvider (Set<String>)
wishlistStreamProvider (List<WishlistItemModel>)
wishlistCountProvider (int)
   │
   ▼ consumed by
- BookmarkButton (via effectiveWishlistedProvider)
- WishlistPage (Saved tab)
- Profile tile subtitle (count)
```

### Optimistic toggle

`WishlistToggleNotifier` keeps an overlay of `optimisticallyAdded` /
`optimisticallyRemoved` ids on top of the server-truth set. On tap we
mutate the overlay immediately so the heart flips within one frame; on
write success we clear the overlay (the next snapshot will already match).
On write failure we roll the overlay back and surface a snackbar.

This matters because Firestore round-trips on a flaky 3G can take 800ms+
— users would otherwise tap the heart and watch it not change for a full
second.

---

## 3. Files added

| Path | Role |
|---|---|
| `lib/features/wishlist/domain/entities/wishlist_item.dart` | Freezed entity |
| `lib/features/wishlist/data/models/wishlist_item_model.dart` | Freezed + JsonSerializable model |
| `lib/features/wishlist/data/datasources/wishlist_datasource.dart` | watchAll, watchIds, watchCount, add, addRaw, remove |
| `lib/features/wishlist/presentation/providers/wishlist_providers.dart` | Streams + selectors + `WishlistToggleNotifier` (optimistic overlay) |
| `lib/features/wishlist/presentation/widgets/bookmark_button.dart` | Animated heart with `card`/`appBar`/`plain` style variants |
| `lib/features/wishlist/presentation/pages/wishlist_page.dart` | List with swipe-to-delete + empty state with browse CTA |
| `docs/wishlist.md` | This file |

## 4. Files changed

- `lib/features/courses/presentation/widgets/course_card.dart` — wrapped
  the thumbnail in a `Stack` and overlaid `BookmarkButton` in the
  top-right corner. The button absorbs its own tap so heart-toggling
  doesn't route into the card's `onTap`.
- `lib/features/courses/presentation/pages/course_detail_page.dart` —
  added `BookmarkButton(style: appBar)` to the `SliverAppBar` actions
  so the heart is always visible alongside the cover image.
- `lib/features/profile/presentation/pages/profile_page.dart` —
  replaced the placeholder "Saved courses" tile with a routed entry
  whose subtitle reads from `wishlistCountProvider` (e.g.
  `"3 courses saved"`).
- `lib/core/routing/route_names.dart` + `app_router.dart` — new
  `/profile/wishlist` route nested under the profile branch.
- `firestore.rules` — owner-only carve-out on `users/{uid}/wishlist/{courseId}`.
- `firestore.indexes.json` — new collection-group index on
  `wishlist.courseId` for the price-drop Cloud Function.
- `functions/src/index.ts` — new `onCoursePriceDrop` trigger (see §5).
  Also extended `deleteAccount` to drop the wishlist subcollection.
- `lib/l10n/app_en.arb`, `app_vi.arb` + generated `app_localizations*.dart`
  — 11 new keys.

## 5. Price-drop Cloud Function

`onCoursePriceDrop` fires on `courses/{id}` update when `priceTier`
drops (basic < standard < premium, lower rank means cheaper).

```
update event
   ↓
diff priceTier — rank decreased?
   ↓ yes
collectionGroup('wishlist').where('courseId', '==', cid).get()
   ↓
for each saver:
   - update users/{saver}/wishlist/{cid}.priceTier (denorm sync)
   - notifyUser(saver, push + inbox row)
```

Each push is sent through the existing `notifyUser` helper (FCM + inbox
mirror) — wishlisters see the alert both as a system push and in their
in-app inbox.

### Quota safety

The function chunks the FCM fan-out at 20 recipients per
`Promise.all`. For courses with thousands of savers the fan-out can
still hit Firestore write quotas; the function logs and proceeds. For
production scale (>5k saves) swap this for a queue-based fan-out where
each saver is enqueued and a worker drains the queue with concurrency
caps.

### Index requirement

```json
{
  "collectionGroup": "wishlist",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    { "fieldPath": "courseId", "order": "ASCENDING" }
  ]
}
```

Already added to `firestore.indexes.json` — deploy with
`firebase deploy --only firestore:indexes`.

## 6. Firestore rules

```firestore
match /users/{userId}/wishlist/{courseId} {
  allow read, write: if isSignedIn() && uid() == userId;
}
```

Owner-only by design — other users can't see what you've saved. The
Cloud Function uses the Admin SDK and bypasses these rules.

## 7. Testing checklist

| Scenario | Expected |
|---|---|
| Tap heart on a CourseCard | Icon flips immediately (optimistic); Firestore doc appears |
| Tap heart while offline | Icon flips, write queues, syncs when connection returns |
| Tap heart with bad creds (rule denial) | Icon rolls back; snackbar "Could not update — please try again" |
| Sign in as a different user | Bookmark icons across the catalogue reflect the new user's wishlist |
| Open Profile when logged out | Tile subtitle shows "Bookmark a course to come back to it" |
| Open Profile with 3 saves | Tile subtitle shows "3 courses saved" |
| Tap Saved tile | Routes to `/profile/wishlist`; list ordered newest-first |
| Swipe a row | Row deletes; Firestore doc removed |
| Tap a row | Routes to `/courses/{id}` |
| Empty state | "No saved courses yet" + "Browse courses" CTA |
| Admin drops a course tier basic ← standard | Wishlisters get push + inbox row; their denormalized `priceTier` updates |
| Admin raises tier (premium ← standard) | No notification (only drops trigger) |
| Delete account | Wishlist subcollection wiped by `deleteAccount` Cloud Function |

## 8. Future work

- **Email campaign.** Roadmap §P2-2 mentions an email trigger — wire
  `onCoursePriceDrop` to also enqueue a SendGrid / Mailgun template.
- **Bulk operations.** Multi-select on the Saved page → "Add all to
  cart" or "Apply coupon to all".
- **Shareable lists.** A read-only public URL for someone else's
  wishlist — useful for instructor "follow my recommended sequence"
  posts.
- **Recently saved Home rail.** Symmetric to "Continue learning" —
  surface the user's 3 most recently bookmarked courses.
- **Wishlist export.** CSV download from the Saved page for users who
  want to track their learning queue elsewhere.
