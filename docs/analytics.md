# Admin analytics — revenue + cohort dashboard

Admin-portal-only page at `/admin/analytics`. Headline KPIs (MRR,
revenue in window, paying users, active subscribers), a stacked
revenue chart, per-plan and per-course breakdowns, a conversion
funnel, and a cohort retention heat-map.

## Data sources

The dashboard reads three collections in a single load:

```
courses/*               → priceTier + title → enrollment valuation
enrollments/*           → userId + courseId + createdAt → revenue + cohort signal
users/*                 → createdAt + onboardingComplete + subscription{} → cohort + MRR
```

Reads happen via the Admin SDK-equivalent rules path: admin role has
unrestricted read on these collections, so the client-side
aggregator works without a Cloud Function.

### Revenue valuation

| Source | Per-event value |
|---|---|
| Course purchase (`enrollments` doc created) | `PriceTier.fromId(course.priceTier).rawFallbackPrice` — USD fallback price ($9.99 / $19.99 / $39.99) |
| Subscription | `SubscriptionPlan.fallbackUsd / billingPeriodMonths` per active month |

USD fallback is used because the real charged amount lives on Apple /
Google's billing systems; we don't import receipt-level revenue
in v1. For the first launch this approximation is within ~10% of
actual storefront net revenue (after platform fees we don't display
here either).

### Subscription month attribution

For each user with an embedded `subscription.planId`, we straight-line
the per-month value across `[subscription.startedAt, subscription.expiresAt]`,
adding one month's worth of value to every bucket the interval
overlaps. Yearly subscriptions are spread evenly across 12 buckets, so
a single yearly sub showing $79.99/12 ≈ $6.67 per month in the chart
is expected.

We deliberately do not model proration, refunds, or churn timing —
those will arrive when we move aggregation to a nightly Cloud Function
backed by storefront server-to-server notifications.

## Cohort matrix

The matrix is built in a single pass over users + enrollments:

1. Bucket each user into a *signup cohort* by `createdAt` month
   (rolling 12 months ending at the window end).
2. For every user, compute their `firstPaidMonth` = `min(earliest
   enrollment month, subscription.startedAt month)` if either exists.
3. For each cell `[cohort, offset]`, count users in that cohort whose
   `firstPaidMonth <= cohort + offset`. This is "monotonically
   retained" (once they pay, they're retained forever) — appropriate
   for total-conversion view; not appropriate for active-subscription
   retention which would need monthly active-flag computation.

The matrix is triangular: row N has `12 - N` populated cells because
the older months haven't happened yet.

## Funnel

Four stages, no time-window — they're absolute snapshots:

| Stage | Computed from |
|---|---|
| Signed up | `users.count` |
| Onboarded | `users.where(u => u.onboardingComplete == true OR u.skillLevel != null)` |
| Made a payment | distinct userIds across enrollments + users with subscription.planId |
| Active subscribers | users with `subscription.expiresAt > now` |

Onboarding completion uses an OR because the field name shifted during
P1-1 (some early users have `skillLevel` but no
`onboardingComplete` flag). We treat either as "they finished
onboarding".

## State + providers

- `analyticsNotifierProvider` (StateNotifier&lt;AnalyticsState&gt;) holds the
  selected range. Calling `setRange` updates state.
- `analyticsSnapshotProvider` (FutureProvider&lt;AnalyticsSnapshot&gt;) reads
  the notifier's state, calls `AdminAnalyticsDataSource.loadAll`, and
  caches by window. Switching range invalidates automatically.
- `AnalyticsRange` enum: 90d, 6m, 12m, YTD.
- The "Refresh" button manually invalidates the snapshot provider —
  useful immediately after a known event (large purchase, broadcast
  campaign).

## Routing

```
RouteName: AdminRoutes.analytics  → AdminRoutes.analyticsPath ('/admin/analytics')
```

Wired into `admin_router.dart` alongside `subscriptions` and
`learning-paths`. Side-nav entry added under "Notifications" with the
`Icons.insights_outlined` icon. Dashboard tile points at the same
route with a non-streaming `_NavTile` — we don't compute the MRR
on every dashboard mount because it requires a full users scan.

## Scaling escape hatch

When active subscribers cross ~10k or enrollments cross ~100k, the
right move is:

1. A nightly Cloud Function writes
   `analytics/monthly/{YYYY-MM}` and `analytics/cohorts/{YYYY-MM}`
   pre-aggregated documents.
2. `AdminAnalyticsDataSource.loadAll` swaps from `.collection('users').get()`
   to `.collection('analytics/monthly/...').get()`.
3. The page UI doesn't change.

Cost of the current implementation at ~5k users, ~1k subscribers,
~20k enrollments: roughly 26k document reads per page load. That's
fine for an admin-only page hit a few times per day.

## Manual testing

1. Sign in as an admin to the web admin portal.
2. Navigate to **Analytics** in the side-nav (or click the dashboard
   "Revenue + cohorts" tile).
3. KPI cards populate within a couple of seconds. MRR should match
   `sum(activeSubscriptionMonthlyValue)`.
4. Toggle the range chooser (90d/6m/12m/YTD). The chart and KPI
   "Revenue (window)" both recompute; MRR stays the same (it's
   point-in-time, not window-dependent).
5. The cohort heat-map should show a triangular shape — the oldest
   row spans all 12 columns, the newest spans 1.
6. Switch to a non-admin instructor account → side-nav hides the
   Analytics entry (the dashboard tile is also gated on `isAdmin`).
7. Sign out → admin guard kicks back to `/login`.

## Files

```
lib/admin/analytics/
  domain/entities/
    revenue_point.dart          RevenuePoint, PlanRevenue, CourseRevenue
    cohort_matrix.dart          CohortMatrix, CohortRow, FunnelCounts
  data/
    analytics_snapshot.dart     AnalyticsSnapshot (combined payload)
    admin_analytics_datasource.dart   loadAll() + private aggregators
  presentation/
    providers/
      analytics_state.dart      AnalyticsRange enum + AnalyticsState
      analytics_notifier.dart   StateNotifier
      analytics_providers.dart  Datasource + notifier + FutureProvider
    widgets/
      revenue_line_chart.dart   Stacked area, fl_chart LineChart
      plan_breakdown_chart.dart BarChart
      cohort_heatmap.dart       Hand-rolled grid (no chart lib)
      funnel_strip.dart         Wrap of stage cards
    pages/
      admin_analytics_page.dart Page assembly + KPI cards
docs/analytics.md
```

## Build steps

After editing the freezed entities:

```
dart run build_runner build --delete-conflicting-outputs
```

to regenerate `revenue_point.freezed.dart` and `cohort_matrix.freezed.dart`.
