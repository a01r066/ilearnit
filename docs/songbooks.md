# Songbooks — Setup, Rules, Seeding

iLearnIt's **Songbooks tab** is a separate content type from courses: sheet-music books (often from publishers like Hal Leonard) that the user can browse, sample, and unlock via subscription or one-off purchase. Songbooks live as a 5th bottom-nav tab in the mobile app and are stored in the `songbooks` Firestore collection.

## Architecture

```
ShellScaffold (bottom nav)
├── Home
├── Courses
├── Instructors
├── Songbooks  ◄── 5th tab
│     SongbooksPage
│        ├─ Brand header + bell/profile
│        ├─ "Start 7-day free trial" banner (hidden if subscribed)
│        ├─ Search-pill row (deep-links to /search)
│        ├─ Recently Viewed carousel  ◄── from PrefsService MRU
│        └─ Bestsellers carousel       ◄── from Firestore
│     /songbooks/:id ─► SongbookDetailPage
│        banner ▸ title ▸ Get Songbook CTA ▸ action row
│        ▸ rating ▸ description ▸ Includes ▸ metadata strip
│        ▸ Reviews (subcollection)
│        ▸ You might also like
└── Profile
```

State management mirrors the project pattern: a single `SongbooksDataSource` wraps Firestore; provider files in `lib/features/songbooks/presentation/providers/` expose typed streams to the UI.

## Firestore schema

```
songbooks/
  {songbookId}
    title              string
    coverUrl           string   // portrait 3:4 image
    bannerUrl          string   // wide 16:9 image (falls back to coverUrl)
    description        string
    includes           string[]
    instrument         string   // "Piano" | "Guitar" | "Mixed" | …
    topics             string[]
    publisher          string
    rating             number   // 0..5
    ratingCount        number
    productId          string   // IAP id (per-songbook purchase)
    isBestseller       bool
    samplePages        string[] // URLs of preview PDF pages
    publishedAt        timestamp

    reviews/                    // subcollection
      {reviewId}
        userId         string
        userName       string
        rating         number
        body           string
        createdAt      timestamp
```

The mobile app reads with `snapshots()` for live updates so a publisher pushing a new title appears without a refresh.

## Firestore security rules

The Songbooks queries fail with `PERMISSION_DENIED` until these rules are deployed. Append to `firestore.rules` alongside the existing course rules (which already define the `isAdmin()`, `isSignedIn()`, `uid()` helpers from `docs/admin_portal.md`):

```javascript
// ---------- songbooks ----------
match /songbooks/{songbookId} {
  // Catalogue is public — same model as courses.
  allow read: if true;
  // Only admins can publish / edit songbooks.
  allow write: if isAdmin();

  match /reviews/{reviewId} {
    allow read: if true;
    // Users can author their own review; admins can edit/delete any.
    allow create: if isSignedIn()
      && request.resource.data.userId == uid();
    allow update, delete: if isAdmin()
      || (isSignedIn() && resource.data.userId == uid());
  }
}
```

Deploy with:

```bash
firebase deploy --only firestore:rules --project ilearnit-dev
# smoke-test, then:
firebase deploy --only firestore:rules --project ilearnit-prod
```

The bestsellers stream re-evaluates the permission check automatically — no app restart needed.

## Firestore indexes

The v1 queries all use single-field constraints, so Firestore's **auto-generated indexes are sufficient**. No `firestore.indexes.json` entries are required for:

| Query | Used by | Why no composite index needed |
|---|---|---|
| `orderBy('publishedAt', desc).limit(60)` | `watchAll()` | Single-field orderBy |
| `where('isBestseller', ==, true).limit(12)` | `watchBestsellers()` | Single-field where; implicit `__name__` orderBy is auto-indexed |
| `where('instrument', ==, X).limit(9)` | `watchSimilar()` | Single-field where |
| `where(__name__, in, ids)` | `fetchByIds()` (Recently Viewed) | `whereIn` on doc id is always auto-indexed |
| `reviews orderBy('createdAt', desc).limit(20)` | `watchReviews()` | Single-field orderBy on a subcollection |

You'll need to **declare composite indexes** if you extend the queries — likely additions:

