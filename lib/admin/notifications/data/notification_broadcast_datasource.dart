import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed datasource for admin-authored notification broadcasts.
///
/// Writing a doc to `notification_broadcasts/{id}` triggers the
/// `onNotificationBroadcast` Cloud Function (see `functions/src/index.ts`),
/// which fans the message out to FCM and stamps `sentAt` back on the doc.
class NotificationBroadcastDataSource {
  NotificationBroadcastDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _broadcasts =>
      _firestore.collection('notification_broadcasts');

  Future<String> send({
    required String topic,
    required String title,
    required String body,
    required String createdBy,
    String? route,
  }) async {
    final doc = _broadcasts.doc();
    await doc.set({
      'topic': topic,
      'title': title,
      'body': body,
      'route': route,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'sentAt': null,
      'status': 'pending', // → 'sent' | 'failed', written by the Function
      'failureReason': null,
    });
    return doc.id;
  }

  /// Stream the most recent broadcasts so the admin sees a history /
  /// confirmation that the Function picked their request up.
  Stream<List<BroadcastRecord>> watchRecent({int limit = 20}) => _broadcasts
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(BroadcastRecord.fromDoc).toList());
}

class BroadcastRecord {
  const BroadcastRecord({
    required this.id,
    required this.topic,
    required this.title,
    required this.body,
    required this.status,
    this.route,
    this.createdAt,
    this.sentAt,
    this.failureReason,
  });

  factory BroadcastRecord.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const <String, dynamic>{};
    return BroadcastRecord(
      id: doc.id,
      topic: d['topic'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      route: d['route'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      sentAt: (d['sentAt'] as Timestamp?)?.toDate(),
      failureReason: d['failureReason'] as String?,
    );
  }

  final String id;
  final String topic;
  final String title;
  final String body;
  final String status;
  final String? route;
  final DateTime? createdAt;
  final DateTime? sentAt;
  final String? failureReason;
}
