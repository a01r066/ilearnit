# Skeletons + Pull-to-Refresh

Implements **P1-10** from `docs/go_live_roadmap.md` — replaces
`CircularProgressIndicator` first-load states with shimmer skeletons, and
wraps every data-driven list in a `RefreshIndicator` so the user has a
single recovery gesture for stale data.

P1-9 (Courses pagination) already shipped skeletons + refresh for the
Courses tab; this task extends the same pattern to **Home**,
**Instructors**, **Songbooks**, and the **Reviews** section embedded in
the course detail page.

---

## 1. Why skeletons matter

Centred spinners signal "something is happening" but not "what's
coming." On a 200ms network they flash in and out — perceived latency
without informational payoff. Shimmer placeholders preview the layout
the user is about to see, which compresses perceived latency and (more
importantly) anchors the eye so the real content doesn't appear to
"jump in."

Concretely: the Home tab is now usable to scroll-read even before any
Firestore reads complete. The user sees rail headings, card geometry,
and column structure within one frame — same as on Tonebase / Spotify /
YouTube.

---

## 2. Shared primitives

Three building blocks in `lib/core/widgets/skeleton.dart`:

```dart
SkeletonShimmer(child: …)   // one Shimmer at the root drives the whole subtree
SkeletonBox(width, height, borderRadius)   // rounded rectangle placeholder
SkeletonText(width, height)                // thin bar styled like a text line
SkeletonAvatar(size)                       // circle, sized for ListTile leading
```

**Performance note:** put a single `SkeletonShimmer` at the root of the
skeleton subtree, not around each shape. The gradient sweep is one
paint pass over the whole tree; nesting `Shimmer.fromColors` per shape
quadruples the GPU cost without changing the visual.

Colours come from the active `ColorScheme` — `surfaceContainerHighest`
(base) and `surfaceContainerHigh` (highlight) — so skeletons recolour
automatically when the user toggles vibrant / professional / system in
Settings.

---

## 3. Per-feature wiring

### Home (`features/home/presentation/pages/home_page.dart`)

- Wrapped the outer `ListView` in `RefreshIndicator`. The handler
  invalidates `featuredCoursesProvider` + the three
  `popularByInstrumentProvider(category)` family entries.
- Replaced the two `SizedBox(height: 220, child: LoadingIndicator())`
  blocks with `CourseCarouselSkeleton()` — a horizontal row of 3 skeleton
  cards sized identically to the live `CourseCard` (280×320).
- `AlwaysScrollableScrollPhysics` on the ListView so the refresh gesture
  works when the page is shorter than the viewport.

### Instructors (`features/instructors/.../instructors_page.dart`)

- Wrapped in `RefreshIndicator` invalidating `instructorsListProvider`.
- Replaced the centered `CircularProgressIndicator` with a new
  `_InstructorListSkeleton` — 6 rows of `ListTile`-shaped placeholders
  (56×56 avatar + two text lines) that match the real `_InstructorRow`.
- Empty state is now wrapped in a `ListView` so the refresh gesture
  works even when there are no instructors.

### Songbooks (`features/songbooks/.../songbooks_page.dart`)

- Wrapped the outer `ListView` in `RefreshIndicator`. The handler
  invalidates both `recentlyViewedSongbooksProvider` (FutureProvider)
  and `bestsellersStreamProvider` (StreamProvider).
- The existing `_CarouselSkeleton` was a static grey box; it now wraps a
  row of 4 portrait `SkeletonBox(width: 160, height: 216)` inside a
  `SkeletonShimmer`, matching the cover dimensions of the live
  `SongbookCard`.

### Course reviews (`features/courses/.../course_reviews_section.dart`)

- Replaced the inline `Padding(child: CircularProgressIndicator)` with
  a new `_ReviewsSkeleton` — a summary-row placeholder followed by 3
  review-tile placeholders (avatar + name + stars + body).
- Course detail itself doesn't gain a top-level `RefreshIndicator` —
  it's a `CustomScrollView` whose underlying providers re-fetch on
  re-mount, and pulling-to-refresh inside a video player would surprise
  more users than it would help.

---

## 4. Files added

| Path | Role |
|---|---|
| `lib/core/widgets/skeleton.dart` | `SkeletonShimmer` + `SkeletonBox` + `SkeletonText` + `SkeletonAvatar` |
| `lib/features/courses/presentation/widgets/course_carousel_skeleton.dart` | Horizontal 320×280 placeholder row (used by Home) |
| `docs/skeletons_and_refresh.md` | This file |

## 5. Files changed

- `home_page.dart` — RefreshIndicator + carousel skeletons + remove
  `loading_indicator` import.
- `instructors_page.dart` — RefreshIndicator + new
  `_InstructorListSkeleton`.
- `songbooks_page.dart` — RefreshIndicator + `_CarouselSkeleton`
  rebuilt on top of `SkeletonShimmer`.
- `course_reviews_section.dart` — new `_ReviewsSkeleton` replaces the
  centered spinner.

No string changes — the skeleton state has no labels by design (the
real layout speaks for itself).

## 6. Testing checklist

| Scenario | Expected |
|---|---|
| Cold-start Home | Carousel skeletons paint within one frame; resolve to real cards as Firestore returns |
| Pull-down on Home | Spinner appears at the top; `featuredCoursesProvider` + all 3 `popularByInstrumentProvider` family entries re-fetch |
| Cold-start Instructors | 6 row skeletons; resolve into real instructor rows |
| Pull-down on Songbooks | Both carousels re-resolve; trial banner re-checks subscription |
| Pull-down on Courses | (P1-9) — full grid resets via `CoursesNotifier.refresh()` |
| Cold-start a course detail with no reviews | Skeleton summary + 3 placeholder rows; resolves to "No reviews yet — be the first" |
| Theme switch mid-skeleton | Base + highlight colors update on the next frame |

## 7. Future work

- **Sliver skeletons.** The Home tab uses a plain `ListView` rather than
  `CustomScrollView` so the skeleton ListView nesting works without
  Sliver gymnastics. If Home gains more sections, swap to slivers and
  use a sliver-friendly skeleton.
- **Empty-state retry.** All four pages currently show plain "Nothing
  yet" copy on empty. P0-6 Crashlytics will surface flaky-but-not-empty
  cases; future polish should differentiate.
- **Course detail RefreshIndicator.** Filed as deliberate skip in §3;
  revisit if course pages start showing reviews-by-date or other
  freshness-sensitive content.
- **Skeleton-shimmer A/B.** Some users perceive shimmer as "buggy
  loading." Worth running an experiment toggling shimmer on/off after
  Remote Config lands (Ops-2 in the roadmap).