```json
// firestore.indexes.json — add when needed
{
  "indexes": [
    {
      "collectionGroup": "songbooks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isBestseller", "order": "ASCENDING" },
        { "fieldPath": "publishedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "songbooks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "instrument", "order": "ASCENDING" },
        { "fieldPath": "rating", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "songbooks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "topics", "arrayConfig": "CONTAINS" },
        { "fieldPath": "publishedAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Deploy indexes with `firebase deploy --only firestore:indexes`. Note that Firestore also surfaces a click-to-create link in the console + the runtime error message whenever a query hits a missing composite index — that's usually the easiest way to bootstrap them.

## Seeding sample data

The repo ships `sample_data/songbooks.json` with 6 books matching the attached design (First 50 Popular Songs, The Greatest Video Game Music, Next First 50, The Real Pop Book Vol I, Fingerpicking Guitar Bible, Jazz Piano Method).

If you already use `sample_data/seed_firestore.js` for courses + instructors, append a songbooks block to its `COLLECTIONS` array (or equivalent dispatcher). Reference shape:

```js
// sample_data/seed_firestore.js
const fs = require('fs');
const admin = require('firebase-admin');

// ...existing init...
const db = admin.firestore();

async function seedCollection(name, file) {
  const docs = JSON.parse(fs.readFileSync(file, 'utf8'));
  const batch = db.batch();
  for (const doc of docs) {
    const { id, ...rest } = doc;
    // Convert ISO date strings to Firestore Timestamps.
    if (rest.publishedAt) {
      rest.publishedAt = admin.firestore.Timestamp.fromDate(
        new Date(rest.publishedAt),
      );
    }
    batch.set(db.collection(name).doc(id), rest, { merge: true });
  }
  await batch.commit();
  console.log(`✔  Seeded ${docs.length} → ${name}`);
}

(async () => {
  await seedCollection('courses', 'sample_data/courses.json');
  await seedCollection('instructors', 'sample_data/instructors.json');
  await seedCollection('songbooks', 'sample_data/songbooks.json');   // ← add this
})();
```

Run from the repo root:

```bash
node sample_data/seed_firestore.js
```

Expected output:

```
✔  Seeded 6 → songbooks
```

Verify in Firebase Console → Firestore → `songbooks` — you should see 6 docs, four with `isBestseller: true`.

### Seeding reviews (optional)

For UI smoke testing, add a few reviews to one book:

```js
// optional review-seed snippet
const reviews = [
  {
    userId: 'demo_user_1',
    userName: 'Debra Why',
    rating: 5,
    body: 'Lovely book to learn to play these favorites!',
    createdAt: admin.firestore.Timestamp.fromDate(
      new Date('2024-12-30T00:00:00Z'),
    ),
  },
  {
    userId: 'demo_user_2',
    userName: 'Marcus T.',
    rating: 4,
    body: 'Good arrangements — would love a tab version.',
    createdAt: admin.firestore.Timestamp.fromDate(
      new Date('2025-01-12T00:00:00Z'),
    ),
  },
];

