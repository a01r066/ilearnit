import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/api_endpoints.dart';
import '../domain/entities/application_status.dart';
import '../domain/entities/instructor_application.dart';

/// Firestore-backed datasource for the `instructor_applications` collection
/// and the related `users/{uid}.role` mutation on approval.
///
/// All methods stream/read from Firestore directly; in admin/web flows we
/// want immediate live updates so caching layers would be more hindrance
/// than help.
class InstructorApplicationDataSource {
  InstructorApplicationDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection(FirestoreCollections.instructorApplications);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  // ---------- queries -----------------------------------------------------

  /// Stream the current user's application, or `null` if they have never
  /// applied.
  Stream<InstructorApplication?> watchMine(String userId) =>
      _applications.doc(userId).snapshots().map(
            (doc) => doc.exists ? _fromDoc(doc) : null,
          );

  /// Stream every pending application (admin view).
  Stream<List<InstructorApplication>> watchPending() => _applications
      .where('status', isEqualTo: ApplicationStatus.pending.id)
      .orderBy('appliedAt')
      .snapshots()
      .map((s) => s.docs.map(_fromDoc).toList());

  /// Stream all applications regardless of status (admin history view).
  Stream<List<InstructorApplication>> watchAll() => _applications
      .orderBy('appliedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(_fromDoc).toList());

  // ---------- mutations ---------------------------------------------------

  /// Submit a new application. Overwrites any prior `rejected` application
  /// from the same user so they can re-apply.
  Future<void> submit(InstructorApplication app) async {
    await _applications.doc(app.userId).set({
      ..._toJson(app),
      'status': ApplicationStatus.pending.id,
      'appliedAt': FieldValue.serverTimestamp(),
      'decidedAt': null,
      'decidedBy': null,
      'rejectionReason': null,
    });
  }

  /// Approve an application: marks it approved AND promotes the user's
  /// `users/{uid}.role` to `instructor`. Both writes happen in a batch so
  /// they're atomic.
  Future<void> approve({
    required String applicationId,
    required String adminUid,
  }) async {
    final batch = _firestore.batch();
    batch.update(_applications.doc(applicationId), {
      'status': ApplicationStatus.approved.id,
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': adminUid,
      'rejectionReason': null,
    });
    batch.set(
      _users.doc(applicationId),
      {'role': 'instructor', 'isSuspended': false},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// Reject an application with an optional reason. The user's `role` is
  /// untouched (stays `student`).
  Future<void> reject({
    required String applicationId,
    required String adminUid,
    String? reason,
  }) async {
    await _applications.doc(applicationId).update({
      'status': ApplicationStatus.rejected.id,
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': adminUid,
      'rejectionReason': reason,
    });
  }

  // ---------- mapping -----------------------------------------------------

  InstructorApplication _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return InstructorApplication(
      id: doc.id,
      userId: d['userId'] as String? ?? doc.id,
      displayName: d['displayName'] as String? ?? '',
      email: d['email'] as String? ?? '',
      bio: d['bio'] as String? ?? '',
      instruments:
          (d['instruments'] as List?)?.whereType<String>().toList() ?? const [],
      years: (d['years'] as num?)?.toInt(),
      portfolioUrl: d['portfolioUrl'] as String?,
      status: ApplicationStatus.fromId(d['status'] as String?),
      rejectionReason: d['rejectionReason'] as String?,
      appliedAt: (d['appliedAt'] as Timestamp?)?.toDate(),
      decidedAt: (d['decidedAt'] as Timestamp?)?.toDate(),
      decidedBy: d['decidedBy'] as String?,
    );
  }

  Map<String, dynamic> _toJson(InstructorApplication a) => {
        'userId': a.userId,
        'displayName': a.displayName,
        'email': a.email,
        'bio': a.bio,
        'instruments': a.instruments,
        'years': a.years,
        'portfolioUrl': a.portfolioUrl,
      };
}
