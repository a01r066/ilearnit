# Courses Pagination

Implements **P1-9** from `docs/go_live_roadmap.md` — cursor-based infinite
scroll on the Courses tab, with skeleton placeholders and inline retry on
load-more failures.

---

## 1. Flow

```
User lands on /courses
   ↓
CoursesNotifier (auto-fires refresh() on construction)
   ↓ initial fetch (limit = AppConstants.defaultPageSize = 20)
state.items[0..19] + nextCursor + hasMore=true
   ↓
CoursesPage renders SliverGrid + scrolls
   ↓ position.pixels / position.maxScrollExtent >= 0.80
notifier.loadNextPage()
   ↓ fetchCourses(cursor: state.nextCursor)
state.items extended; state.isLoadingMore flips false
   ↓ scroll past 80% again
… repeat until hasMore == false
   ↓
SliverToBoxAdapter renders the "You've reached the end." sentinel
```

---

## 2. Scroll trigger

`CoursesPage` keeps a `ScrollController` whose listener fires:

```dart
final fraction = pos.pixels / pos.maxScrollExtent;
if (fraction >= 0.80) {
  ref.read(coursesNotifierProvider.notifier).loadNextPage();
}
```

The notifier's guard clause makes the call cheap:

```dart
if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) return;
```

so calling `loadNextPage()` on every scroll tick is safe.

The 80% threshold means the user typically sees zero loading state on a
desktop monitor (page lands while they're still reading row 14 of 20) and
~half a second of skeleton on a phone — better than a strict "fire when
they hit the bottom" rule which always shows a spinner.

## 3. State machine

```
CoursesState
  ├── items         : List<CourseEntity>     (accumulating, never reset on loadMore)
  ├── isLoading     : bool                   (initial / refresh)
  ├── isLoadingMore : bool                   (background page fetch)
  ├── hasMore       : bool                   (drives end-of-list sentinel)
  ├── nextCursor    : String?
  ├── category      : InstrumentCategory?    (filter)
  ├── level         : CourseLevel?           (filter)
  ├── failure         : Failure?             (initial / refresh failure)
  └── loadMoreFailure : Failure?             (page-fetch failure — inline retry footer)
```

Crucially, `failure` and `loadMoreFailure` are separate fields. A failed
page fetch never blows away the existing list — it surfaces as an inline
retry banner at the bottom of the grid so the user can keep their
scroll position. Only the initial / refresh failure escalates to the
full-bleed `ErrorView`.

## 4. UI states

| Condition | Render |
|---|---|
| `isLoading && items.isEmpty` | `CourseGridSkeleton(count: 6)` |
| `failure != null && items.isEmpty` | `ErrorView` (full-bleed retry) |
| `isEmpty` | `EmptyView(message: t.coursesEmpty)` |
| Normal | `SliverGrid` of `CourseCard`s |
| `isLoadingMore` | Footer: 2-card skeleton row + "Loading more courses…" |
| `loadMoreFailure != null` | Inline retry banner |
| `!hasMore && items.isNotEmpty` | "You've reached the end." sentinel |

## 5. Skeletons

`CourseCardSkeleton` mirrors the live `CourseCard` layout — 16:9
thumbnail, two-line title placeholder, instructor line, stats row. Uses
the `shimmer` package (already in stack).

`CourseGridSkeleton` is a non-scrolling `GridView.builder` of skeleton
cards sized to match the live grid's `SliverGridDelegateWithMaxCrossAxisExtent`,
so the grid never jumps when results arrive.

## 6. Files added

| Path | Role |
|---|---|
| `lib/features/courses/presentation/widgets/course_card_skeleton.dart` | Shimmer placeholder + grid wrapper |
| `docs/pagination.md` | This file |

## 7. Files changed

- `lib/features/courses/presentation/providers/courses_state.dart` — new
  nullable `loadMoreFailure` field.
- `lib/features/courses/presentation/providers/courses_notifier.dart` —
  `loadMore()` writes to `loadMoreFailure` instead of `failure`; new
  `loadNextPage()` alias to match the roadmap-spec name.
- `lib/features/courses/presentation/pages/courses_page.dart` —
  rewritten as a `CustomScrollView` with `SliverGrid` + skeleton +
  inline retry + end-of-list sentinel. 80% scroll trigger replaces the
  previous "240px from bottom" heuristic.
- `lib/l10n/app_en.arb`, `app_vi.arb` + generated `app_localizations*.dart`
  — `coursesLoadingMore` + `coursesEndOfList` keys.
- `sample_data/generate_seed.py` + `sample_data/README.md` — course
  count bumped from 100 → 120 (45 guitar / 45 piano / 30 violin) to
  guarantee multiple pages per category at the default page size of
  20. Re-run `python3 generate_seed.py` to regenerate the JSON files.

## 8. Testing checklist

| Scenario | Expected |
|---|---|
| Fresh load with no filter | Skeleton grid for ~one network round-trip, then 20 cards + "Loading more courses…" footer if scrolled past 80% |
| Scroll to bottom (no filter) | 6 pages of 20 fetched; sentinel renders after page 6 |
| Apply Guitar filter | List resets to ~20 cards, scroll past 80% loads pages 2 + 3 (45 total) |
| Apply rare filter (Violin advanced) | Single page, end-of-list sentinel shown immediately |
| Disconnect mid-load-more | Inline red banner appears with "Try again" — list stays put |
| Tap "Try again" in banner | Refreshes the failed page only; existing items untouched |
| Pull-to-refresh | Resets the list; cursor + state reset; skeleton shown briefly |
| Scroll back to top after multi-page load | List is buttery — no rebuild churn (items list is append-only) |

## 9. Future work

- **Per-page page-size tuning.** First page could be smaller (10) so it
  lands faster, subsequent pages 20-30. Requires plumbing limit into
  `loadMore`.
- **Optimistic merge on category change.** Currently `filterByCategory`
  re-fetches from scratch. We could keep the items that match the new
  category and only re-fetch the cursor's worth — but this requires
  hashing courses to category client-side to avoid drift.
- **Predictive prefetch.** Trigger `loadNextPage()` at 60% instead of
  80% if the previous page's fetch latency was under 300ms. Reduces
  perceived loading to zero on fast connections.
- **Composite index for sort changes.** As of v1 the catalogue is
  sorted by `publishedAt desc` on the server side. Adding "sort by
  popularity" or "sort by rating" would need composite indexes —
  documented in `docs/go_live_roadmap.md` Ops-6.
