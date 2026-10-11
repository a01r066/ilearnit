import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/subscription_status.dart';
import '../models/subscription_model.dart';

/// Reads the embedded `subscription` map on `users/{uid}`.
///
/// Read-only: the map is written exclusively by the `verifySubscription`
/// Cloud Function after the store receipt is validated. firestore.rules
/// reject client writes to `subscription`.
class SubscriptionFirestoreDataSource {
  SubscriptionFirestoreDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  Stream<SubscriptionStatus> watch(String uid) =>
      _users.doc(uid).snapshots().map((doc) {
        final data = doc.data() ?? const <String, dynamic>{};
        final raw = data['subscription'];
        if (raw is! Map) return const SubscriptionStatus();
        return SubscriptionModel.fromJson(Map<String, dynamic>.from(raw))
            .toEntity();
      });

  Future<SubscriptionStatus> fetch(String uid) async {
    final doc = await _users.doc(uid).get();
    final raw = (doc.data() ?? {})['subscription'];
    if (raw is! Map) return const SubscriptionStatus();
    return SubscriptionModel.fromJson(Map<String, dynamic>.from(raw))
        .toEntity();
  }
}
