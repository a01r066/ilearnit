# Learning Paths

Implements **P2-5** from `docs/go_live_roadmap.md` — curated multi-course
sequences (think Tonebase "Classical Guitar from Scratch — 12 Weeks").
An editorial product, written by admins via the admin portal, surfaced
on the consumer Home tab as a horizontal rail, and rendered as an
ordered curriculum on the detail page with per-course completion bars.

---

## 1. Data model

```
learning_paths/{pathId}
  ├── title           string
  ├── summary         string
  ├── coverUrl        string?
  ├── instrument      string?   ('guitar' | 'piano' | 'violin' | null = "Mixed")
  ├── courseIds       array<string>   (order is significant)
  ├── totalHours      number          (editor-supplied total)
  ├── isPublished     bool            (draft gate)
  ├── createdAt       timestamp
  └── updatedAt       timestamp
```

### Why `courseIds` is an ordered array, not a subcollection

A path is at most ~20 courses. Loading them as a single array is cheaper
than 20 subcollection docs and lets the editor reorder with a simple
`ReorderableListView` → array swap → one Firestore write.

If a path ever crosses ~100 courses (which it shouldn't editorially),
swap to `learning_paths/{id}/courses/{order}` so we can paginate.

### Why denormalize `totalHours`?

Summing per-course durations would require N+1 reads of `courses/{id}`.
The editor types the number once when assembling the path; we trust it.
A future Cloud Function trigger could recompute from
`courses[*].durationMinutes / 60` on every write — filed as polish.

---

## 2. Architecture

```
Admin
  AdminLearningPathsPage   ──► create (draft) ──► LearningPathEditorPage
        │                                                 │
        │  AdminLearningPathsDataSource                   │  AdminLearningPathsDataSource.update
        │  (watchAll, create, update, delete)             │  AdminStorageService.uploadLearningPathCover
        ▼                                                 ▼
                       learning_paths/{pathId}
                              ▲
Consumer                       │
  LearningPathsRail  ◄─── learningPathsStreamProvider (watchAll, isPublished=true)
        │
        ▼ tap a card
  LearningPathDetailPage ──► courseByIdProvider(courseId)     [fetches each row]
        │                  └► courseProgressSummaryProvider   [progress bar]
        ▼
  CourseDetailPage
```

The consumer datasource filters by `isPublished == true`; the admin
datasource doesn't (so editors can find a draft they parked yesterday).

---

## 3. Files added

### Consumer

| Path | Role |
|---|---|
| `lib/features/learning_paths/domain/entities/learning_path.dart` | Freezed `LearningPath` + `courseCount` getter |
| `lib/features/learning_paths/data/models/learning_path_model.dart` | Freezed + JsonSerializable, instrument stored as id string |
| `lib/features/learning_paths/data/datasources/learning_paths_datasource.dart` | watchAll, watchById, watchByInstrument — published-only |
| `lib/features/learning_paths/presentation/providers/learning_paths_providers.dart` | Stream providers + by-instrument family |
| `lib/features/learning_paths/presentation/widgets/learning_path_card.dart` | 320×280 carousel card matching `CourseCard` rhythm |
| `lib/features/learning_paths/presentation/widgets/learning_paths_rail.dart` | Home rail (self-hides when empty) |
| `lib/features/learning_paths/presentation/pages/learning_path_detail_page.dart` | Cover + summary + numbered curriculum with per-course progress |

### Admin

| Path | Role |
|---|---|
| `lib/admin/learning_paths/data/admin_learning_paths_datasource.dart` | CRUD against `learning_paths/` |
| `lib/admin/learning_paths/presentation/admin_learning_paths_page.dart` | List + "New path" button + delete confirm |
| `lib/admin/learning_paths/presentation/learning_path_editor_page.dart` | Form: cover upload + title + summary + total hours + instrument + reorderable course multi-select |

### Docs

| Path | Role |
|---|---|
| `docs/learning_paths.md` | This file |

## 4. Files changed

- `lib/core/constants/api_endpoints.dart` — new
  `FirestoreCollections.learningPaths = 'learning_paths'`.
- `lib/features/courses/presentation/providers/courses_providers.dart` —
  new `courseByIdProvider` (FutureProvider.family) so the detail page
  can hydrate each curriculum row.
- `lib/features/home/presentation/pages/home_page.dart` — mounted
  `LearningPathsRail` between Continue Learning and the instrument
  grid.
- `lib/core/routing/route_names.dart` + `app_router.dart` — new
  top-level `/learning-paths/:id` route registered above the shell.
- `lib/admin/routing/admin_route_names.dart` + `admin_router.dart` —
  new `/admin/learning-paths` + `/admin/learning-paths/:id` routes,
  added to `_isAdminOnly` allow-list.
- `lib/admin/shared/widgets/admin_scaffold.dart` — new "Learning paths"
  side-nav item between Songbooks and Subscriptions.
- `lib/admin/shared/providers/admin_providers.dart` — new
  `adminLearningPathsDataSourceProvider`.
- `lib/admin/courses/data/admin_storage_service.dart` — new
  `uploadLearningPathCover` (one-shot upload returning the download URL,
  unlike the streaming uploads for lecture media).
- `firestore.rules` — public read of `learning_paths/{pathId}` (filtered
  client-side by `isPublished`), admin write.
- `firestore.indexes.json` — composite indexes for `isPublished +
  createdAt` (Home rail) and `isPublished + instrument + createdAt`
  (instrument filter).
- `lib/l10n/app_en.arb` + `app_vi.arb` + generated localizations — 7
  new keys covering rail title, eyebrow, course count, total hours,
  curriculum header, missing-course fallback, and the not-found
  message.

## 5. Editor UX notes

The editor uses `ReorderableListView` for the selected courses — drag
the handle to swap row positions. The picker below shows the next
20 courses matching the search query and excludes courses already in
the selection so editors don't accidentally double-add.

Cover upload reuses the existing `AdminStorageService` but with a new
one-shot `uploadLearningPathCover` (returns a `Future<String>` of the
download URL) instead of the streaming progress flow used by lecture
media. A learning-path cover is a single JPEG; a progress bar is
overkill.

## 6. Firestore rules

```firestore
match /learning_paths/{pathId} {
  allow read: if true;
  allow write: if isAdmin();
}
```

Public read of draft docs is intentionally OK — the consumer
`watchAll` filters on `isPublished == true`, so a draft doc is
invisible to the rail. If an external script crawls the collection
directly it'll see drafts, which is fine for an editorial product
that has no PII.

## 7. Indexes

```json
{
  "collectionGroup": "learning_paths",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "isPublished", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "learning_paths",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "isPublished", "order": "ASCENDING" },
    { "fieldPath": "instrument", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

Both added to `firestore.indexes.json`. Deploy with
`firebase deploy --only firestore:indexes`.

## 8. Testing checklist

| Scenario | Expected |
|---|---|
| Admin: create new path → editor opens | Empty draft renders, course picker shows live catalogue |
| Drag a row in the selected list | Order persists on save; consumer rebuilds in numbered order |
| Toggle "Published" → save | Doc appears on Home rail; toggle off → doc disappears |
| Delete a course that's part of a path | Detail row renders "(Course no longer available)" fallback |
| Empty home rail | LearningPathsRail self-hides — no dead headline |
| Tap a card from the rail | `pushNamed(learningPathDetail, id)` — modal-style, back returns to Home |
| Detail page with completed first course | Row 1 shows green checkmark; row 2 highlighted |
| Tap a row | Routes into the existing CourseDetailPage |
| Sign in as instructor (not admin) | Side-nav hides Learning paths; direct URL bounces |

## 9. Future work

- **"Next up" CTA.** Surface the first not-completed course as a sticky
  primary button on the detail page so a returning user can resume in
  one tap.
- **Auto totalHours.** Cloud Function trigger that recomputes the sum
  from `courses[*].durationMinutes / 60` on every path write — removes
  one editor-error vector.
- **Per-instrument rails.** Re-use `learningPathsByInstrumentProvider`
  on the instrument detail page (currently unused by the rail but the
  provider is already wired).
- **Path enrollment + certificates.** Treat "all courses in path
  completed" as a milestone for the certificate generator described
  in P2-1.
- **Editor lint.** Warn when total hours diverges from the per-course
  sum by more than ±15%.
