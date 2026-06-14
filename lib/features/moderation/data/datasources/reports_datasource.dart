import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/report_content_type.dart';
import '../../domain/entities/report_reason.dart';
import '../../domain/entities/report_status.dart';
import '../models/report_model.dart';

/// Coordinates Firestore reads + writes for the global
/// `reports/{reportId}` collection.
///
/// **Visibility model.** The collection is global (not nested under
/// reporter or reportee) so moderators can stream open reports with
/// one query. Firestore rules deny all non-moderator reads.
///
/// **Idempotency.** A user reporting the same content twice is a
/// no-op — we look up an existing open report from the same reporter
/// for the same `contentPath` before writing a new one. This stops the
/// admin queue from ballooning when a serial reporter rage-clicks.
class ReportsDataSource {
  ReportsDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  // ---------- Writes -----------------------------------------------------

  /// Submit a report. Returns the report id (existing or new). If the
  /// reporter already has an open report on the same content, the
  /// existing id is returned without a write.
  Future<String> submit({
    required ReportContentType contentType,
    required String contentId,
    required String contentPath,
    String? courseId,
    String? lectureId,
    required String contentSnapshot,
    required String authorId,
    String authorName = '',
    required String reporterId,
    String reporterName = '',
    required ReportReason reason,
    String reporterNotes = '',
  }) async {
    final existing = await _reports
        .where('reporterId', isEqualTo: reporterId)
        .where('contentPath', isEqualTo: contentPath)
        .where('status', isEqualTo: ReportStatus.open.id)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final ref = _reports.doc();
    await ref.set({
      'contentType': contentType.id,
      'contentId': contentId,
      'contentPath': contentPath,
      if (courseId != null) 'courseId': courseId,
      if (lectureId != null) 'lectureId': lectureId,
      'contentSnapshot': _truncate(contentSnapshot, 280),
      'authorId': authorId,
      'authorName': authorName,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reason': reason.id,
      'reporterNotes': _truncate(reporterNotes, 500),
      'status': ReportStatus.open.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Resolve a report. Called from the moderator queue with one of
  /// [ReportStatus.actionTaken] or [ReportStatus.dismissed].
  Future<void> resolve({
    required String reportId,
    required ReportStatus status,
    required String reviewerId,
    String reviewerName = '',
    String resolutionNotes = '',
  }) {
    assert(status != ReportStatus.open, 'use submit() to (re)open a report');
    return _reports.doc(reportId).set({
      'status': status.id,
      'reviewedBy': reviewerId,
      'reviewedByName': reviewerName,
      'reviewedAt': FieldValue.serverTimestamp(),
      'resolutionNotes': _truncate(resolutionNotes, 500),
    }, SetOptions(merge: true));
  }

  // ---------- Reads ------------------------------------------------------

  /// Open queue, newest first. Admin portal uses this directly;
  /// moderators get this filtered by courseId in the page-level
  /// notifier (see ModeratorReportsNotifier).
  Stream<List<ReportModel>> watchOpen({int limit = 200}) => _reports
      .where('status', isEqualTo: ReportStatus.open.id)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs.map(ReportModel.fromDoc).toList());

  /// Open reports scoped to a list of course ids. Empty list → empty
  /// stream (Firestore disallows `in` queries on empty arrays).
  Stream<List<ReportModel>> watchOpenForCourses(
    List<String> courseIds, {
    int limit = 200,
  }) {
    if (courseIds.isEmpty) return const Stream.empty();
    // Firestore `whereIn` caps at 10; chunk if you ever exceed that.
    final chunk = courseIds.take(10).toList();
    return _reports
        .where('status', isEqualTo: ReportStatus.open.id)
        .where('courseId', whereIn: chunk)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ReportModel.fromDoc).toList());
  }

  /// Live count of open reports, for the admin side-nav badge. Reads
  /// the `_aggregates/openCount` doc that the `onReportCreated` Cloud
  /// Function maintains. Falls back to 0 if the doc hasn't been
  /// initialized yet.
  Stream<int> watchOpenCount() => _reports
      .doc('_aggregates')
      .snapshots()
      .map((snap) => (snap.data()?['openCount'] as num?)?.toInt() ?? 0);

  // ---------- Helpers ----------------------------------------------------

  static String _truncate(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);
}
