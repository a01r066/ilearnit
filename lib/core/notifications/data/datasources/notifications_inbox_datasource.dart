import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../constants/api_endpoints.dart';
import '../models/notification_item_model.dart';

/// Read + write side of the in-app notification inbox.
///
/// Live at `users/{uid}/notifications/{id}`, ordered by `createdAt desc`.
/// Items are created by Cloud Functions in parallel to the FCM send so the
/// inbox stays in sync regardless of OS notification permission.
class NotificationsInboxDataSource {
  NotificationsInboxDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) => _firestore
      .collection(FirestoreCollections.users)
      .doc(userId)
      .collection('notifications');

  /// Live list of all inbox items, newest first. Capped at 50 so a
  /// rarely-opened inbox doesn't balloon the snapshot payload.
  Stream<List<NotificationItemModel>> watchInbox({
    required String userId,
    int limit = 50,
  }) =>
      _col(userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) =>
              snap.docs.map(NotificationItemModel.fromDoc).toList());

  /// Live count of unread items. Backs the bell badge.
  Stream<int> watchUnreadCount({required String userId}) => _col(userId)
      .where('readAt', isNull: true)
      .snapshots()
      .map((snap) => snap.docs.length);

  /// Mark one item as read by stamping `readAt = serverTimestamp`.
  /// Idempotent — re-running on an already-read doc is a no-op.
  Future<void> markRead({
    required String userId,
    required String notificationId,
  }) =>
      _col(userId).doc(notificationId).set(
        {'readAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

  /// Sweep all unread items. We page through 200 at a time so a long-
  /// neglected inbox still completes within Firestore's batch limit.
  Future<void> markAllRead({required String userId}) async {
    while (true) {
      final snap = await _col(userId)
          .where('readAt', isNull: true)
          .limit(200)
          .get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final d in snap.docs) {
        batch.set(
          d.reference,
          {'readAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      if (snap.docs.length < 200) return;
    }
  }

  /// Hard-delete a single inbox item. Used by the swipe-to-dismiss action.
  Future<void> delete({
    required String userId,
    required String notificationId,
  }) =>
      _col(userId).doc(notificationId).delete();

  /// Clear the entire inbox. Surfaced as an overflow action.
  Future<void> clearAll({required String userId}) async {
    while (true) {
      final snap = await _col(userId).limit(200).get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      if (snap.docs.length < 200) return;
    }
  }
}
