import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../constants/api_endpoints.dart';
import '../fcm_service.dart';

/// Coordinates FCM topic subscriptions with a mirror on
/// `users/{uid}.subscribedTopics` — that mirror is the source of truth the
/// preferences UI binds to, and survives reinstalls (FCM tokens don't).
class NotificationPreferencesDataSource {
  NotificationPreferencesDataSource({
    required FirebaseFirestore firestore,
    required FcmService fcm,
  })  : _firestore = firestore,
        _fcm = fcm;

  final FirebaseFirestore _firestore;
  final FcmService _fcm;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _firestore.collection(FirestoreCollections.users).doc(userId);

  /// Live stream of the user's currently subscribed topics.
  Stream<Set<String>> watchSubscribedTopics({required String userId}) =>
      _userDoc(userId).snapshots().map((snap) {
        final raw = snap.data()?['subscribedTopics'];
        if (raw is List) {
          return raw.whereType<String>().toSet();
        }
        return const <String>{};
      });

  /// Subscribe to a single topic. Order matters: FCM call first (so a
  /// failure surfaces before we lie in Firestore), then mirror.
  Future<void> subscribe({
    required String userId,
    required String topic,
  }) async {
    await _fcm.subscribeToTopic(topic);
    await _userDoc(userId).set(
      {
        'subscribedTopics': FieldValue.arrayUnion(<String>[topic]),
      },
      SetOptions(merge: true),
    );
  }

  /// Unsubscribe from a single topic. Same FCM-then-mirror order.
  Future<void> unsubscribe({
    required String userId,
    required String topic,
  }) async {
    await _fcm.unsubscribeFromTopic(topic);
    await _userDoc(userId).set(
      {
        'subscribedTopics': FieldValue.arrayRemove(<String>[topic]),
      },
      SetOptions(merge: true),
    );
  }
}
