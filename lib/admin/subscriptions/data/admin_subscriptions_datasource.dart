import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../features/auth/data/models/user_model.dart';
import '../../../features/subscriptions/data/models/subscription_model.dart';

/// One row in the admin subscriptions table — the user plus their parsed
/// subscription map.
class SubscriberRow {
  const SubscriberRow({required this.user, required this.subscription});
  final UserModel user;
  final SubscriptionModel subscription;
}

/// Admin-side read + minimal-write for the `users/{uid}.subscription`
/// embedded map.
///
/// Because the subscription is an *embedded* map on the user doc (not its
/// own collection), every query is over the `users` collection. We can't
/// `where('subscription.expiresAt', >, now)` directly without a
/// composite index — so we pull all users with a `subscription.planId`
/// set and filter by `expiresAt` client-side. Fine for a few hundred
/// active subscribers; switch to a denormalized `subscriptions/{uid}`
/// collection when that grows.
class AdminSubscriptionsDataSource {
  AdminSubscriptionsDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  /// Stream every user with a populated subscription map (any state).
  /// The page filters to "active" client-side from this list.
  Stream<List<SubscriberRow>> watchAll() {
    return _users
        .where('subscription.planId', whereIn: ['monthly', 'yearly'])
        .snapshots()
        .map((snap) {
      final out = <SubscriberRow>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final raw = data['subscription'];
        if (raw is! Map) continue;
        final sub = SubscriptionModel.fromJson(
          Map<String, dynamic>.from(raw),
        );
        out.add(SubscriberRow(
          user: UserModel.fromDoc(doc),
          subscription: sub,
        ));
      }
      return out;
    });
  }

  /// Hard-revoke: set `expiresAt` to now + flip auto-renew off. The user
  /// loses access immediately (their `SubscriptionStatus.isActive` flips
  /// false). The IAP entitlement on Apple/Google is untouched — those
  /// have to be cancelled in OS settings; this just removes our local
  /// gate.
  Future<void> revokeNow(String uid) async {
    await _users.doc(uid).set(
      {
        'subscription': {
          'expiresAt': Timestamp.fromDate(DateTime.now()),
          'autoRenew': false,
          'canceledAt': Timestamp.fromDate(DateTime.now()),
        },
      },
      SetOptions(merge: true),
    );
  }

  /// Extend the current entitlement by [days] days from whichever is
  /// later: now, or the current `expiresAt`. Useful for support
  /// goodwill grants.
  Future<void> extendByDays(String uid, int days) async {
    final doc = await _users.doc(uid).get();
    final raw = (doc.data() ?? {})['subscription'];
    if (raw is! Map) return;
    final current = SubscriptionModel.fromJson(
      Map<String, dynamic>.from(raw),
    );
    final base = (current.expiresAt != null &&
            current.expiresAt!.isAfter(DateTime.now()))
        ? current.expiresAt!
        : DateTime.now();
    final newExpiry = base.add(Duration(days: days));
    await _users.doc(uid).set(
      {
        'subscription': {
          'expiresAt': Timestamp.fromDate(newExpiry),
        },
      },
      SetOptions(merge: true),
    );
  }
}
