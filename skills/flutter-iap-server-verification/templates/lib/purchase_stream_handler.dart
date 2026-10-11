import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;

import 'purchase_verification_datasource.dart';

enum GrantStatus { pending, granted, failed }

class GrantEvent {
  const GrantEvent(this.itemId, this.status);
  final String? itemId;
  final GrantStatus status;
}

/// Owns the ONE subscription to `InAppPurchase.purchaseStream` for
/// consumable tiers. Create it eagerly at app start (read its provider in
/// bootstrap.dart) — the OS can deliver unfinished transactions before any
/// store UI exists, and a lazily-created listener loses them.
///
/// Subscriptions and non-consumables use their own handlers on the same
/// stream and must skip products they don't own (see [_isMine]).
class TierPurchaseHandler {
  TierPurchaseHandler({
    required iap.InAppPurchase store,
    required PurchaseVerificationDataSource verifier,
    required FirebaseAuth auth,
    required String tierPrefix,
  })  : _store = store, _verifier = verifier, _auth = auth, _tierPrefix = tierPrefix {
    _sub = _store.purchaseStream.listen(_onBatch);
  }

  final iap.InAppPurchase _store;
  final PurchaseVerificationDataSource _verifier;
  final FirebaseAuth _auth;
  final String _tierPrefix;
  late final StreamSubscription<List<iap.PurchaseDetails>> _sub;
  final _events = StreamController<GrantEvent>.broadcast();

  /// productId → itemId the user tapped (lost on app kill; the server's
  /// purchase_intent covers that case).
  final Map<String, String> _hints = {};

  Stream<GrantEvent> get events => _events.stream;

  bool _isMine(iap.PurchaseDetails p) => p.productID.startsWith(_tierPrefix);

  Future<void> buy(String itemId) async {
    // Server picks the product from the item's tier.
    final productId = await _verifier.createIntent(itemId);
    final details = await _store.queryProductDetails({productId});
    if (details.productDetails.isEmpty) {
      throw const PurchaseVerificationException('not-found', 'Product unavailable');
    }
    _hints[productId] = itemId;
    await _store.buyConsumable(
      purchaseParam: iap.PurchaseParam(
        productDetails: details.productDetails.first,
        applicationUserName: _auth.currentUser?.uid,
      ),
      // Consume server-side AFTER granting; never let the plugin auto-consume.
      autoConsume: false,
    );
  }

  Future<void> _onBatch(List<iap.PurchaseDetails> batch) async {
    for (final p in batch) {
      if (_isMine(p)) await _handle(p);
    }
  }

  Future<void> _handle(iap.PurchaseDetails p) async {
    final hint = _hints[p.productID];
    switch (p.status) {
      case iap.PurchaseStatus.pending:
        _events.add(GrantEvent(hint, GrantStatus.pending)); // Ask to Buy / slow card
        return;
      case iap.PurchaseStatus.canceled:
      case iap.PurchaseStatus.error:
        // StoreKit keeps failed transactions queued until finished; an open
        // one blocks the next purchase of the same product.
        await _complete(p);
        _hints.remove(p.productID);
        _events.add(GrantEvent(hint, GrantStatus.failed));
        return;
      case iap.PurchaseStatus.purchased:
      case iap.PurchaseStatus.restored:
        break;
    }

    // Cold start: wait for Auth to restore the session before deciding.
    final user = _auth.currentUser ?? await _auth.authStateChanges().first;
    if (user == null) return; // leave open; re-delivered after sign-in

    try {
      final g = await _verifier.verifyTier(p, itemIdHint: hint);
      _hints.remove(p.productID);
      if (!g.consumed) await _complete(p);
      _events.add(GrantEvent(g.itemId, GrantStatus.granted));
    } on PurchaseVerificationException catch (e) {
      if (!e.retryable) {
        _hints.remove(p.productID);
        // iOS: finish so a bad receipt doesn't loop forever (server logged
        // it). Android: leave unacknowledged — Play auto-refunds in 3 days.
        if (PurchaseVerificationDataSource.platform == 'ios') await _complete(p);
      }
      _events.add(GrantEvent(hint, GrantStatus.failed));
    } catch (_) {
      _events.add(GrantEvent(hint, GrantStatus.failed)); // unknown → retryable
    }
  }

  Future<void> _complete(iap.PurchaseDetails p) async {
    if (!p.pendingCompletePurchase) return;
    try {
      await _store.completePurchase(p);
    } catch (_) {/* re-delivered next pump */}
  }

  void dispose() {
    _sub.cancel();
    _events.close();
  }
}
