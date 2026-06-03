import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_status.dart';
import '../models/subscription_model.dart';

/// Reads + writes the embedded `subscription` map on `users/{uid}`.
///
/// "Trust the client" model — the mobile app writes directly after a
/// successful IAP. Firestore rules (see `docs/subscriptions.md`) only let a
/// user write their own subscription map.
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

  /// Persist a freshly-purchased subscription. We compute `expiresAt`
  /// client-side as a best-effort; a server-side verifier would replace
  /// this with the value from the receipt.
  Future<void> recordPurchase({
    required String uid,
    required SubscriptionPlan plan,
    required String platform,
    required String originalTransactionId,
    DateTime? startedAt,
  }) async {
    final start = startedAt ?? DateTime.now();
    final end = _addMonths(start, plan.billingPeriodMonths);
    final model = SubscriptionModel(
      planId: plan.id,
      productId: plan.productId,
      startedAt: start,
      expiresAt: end,
      autoRenew: true,
      canceledAt: null,
      platform: platform,
      originalTransactionId: originalTransactionId,
    );
    await _users.doc(uid).set(
      {'subscription': model.toJson()},
      SetOptions(merge: true),
    );
  }

  /// Flag auto-renew off but leave the entitlement in place until
  /// `expiresAt`. iOS actually surfaces the cancellation through a new
  /// receipt — this is just a UI hint while we wait for that signal.
  Future<void> markAutoRenewOff(String uid) async {
    await _users.doc(uid).set(
      {
        'subscription': {
          'autoRenew': false,
          'canceledAt': Timestamp.fromDate(DateTime.now()),
        },
      },
      SetOptions(merge: true),
    );
  }

  Future<SubscriptionStatus> fetch(String uid) async {
    final doc = await _users.doc(uid).get();
    final raw = (doc.data() ?? {})['subscription'];
    if (raw is! Map) return const SubscriptionStatus();
    return SubscriptionModel.fromJson(Map<String, dynamic>.from(raw))
        .toEntity();
  }

  static DateTime _addMonths(DateTime d, int months) {
    final year = d.year + ((d.month - 1 + months) ~/ 12);
    final month = (d.month - 1 + months) % 12 + 1;
    final day = d.day.clamp(1, _lastDayOfMonth(year, month));
    return DateTime(year, month, day, d.hour, d.minute, d.second);
  }

  static int _lastDayOfMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}
