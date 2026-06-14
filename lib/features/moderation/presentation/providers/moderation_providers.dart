import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/blocks_datasource.dart';
import '../../data/datasources/reports_datasource.dart';
import '../../data/models/report_model.dart';

// ---------- Datasources --------------------------------------------------

final reportsDataSourceProvider = Provider<ReportsDataSource>(
  (ref) => ReportsDataSource(ref.watch(firestoreProvider)),
);

final blocksDataSourceProvider = Provider<BlocksDataSource>(
  (ref) => BlocksDataSource(ref.watch(firestoreProvider)),
);

// ---------- Block list --------------------------------------------------

/// Live set of uids the signed-in user has blocked. Empty when signed
/// out — guest browsing never sees anyone's content filtered.
///
/// Consumed by every UGC list surface (`CourseReviewsSection`,
/// `LectureQASection`, `LectureNotesSection`, etc.) to drop items
/// whose `authorId` is in the set. Stream-based so unblocking
/// reappears the content instantly.
final blockedUserIdsProvider =
    StreamProvider.autoDispose<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <String>{});
  return ref.watch(blocksDataSourceProvider).watch(ownerUid: user.id);
});

// ---------- Reports queue (admin) ---------------------------------------

/// Global open queue. Admin portal consumes this directly. Empty +
/// throws permission-denied if a non-admin reads — the admin route
/// gate prevents that case.
final openReportsProvider =
    StreamProvider.autoDispose<List<ReportModel>>((ref) {
  return ref.watch(reportsDataSourceProvider).watchOpen();
});

/// Live badge count for the admin side-nav. 0 when the aggregates
/// doc hasn't been initialized yet (first report ever).
final openReportsCountProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(reportsDataSourceProvider).watchOpenCount();
});

/// Reports scoped to a list of course ids — used by the in-app
/// `/moderator` page when the signed-in user is a moderator (not
/// admin). Admins get the unscoped [openReportsProvider] instead.
final openReportsForCoursesProvider = StreamProvider.autoDispose
    .family<List<ReportModel>, List<String>>((ref, courseIds) {
  return ref
      .watch(reportsDataSourceProvider)
      .watchOpenForCourses(courseIds);
});
