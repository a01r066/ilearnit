import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/revenue_summary.dart';
import '../models/transaction_model.dart';

/// Read-only Firestore access scoped to a single instructor. Every
/// query attaches `where('instructorId', '==', instructorUid)` so the
/// Firestore security rules and the result set are consistent — the
/// rule denies cross-instructor reads, and our queries never ask for
/// them.
///
/// **What this CAN do:**
///   • Stream the instructor's own transactions.
///   • Compute a RevenueSummary over the instructor's transactions.
///   • Stream the instructor's enrollments (students grouped by
///     course) via the courses + enrollments collection.
///
/// **What this CANNOT do** (by design):
///   • Read another instructor's transactions or enrollments.
///   • Modify any transaction (no setStatus / refund).
///   • Read raw payment details — only the masked [last4] field
///     reaches the client.
class InstructorRevenueDataSource {
  InstructorRevenueDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _txns =>
      _firestore.collection('transactions');

  CollectionReference<Map<String, dynamic>> get _enrollments =>
      _firestore.collection('enrollments');

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection('courses');

  CollectionReference<Map<String, dynamic>> get _payouts =>
      _firestore.collection('payouts');

  /// Live stream of the instructor's transactions, newest first.
  Stream<List<TransactionModel>> watchTransactions(String instructorUid) =>
      _txns
          .where('instructorId', isEqualTo: instructorUid)
          .snapshots()
          .map((s) {
        final list = s.docs.map(TransactionModel.fromDoc).toList();
        // Client-side sort by createdAt desc — avoids a composite
        // index (instructorId, createdAt) the project doesn't have
        // until we deploy it. See firestore.indexes.json for the
        // declared index we'll use once scale demands it.
        list.sort(
          (a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0)),
        );
        return list;
      });

  /// One-shot rollup. Used by the KPI cards on `/my-revenue`.
  Future<RevenueSummary> computeSummary(String instructorUid) async {
    final snap = await _txns
        .where('instructorId', isEqualTo: instructorUid)
        .get();
    final txns = snap.docs.map(TransactionModel.fromDoc).toList();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    double total = 0;
    double month = 0;
    int refunds = 0;
    final byCourseMap = <String, _CourseAcc>{};
    final distinctStudents = <String>{};

    for (final t in txns) {
      if (t.status == 'refunded') {
        refunds += 1;
        continue; // refunded revenue is excluded from the totals
      }
      total += t.amountUsd;
      if ((t.createdAt ?? DateTime(0)).isAfter(monthStart)) {
        month += t.amountUsd;
      }
      distinctStudents.add(t.studentUid);
      final acc = byCourseMap.putIfAbsent(
        t.courseId,
        () => _CourseAcc(t.courseId, t.courseTitle),
      );
      acc.revenue += t.amountUsd;
      acc.enrollments += 1;
    }

    final byCourse = byCourseMap.values
        .map((a) => CourseRevenue(
              courseId: a.courseId,
              courseTitle: a.title,
              revenueUsd: a.revenue,
              enrollments: a.enrollments,
            ))
        .toList()
      ..sort((a, b) => b.revenueUsd.compareTo(a.revenueUsd));

    return RevenueSummary(
      totalRevenueUsd: total,
      monthRevenueUsd: month,
      totalEnrollments:
          txns.where((t) => t.status == 'paid').length,
      totalStudents: distinctStudents.length,
      refundCount: refunds,
      byCourse: byCourse,
    );
  }

  /// Stream the instructor's own course list — used by the students
  /// page to group enrollments by course.
  Stream<List<_MyCourse>> watchMyCourses(String instructorUid) =>
      _courses
          .where('instructorId', isEqualTo: instructorUid)
          .snapshots()
          .map((s) => s.docs
              .map((d) => _MyCourse(
                    id: d.id,
                    title: (d.data()['title'] as String?) ?? '(untitled)',
                    enrollmentCount:
                        (d.data()['enrollmentCount'] as num?)?.toInt() ?? 0,
                  ))
              .toList());

  /// Stream enrollments for one of the instructor's courses. The
  /// Firestore rule cross-checks course.instructorId == uid before
  /// allowing the read — clients can't poke at other instructors'
  /// enrollment lists by swapping the courseId.
  Stream<List<_EnrolledStudent>> watchStudentsForCourse(String courseId) =>
      _enrollments
          .where('courseId', isEqualTo: courseId)
          .snapshots()
          .map((s) {
        final list = s.docs.map((d) {
          final data = d.data();
          return _EnrolledStudent(
            enrollmentId: d.id,
            userId: (data['userId'] as String?) ?? '',
            studentName: (data['studentName'] as String?) ?? '',
            studentEmail: (data['studentEmail'] as String?) ?? '',
            enrolledAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0),
            status: (data['status'] as String?) ?? 'active',
          );
        }).toList();
        list.sort((a, b) => b.enrolledAt.compareTo(a.enrolledAt));
        return list;
      });

  /// Stream the instructor's own payouts.
  Stream<List<Map<String, dynamic>>> watchMyPayoutsRaw(
      String instructorUid) =>
      _payouts
          .where('instructorUid', isEqualTo: instructorUid)
          .snapshots()
          .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
}

class _CourseAcc {
  _CourseAcc(this.courseId, this.title);
  final String courseId;
  final String title;
  double revenue = 0;
  int enrollments = 0;
}

class _MyCourse {
  const _MyCourse({
    required this.id,
    required this.title,
    required this.enrollmentCount,
  });
  final String id;
  final String title;
  final int enrollmentCount;
}

class _EnrolledStudent {
  const _EnrolledStudent({
    required this.enrollmentId,
    required this.userId,
    required this.studentName,
    required this.studentEmail,
    required this.enrolledAt,
    required this.status,
  });
  final String enrollmentId;
  final String userId;
  final String studentName;
  final String studentEmail;
  final DateTime enrolledAt;
  final String status;
}

// Re-export the row classes so the UI layer can consume them without
// depending on the private names. Plain typedefs keep the surface
// uncluttered.
typedef MyCourseRow = _MyCourse;
typedef EnrolledStudentRow = _EnrolledStudent;
