import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../data/datasources/admin_revenue_datasource.dart';
import '../../data/datasources/instructor_revenue_datasource.dart';
import '../../data/models/payout_model.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/entities/revenue_summary.dart';

// ── Datasource singletons ────────────────────────────────────────────

final instructorRevenueDataSourceProvider =
    Provider<InstructorRevenueDataSource>(
  (ref) => InstructorRevenueDataSource(
    firestore: ref.watch(firestoreProvider),
  ),
);

final adminRevenueDataSourceProvider = Provider<AdminRevenueDataSource>(
  (ref) => AdminRevenueDataSource(
    firestore: ref.watch(firestoreProvider),
    functions: FirebaseFunctions.instance,
  ),
);

// ── Instructor-side reads ────────────────────────────────────────────

/// Family by instructor uid — the consumer page passes the current
/// user's id in. AutoDispose so leaving the page tears down the stream.
final instructorTransactionsStreamProvider = StreamProvider.autoDispose
    .family<List<TransactionModel>, String>(
  (ref, instructorUid) =>
      ref.watch(instructorRevenueDataSourceProvider).watchTransactions(instructorUid),
);

final instructorRevenueSummaryProvider = FutureProvider.autoDispose
    .family<RevenueSummary, String>(
  (ref, instructorUid) =>
      ref.watch(instructorRevenueDataSourceProvider).computeSummary(instructorUid),
);

final instructorOwnCoursesStreamProvider = StreamProvider.autoDispose
    .family<List<MyCourseRow>, String>(
  (ref, instructorUid) =>
      ref.watch(instructorRevenueDataSourceProvider).watchMyCourses(instructorUid),
);

final courseStudentsStreamProvider = StreamProvider.autoDispose
    .family<List<EnrolledStudentRow>, String>(
  (ref, courseId) =>
      ref.watch(instructorRevenueDataSourceProvider).watchStudentsForCourse(courseId),
);

// ── Admin-side reads ─────────────────────────────────────────────────

final adminAllTransactionsStreamProvider = StreamProvider.autoDispose
    .family<List<TransactionModel>, String?>(
  (ref, statusFilter) => ref
      .watch(adminRevenueDataSourceProvider)
      .watchAllTransactions(statusFilter: statusFilter),
);

final adminAllPayoutsStreamProvider =
    StreamProvider.autoDispose<List<PayoutModel>>(
  (ref) => ref.watch(adminRevenueDataSourceProvider).watchAllPayouts(),
);
