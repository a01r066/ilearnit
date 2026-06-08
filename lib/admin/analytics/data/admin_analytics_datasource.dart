import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../features/courses/data/models/course_model.dart';
import '../../../features/purchases/domain/entities/price_tier.dart';
import '../../../features/subscriptions/domain/entities/subscription_plan.dart';
import '../domain/entities/cohort_matrix.dart';
import '../domain/entities/revenue_point.dart';
import 'analytics_snapshot.dart';

/// Computes the admin revenue + cohort dashboard from raw Firestore
/// data.
///
/// Why client-side aggregation?
///   • Admin reads are scoped via Firestore rules — admins can read
///     `users`, `courses`, and `enrollments` collections in full.
///   • The catalogue + paying-user base is small enough at launch
///     (low thousands) that one batched scan is faster than spinning
///     a BigQuery export.
///   • Avoids a Cloud Functions cron + materialized analytics
///     subcollection for the first iteration.
///
/// **Scaling escape hatch:** when active subscribers cross ~10k or
/// enrollments cross ~100k, the right move is a nightly Cloud
/// Function that writes `analytics/monthly/{YYYY-MM}` and
/// `analytics/cohorts/{YYYY-MM}` docs, and have this data source
/// read those pre-aggregated rows. The dashboard UI doesn't change.
class AdminAnalyticsDataSource {
  AdminAnalyticsDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Pull every signal needed for the dashboard. Single network
  /// round-trip per collection — no streaming, no real-time updates.
  /// The admin can hit "Refresh" to re-run.
  Future<AnalyticsSnapshot> loadAll({
    required DateTime windowStart,
    required DateTime windowEnd,
  }) async {
    // 1. Courses — we need title + priceTier to value enrollments.
    final coursesSnap =
        await _firestore.collection(FirestoreCollections.courses).get();
    final priceByCourse = <String, _CoursePricing>{};
    for (final doc in coursesSnap.docs) {
      final c = CourseModel.fromDoc(doc);
      final tier = PriceTier.fromId(c.priceTier);
      priceByCourse[c.id] =
          _CoursePricing(title: c.title, priceUsd: tier.rawFallbackPrice);
    }

    // 2. Enrollments — every paid course purchase. We deliberately do
    //    NOT range-filter in Firestore so we can compute cohort
    //    conversions that span all time; we filter to the window for
    //    revenue at the aggregation step.
    final enrollmentsSnap =
        await _firestore.collection(FirestoreCollections.enrollments).get();

    final enrollments = <_EnrollmentRow>[];
    for (final doc in enrollmentsSnap.docs) {
      final d = doc.data();
      final userId = d['userId'] as String?;
      final courseId = d['courseId'] as String?;
      final createdAtRaw = d['createdAt'];
      if (userId == null || courseId == null || createdAtRaw is! Timestamp) {
        continue;
      }
      enrollments.add(_EnrollmentRow(
        userId: userId,
        courseId: courseId,
        createdAt: createdAtRaw.toDate(),
      ));
    }

    // 3. Users — for cohort signups and subscription valuation.
    final usersSnap =
        await _firestore.collection(FirestoreCollections.users).get();
    final users = <_UserRow>[];
    for (final doc in usersSnap.docs) {
      final d = doc.data();
      final createdAtRaw = d['createdAt'];
      if (createdAtRaw is! Timestamp) continue;

      // Subscription is embedded on the user doc.
      final subRaw = d['subscription'];
      String? planId;
      DateTime? subStartedAt;
      DateTime? subExpiresAt;
      if (subRaw is Map) {
        planId = subRaw['planId'] as String?;
        final startedRaw = subRaw['startedAt'];
        if (startedRaw is Timestamp) subStartedAt = startedRaw.toDate();
        final expiresRaw = subRaw['expiresAt'];
        if (expiresRaw is Timestamp) subExpiresAt = expiresRaw.toDate();
      }

      users.add(_UserRow(
        id: doc.id,
        createdAt: createdAtRaw.toDate(),
        onboarded: d['onboardingComplete'] == true ||
            d['skillLevel'] != null,
        planId: planId,
        subStartedAt: subStartedAt,
        subExpiresAt: subExpiresAt,
      ));
    }

    return _aggregate(
      users: users,
      enrollments: enrollments,
      priceByCourse: priceByCourse,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
  }

  // ----- Aggregators -------------------------------------------------------

  AnalyticsSnapshot _aggregate({
    required List<_UserRow> users,
    required List<_EnrollmentRow> enrollments,
    required Map<String, _CoursePricing> priceByCourse,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    final monthly = <DateTime, RevenuePoint>{};
    for (var m = _firstOfMonth(windowStart);
        !m.isAfter(_firstOfMonth(windowEnd));
        m = DateTime(m.year, m.month + 1, 1)) {
      monthly[m] = RevenuePoint(month: m);
    }

    // ----- Course purchases ----------------------------------------------
    final byCourse = <String, CourseRevenue>{};
    final payingUserIds = <String>{};

    for (final e in enrollments) {
      if (e.createdAt.isBefore(windowStart) ||
          e.createdAt.isAfter(windowEnd)) {
        continue;
      }
      final pricing = priceByCourse[e.courseId];
      // Skip orphaned enrollments where the course was deleted — they'd
      // poison the average price with 0.
      if (pricing == null) continue;

      final monthKey = _firstOfMonth(e.createdAt);
      final bucket = monthly[monthKey];
      if (bucket != null) {
        monthly[monthKey] = bucket.copyWith(
          purchasesUsd: bucket.purchasesUsd + pricing.priceUsd,
        );
      }

      final existing = byCourse[e.courseId] ??
          CourseRevenue(courseId: e.courseId, title: pricing.title);
      byCourse[e.courseId] = existing.copyWith(
        revenueUsd: existing.revenueUsd + pricing.priceUsd,
        purchaseCount: existing.purchaseCount + 1,
      );
      payingUserIds.add(e.userId);
    }

    // ----- Subscription revenue + active counts --------------------------
    final byPlan = <String, PlanRevenue>{};
    var mrrUsd = 0.0;
    var activeSubscribers = 0;
    final now = DateTime.now();

    for (final u in users) {
      final planId = u.planId;
      if (planId == null) continue;
      final plan = SubscriptionPlan.fromId(planId);
      if (plan == null) continue;

      // Per-month USD value (yearly normalized to monthly).
      final monthlyValue = plan.fallbackUsd / plan.billingPeriodMonths;

      // Recognise revenue for every month the subscription was active
      // *within the window*. We don't have payment events, so we
      // straight-line the value across `startedAt..expiresAt`.
      final start = u.subStartedAt ?? u.createdAt;
      final end = u.subExpiresAt ?? now;
      for (var m = _firstOfMonth(start);
          !m.isAfter(_firstOfMonth(end));
          m = DateTime(m.year, m.month + 1, 1)) {
        final bucket = monthly[m];
        if (bucket == null) continue;
        monthly[m] = bucket.copyWith(
          subscriptionsUsd: bucket.subscriptionsUsd + monthlyValue,
        );
      }

      // Count toward MRR only if currently active.
      final isActive = u.subExpiresAt != null &&
          u.subExpiresAt!.isAfter(now);
      if (isActive) {
        mrrUsd += monthlyValue;
        activeSubscribers += 1;
        payingUserIds.add(u.id);
      }

      // Plan-level totals — sum of the per-month values across the
      // window, regardless of "active now". Mirrors how the revenue
      // chart treats it.
      final monthsInWindow = _monthsBetween(
        start.isBefore(windowStart) ? windowStart : start,
        end.isAfter(windowEnd) ? windowEnd : end,
      );
      final planTotal = monthsInWindow * monthlyValue;
      final existing = byPlan[planId] ?? PlanRevenue(planId: planId);
      byPlan[planId] = existing.copyWith(
        revenueUsd: existing.revenueUsd + planTotal,
        activeCount: existing.activeCount + (isActive ? 1 : 0),
      );
    }

    // ----- Cohort matrix --------------------------------------------------
    final cohorts = _buildCohorts(
      users: users,
      enrollments: enrollments,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );

    // ----- Funnel ---------------------------------------------------------
    final funnel = FunnelCounts(
      totalUsers: users.length,
      onboarded: users.where((u) => u.onboarded).length,
      payingUsers: payingUserIds.length,
      activeSubscribers: activeSubscribers,
    );

    // Sort the per-month buckets chronologically.
    final revenueList = monthly.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month));

    final byCourseSorted = byCourse.values.toList()
      ..sort((a, b) => b.revenueUsd.compareTo(a.revenueUsd));
    final byCourseTop = byCourseSorted.take(10).toList();

    final totalRevenue = revenueList.fold<double>(
      0,
      (acc, p) => acc + p.totalUsd,
    );

    return AnalyticsSnapshot(
      revenue: revenueList,
      byPlan: byPlan.values.toList()
        ..sort((a, b) => b.revenueUsd.compareTo(a.revenueUsd)),
      byCourse: byCourseTop,
      cohorts: cohorts,
      funnel: funnel,
      mrrUsd: mrrUsd,
      totalRevenueUsd: totalRevenue,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
  }

  CohortMatrix _buildCohorts({
    required List<_UserRow> users,
    required List<_EnrollmentRow> enrollments,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    // 12 cohort months ending at the window's end month.
    const windowMonths = 12;
    final lastMonth = _firstOfMonth(windowEnd);
    final firstMonth =
        DateTime(lastMonth.year, lastMonth.month - (windowMonths - 1), 1);

    // Cohort buckets: month → users in cohort.
    final cohortUsers = <DateTime, List<_UserRow>>{};
    for (final u in users) {
      final m = _firstOfMonth(u.createdAt);
      if (m.isBefore(firstMonth) || m.isAfter(lastMonth)) continue;
      cohortUsers.putIfAbsent(m, () => []).add(u);
    }

    // First-purchase month per user (the moment they first became
    // "paying"). For subscribers, that's `subStartedAt`. For one-off
    // course buyers, the earliest enrollment.
    final firstPaidMonth = <String, DateTime>{};
    for (final e in enrollments) {
      final m = _firstOfMonth(e.createdAt);
      final cur = firstPaidMonth[e.userId];
      if (cur == null || m.isBefore(cur)) {
        firstPaidMonth[e.userId] = m;
      }
    }
    for (final u in users) {
      if (u.subStartedAt == null) continue;
      final m = _firstOfMonth(u.subStartedAt!);
      final cur = firstPaidMonth[u.id];
      if (cur == null || m.isBefore(cur)) {
        firstPaidMonth[u.id] = m;
      }
    }

    final rows = <CohortRow>[];
    for (var cohortMonth = firstMonth;
        !cohortMonth.isAfter(lastMonth);
        cohortMonth =
            DateTime(cohortMonth.year, cohortMonth.month + 1, 1)) {
      final usersInCohort = cohortUsers[cohortMonth] ?? const [];
      final maxOffset = _monthsBetween(cohortMonth, lastMonth);

      final retained = List<int>.filled(maxOffset + 1, 0);
      for (final u in usersInCohort) {
        final firstPaid = firstPaidMonth[u.id];
        if (firstPaid == null) continue;
        // The user "retains" at every offset >= the month they first
        // became paying (relative to their cohort).
        final firstOffset = _monthsBetween(cohortMonth, firstPaid);
        if (firstOffset < 0 || firstOffset > maxOffset) continue;
        for (var off = firstOffset; off <= maxOffset; off++) {
          retained[off] += 1;
        }
      }

      rows.add(CohortRow(
        cohortMonth: cohortMonth,
        cohortSize: usersInCohort.length,
        retainedByOffset: retained,
      ));
    }

    return CohortMatrix(rows: rows, maxOffset: windowMonths - 1);
  }

  // ----- Helpers -----------------------------------------------------------

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  /// Whole-month delta between two `_firstOfMonth` dates. `to >= from`
  /// is expected; result is non-negative for valid input.
  static int _monthsBetween(DateTime from, DateTime to) {
    final f = _firstOfMonth(from);
    final t = _firstOfMonth(to);
    return (t.year - f.year) * 12 + (t.month - f.month);
  }
}

// ----- Internal row models ------------------------------------------------

class _CoursePricing {
  const _CoursePricing({required this.title, required this.priceUsd});
  final String title;
  final double priceUsd;
}

class _EnrollmentRow {
  const _EnrollmentRow({
    required this.userId,
    required this.courseId,
    required this.createdAt,
  });
  final String userId;
  final String courseId;
  final DateTime createdAt;
}

class _UserRow {
  const _UserRow({
    required this.id,
    required this.createdAt,
    required this.onboarded,
    required this.planId,
    required this.subStartedAt,
    required this.subExpiresAt,
  });
  final String id;
  final DateTime createdAt;
  final bool onboarded;
  final String? planId;
  final DateTime? subStartedAt;
  final DateTime? subExpiresAt;
}