const target = db.collection('songbooks').doc('sb_first50_popular_piano');
for (const r of reviews) {
  await target.collection('reviews').add(r);
}
```

## In-app purchases

Each songbook carries a `productId` (e.g. `info.ilearnit.songbook.first50_popular_piano`). The current UI shows the **Get Songbook** CTA as a placeholder — wiring it up is a follow-up that reuses the existing IAP infrastructure (`PurchasesNotifier` + `IapRemoteDataSource`). The sample SKUs all start with `info.ilearnit.songbook.` so a single regex pattern can route songbook purchases to the right notifier.

For App Store Connect + Play Console:
- Each songbook = one **Non-Consumable** product (not auto-renewing).
- Bundle them under the same App ID as courses.
- Add the product ids to a `SongbookPurchases` registry mirroring `PriceTier` in `lib/features/purchases/domain/entities/price_tier.dart`.

## Smoke testing

1. **Deploy the rules** (snippet above) to your dev project.
2. **Seed the catalogue**: `node sample_data/seed_firestore.js`.
3. **Run the app**: `flutter run --flavor dev -t lib/main_dev.dart`.
4. Tap the **Songbooks** tab (5th nav slot, between Instructors and Profile).
5. Verify:
   - The "Start 7-day free trial" banner shows (assuming you don't have an active subscription).
   - The **Bestsellers** carousel populates with 4 books.
   - The **Recently Viewed** section is hidden.
6. Tap a cover → detail page renders with banner, title, Get Songbook CTA, action row, rating, description, Includes, metadata strip, Reviews (showing "No reviews yet." until you seed any), and the You might also like carousel.
7. Back to the tab → the book you just opened is now the head of the **Recently Viewed** carousel.
8. Subscribe (Profile → Subscription → checkout, or set `users/{uid}.subscription.expiresAt` to a future date manually) → return to the Songbooks tab → the trial banner is gone.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `PERMISSION_DENIED` on `songbooks` query | Rules not deployed | `firebase deploy --only firestore:rules` |
| Bestsellers carousel empty after rules deploy | Collection empty | Run the seed script (or manually add docs in console) |
| Recently Viewed never shows | MRU has zero ids | Open a detail page first; the post-frame callback writes to `PrefsService.pushRecentSongbook` |
| Detail page shows "Songbook not found." | Doc id mismatch with the URL parameter | Check `pathParameters['id']` matches a real doc id |
| "Missing composite index" error in logcat | You extended a query past v1 | Tap the click-to-create link in the error, or paste an entry into `firestore.indexes.json` (sample above) and `firebase deploy --only firestore:indexes` |
| Covers don't render | `coverUrl` empty or unreachable | `SongbookCard` shows a book-icon fallback; verify `picsum.photos` (or your real CDN) is reachable |
| Reviews subcollection write fails | Rule mismatch on `userId` | Confirm `request.resource.data.userId == uid()` in the create — the rule rejects writes with a different uid |
| Trial banner never hides for active subscriber | `hasActiveSubscriptionProvider` returning false | Inspect `users/{uid}.subscription.expiresAt` — `isActive` checks it's in the future |

## v1 scope checklist

- [x] Songbooks bottom-nav tab (5th slot)
- [x] Brand header + bell/profile icons
- [x] 7-day free trial promo banner (auto-hides if subscribed)
- [x] Recently Viewed carousel (PrefsService MRU, capped at 12)
- [x] Bestsellers carousel (Firestore `isBestseller==true`)
- [x] Detail page: banner, title, Get Songbook CTA, action row
- [x] Description + Includes inline `view all` toggles
- [x] 3-column metadata strip (INSTRUMENT / TOPICS / PUBLISHER)
- [x] Reviews section + single-card preview
- [x] You might also like carousel (similar-instrument)
- [x] Sample data + Firestore rules + index hints documented

## Things deferred (post-v1)

- Wire the **Get Songbook** CTA to IAP via a `SongbookPurchases` notifier (mirroring `PurchasesNotifier` for courses).
- **Sample** action — open a PDF viewer over `samplePages[0]`.
- **Save** action — back the heart toggle with a `users/{uid}.savedSongbookIds` array.
- **Share** action — shareable deep-link via `share_plus`.
- Full Reviews page (list + composer + report).
- Author / admin-portal CRUD for songbooks (mirror the `admin_courses_page.dart` flow under `lib/admin/songbooks/`).
- Search integration — extend `SearchRemoteDataSource` to also rank songbooks alongside courses.
- "Bestsellers" composite-index migration when the catalogue grows past a few hundred titles.

## Files

- Domain
  - `lib/features/songbooks/domain/entities/songbook_entity.dart`
  - `lib/features/songbooks/domain/entities/songbook_review.dart`
- Data
  - `lib/features/songbooks/data/models/songbook_model.dart`
  - `lib/features/songbooks/data/models/songbook_review_model.dart`
  - `lib/features/songbooks/data/datasources/songbooks_datasource.dart`
- State
  - `lib/features/songbooks/presentation/providers/songbook_providers.dart`
- UI
  - `lib/features/songbooks/presentation/pages/songbooks_page.dart`
  - `lib/features/songbooks/presentation/pages/songbook_detail_page.dart`
  - `lib/features/songbooks/presentation/widgets/songbook_card.dart`
- Integrations
  - `lib/core/routing/{route_names,app_router,shell_scaffold}.dart` (5th tab + nested detail route)
  - `lib/core/constants/{api_endpoints,app_constants}.dart` (collection name + MRU key + limit)
  - `lib/core/storage/prefs_service.dart` (recent songbook MRU helpers)
- i18n
  - `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
  - `lib/l10n/generated/app_localizations*.dart` (patched)
- Sample data
  - `sample_data/songbooks.json` (6 books)
- Docs
  - `docs/songbooks.md` (this file)
