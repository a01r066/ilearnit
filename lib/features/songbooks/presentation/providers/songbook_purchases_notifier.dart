import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;

import '../../../../l10n/l10n.dart';
import '../../../purchases/data/datasources/iap_remote_datasource.dart';
import '../../../purchases/data/datasources/purchase_verification_datasource.dart';
import 'songbook_purchases_state.dart';

/// Songbook IAP: non-consumable, one product per songbook
/// (`songbooks/{id}.productId`, prefix [productPrefix]).
///
/// Listens to the shared purchase stream (course tiers and subscriptions
/// are handled by their own notifiers and ignored here), sends each
/// songbook transaction to `verifySongbookPurchase`, and only finishes the
/// store transaction once the server has granted ownership. Ownership is
/// read from Firestore (`ownedSongbookIdsProvider`).
class SongbookPurchasesNotifier extends StateNotifier<SongbookPurchasesState> {
  SongbookPurchasesNotifier({
    required IapRemoteDataSource iap,
    required PurchaseVerificationDataSource verifier,
    required FirebaseAuth auth,
  })  : _iap = iap,
        _verifier = verifier,
        _auth = auth,
        super(const SongbookPurchasesState()) {
    _sub = _iap.purchaseStream.listen(_onUpdates);
  }

  static const productPrefix = 'info.ilearnit.songbook.';

  final IapRemoteDataSource _iap;
  final PurchaseVerificationDataSource _verifier;
  final FirebaseAuth _auth;
  StreamSubscription<List<iap.PurchaseDetails>>? _sub;

  /// Load the localized price for [productId] (no-op if already known).
  Future<void> loadPrice(String productId) async {
    if (productId.isEmpty || state.priceByProductId.containsKey(productId)) {
      return;
    }
    try {
      final products = await _iap.fetchProducts({productId});
      final p = products[productId];
      if (p != null && mounted) {
        state = state.copyWith(
          priceByProductId: {...state.priceByProductId, productId: p.price},
        );
      }
    } catch (_) {
      // Price stays unknown — the button shows without a price.
    }
  }

  Future<void> buy(String productId) async {
    if (state.isBuying(productId)) return;
    state = state.copyWith(
      inFlight: {...state.inFlight, productId},
      clearError: true,
    );
    try {
      await _iap.buyNonConsumable(
        productId: productId,
        applicationUserName: _auth.currentUser?.uid,
      );
    } catch (_) {
      _done(productId, error: L10n.current.purchaseStoreDeclined);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> _onUpdates(List<iap.PurchaseDetails> updates) async {
    for (final p in updates) {
      if (!p.productID.startsWith(productPrefix)) continue;
      switch (p.status) {
        case iap.PurchaseStatus.pending:
          break; // Ask to Buy / slow card — wait for the next update.
        case iap.PurchaseStatus.canceled:
          await _complete(p);
          _done(p.productID);
        case iap.PurchaseStatus.error:
          await _complete(p);
          _done(p.productID, error: L10n.current.purchaseFailed);
        case iap.PurchaseStatus.purchased:
        case iap.PurchaseStatus.restored:
          await _verify(p);
      }
    }
  }

  Future<void> _verify(iap.PurchaseDetails p) async {
    final user = _auth.currentUser ?? await _auth.authStateChanges().first;
    if (user == null) {
      // Left open; re-delivered after sign-in / on restore.
      _done(p.productID);
      return;
    }
    try {
      await _verifier.verifySongbook(p);
      await _complete(p);
      _done(p.productID);
    } on PurchaseVerificationException catch (e) {
      if (!e.retryable && PurchaseVerificationDataSource.platform == 'ios') {
        await _complete(p);
      }
      _done(
        p.productID,
        error: e.code == 'permission-denied' && e.message.contains('another account')
            ? L10n.current.songbookOtherAccount
            : L10n.current.purchaseFailed,
      );
    } catch (_) {
      _done(p.productID, error: L10n.current.purchaseFailed);
    }
  }

  Future<void> _complete(iap.PurchaseDetails p) async {
    if (!p.pendingCompletePurchase) return;
    try {
      await _iap.completePurchase(p);
    } catch (_) {}
  }

  void _done(String productId, {String? error}) {
    if (!mounted) return;
    state = state.copyWith(
      inFlight: state.inFlight.difference({productId}),
      lastError: error,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
