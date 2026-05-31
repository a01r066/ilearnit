import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;

import '../../../../core/error/error_mapper.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/subscription_firestore_datasource.dart';
import '../../../purchases/data/datasources/iap_remote_datasource.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_status.dart';
import 'subscription_state.dart';

/// Owns the subscription lifecycle on the client.
///
/// Wiring:
///   1. On construction, fetches store ProductDetails for both plans.
///   2. Listens to the IAP `purchaseStream` and filters by subscription
///      product ids — when one fires `purchased | restored`, writes the
///      entitlement to `users/{uid}.subscription` and completes the txn.
///   3. Subscribes to Firestore so the UI always reflects authoritative
///      state, not optimistic state.
///
/// The existing [PurchasesNotifier] handles per-course purchases on the
/// same stream — both notifiers coexist by filtering on productId.
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier({
    required IapRemoteDataSource iap,
    required SubscriptionFirestoreDataSource firestore,
    required UserEntity? user,
  })  : _iap = iap,
        _firestore = firestore,
        _user = user,
        super(const SubscriptionState()) {
    _init();
  }

  final IapRemoteDataSource _iap;
  final SubscriptionFirestoreDataSource _firestore;
  final UserEntity? _user;

  StreamSubscription<List<iap.PurchaseDetails>>? _iapSub;
  StreamSubscription<SubscriptionStatus>? _statusSub;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);

    // 1. Live status from Firestore.
    if (_user != null) {
      _statusSub = _firestore.watch(_user.id).listen(
            (s) => state = state.copyWith(status: s),
            onError: (Object e, StackTrace st) {
              state = state.copyWith(lastFailure: mapToFailure(e, st));
            },
          );
    }

    // 2. Localized prices.
    try {
      final products =
          await _iap.fetchProducts(SubscriptionPlan.allProductIds);
      state = state.copyWith(
        priceByProductId: {
          for (final p in products.values) p.productId: p.price,
        },
      );
    } catch (e, st) {
      state = state.copyWith(lastFailure: mapToFailure(e, st));
    }

    // 3. Listen to purchase stream — filter to our subscription products.
    _iapSub = _iap.purchaseStream.listen(_onPurchaseUpdates);

    state = state.copyWith(isLoading: false);
  }

  /// Trigger the store purchase flow for [plan]. The actual entitlement
  /// write happens later, when the purchase stream emits `purchased`.
  Future<void> buy(SubscriptionPlan plan) async {
    if (state.purchaseInFlight) return;
    state = state.copyWith(purchaseInFlight: true, clearFailure: true);
    try {
      await _iap.buyNonConsumable(
        productId: plan.productId,
        applicationUserName: _user?.id,
      );
    } catch (e, st) {
      state = state.copyWith(
        purchaseInFlight: false,
        lastFailure: mapToFailure(e, st),
      );
    }
  }

  /// Replay past purchases from the store. Used when a user reinstalls
  /// the app — the store re-emits their active subscription.
  Future<void> restore() async {
    state = state.copyWith(clearFailure: true);
    try {
      await _iap.restorePurchases();
    } catch (e, st) {
      state = state.copyWith(lastFailure: mapToFailure(e, st));
    }
  }

  /// "Cancel" in-app just means turning auto-renew off in Firestore for
  /// the UI hint. The user still has to cancel in the OS settings (App
  /// Store / Play Store) — we surface that link in the docs.
  Future<void> markAutoRenewOff() async {
    final uid = _user?.id;
    if (uid == null) return;
    try {
      await _firestore.markAutoRenewOff(uid);
    } catch (e, st) {
      state = state.copyWith(lastFailure: mapToFailure(e, st));
    }
  }

  void clearFailure() {
    if (state.lastFailure == null) return;
    state = state.copyWith(clearFailure: true);
  }

  // ---------- purchase stream handler ------------------------------------

  Future<void> _onPurchaseUpdates(List<iap.PurchaseDetails> updates) async {
    for (final p in updates) {
      final plan = SubscriptionPlan.fromProductId(p.productID);
      if (plan == null) continue; // not a subscription update — ignore

      switch (p.status) {
        case iap.PurchaseStatus.pending:
          // keep the in-flight flag, wait for terminal state
          break;
        case iap.PurchaseStatus.canceled:
        case iap.PurchaseStatus.error:
          state = state.copyWith(purchaseInFlight: false);
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
        case iap.PurchaseStatus.purchased:
        case iap.PurchaseStatus.restored:
          await _persistEntitlement(plan, p);
          state = state.copyWith(purchaseInFlight: false);
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
      }
    }
  }

  Future<void> _persistEntitlement(
    SubscriptionPlan plan,
    iap.PurchaseDetails p,
  ) async {
    final uid = _user?.id;
    if (uid == null) {
      // No user — can't persist. Log and skip; the next restore will
      // re-emit when the user signs in.
      if (kDebugMode) {
        debugPrint('[subscription] purchase for ${plan.id} received but no '
            'signed-in user — skipping Firestore write.');
      }
      return;
    }

    String? platform;
    if (!kIsWeb) {
      if (Platform.isIOS || Platform.isMacOS) platform = 'ios';
      if (Platform.isAndroid) platform = 'android';
    }

    try {
      await _firestore.recordPurchase(
        uid: uid,
        plan: plan,
        platform: platform ?? 'unknown',
        originalTransactionId:
            p.purchaseID ?? p.verificationData.serverVerificationData,
      );
    } catch (e, st) {
      state = state.copyWith(lastFailure: mapToFailure(e, st));
    }
  }

  @override
  void dispose() {
    _iapSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}
