import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../flavors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/subscription_firestore_datasource.dart';
import '../../../purchases/data/datasources/iap_remote_datasource.dart';
import '../../../purchases/data/datasources/purchase_verification_datasource.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_status.dart';
import 'subscription_state.dart';
import '../../../../l10n/l10n.dart';

/// Owns the subscription lifecycle on the client.
///
/// Wiring:
///   1. On construction, fetches store ProductDetails for both plans.
///   2. Listens to the IAP `purchaseStream` and filters by subscription
///      product ids — when one fires `purchased | restored`, sends the
///      receipt to the `verifySubscription` Cloud Function (which writes
///      `users/{uid}.subscription`) and only then completes the txn.
///   3. Subscribes to Firestore so the UI always reflects authoritative
///      state, not optimistic state.
///
/// The existing [PurchasesNotifier] handles per-course purchases on the
/// same stream — both notifiers coexist by filtering on productId.
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier({
    required IapRemoteDataSource iap,
    required SubscriptionFirestoreDataSource firestore,
    required PurchaseVerificationDataSource verifier,
    required UserEntity? user,
  })  : _iap = iap,
        _firestore = firestore,
        _verifier = verifier,
        _user = user,
        super(const SubscriptionState()) {
    _init();
  }

  final IapRemoteDataSource _iap;
  final SubscriptionFirestoreDataSource _firestore;
  final PurchaseVerificationDataSource _verifier;
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
    state = state.copyWith(purchaseInFlight: true, lastFailure: null);
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
    state = state.copyWith(lastFailure: null);
    try {
      await _iap.restorePurchases();
    } catch (e, st) {
      state = state.copyWith(lastFailure: mapToFailure(e, st));
    }
  }

  /// Opens the platform's subscription-management page. Cancellation
  /// happens in the store; the server picks up `autoRenew == false` the
  /// next time the subscription is verified. (Clients can no longer
  /// write `users/{uid}.subscription` — see firestore.rules.)
  Future<void> openManageSubscription() async {
    final uri = !kIsWeb && Platform.isAndroid
        ? Uri.parse('https://play.google.com/store/account/subscriptions'
            '?package=${F.androidPackageName}')
        : Uri.parse('https://apps.apple.com/account/subscriptions');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void clearFailure() {
    if (state.lastFailure == null) return;
    state = state.copyWith(lastFailure: null);
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
          final finish = await _verifyEntitlement(p);
          state = state.copyWith(purchaseInFlight: false);
          if (finish && p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
      }
    }
  }

  /// Sends the receipt to `verifySubscription`; the server validates it
  /// with Apple / Google and writes `users/{uid}.subscription`. The
  /// Firestore listener in [_init] then picks up the new status.
  ///
  /// Returns whether the store transaction may be finished.
  Future<bool> _verifyEntitlement(iap.PurchaseDetails p) async {
    if (_user == null) {
      // Leave the transaction open — it is re-delivered after sign-in.
      return false;
    }
    try {
      await _verifier.verifySubscription(p);
      return true;
    } on PurchaseVerificationException catch (e) {
      state = state.copyWith(
        lastFailure: Failure.server(
          message: e.code == 'permission-denied' &&
                  e.message.contains('another account')
              ? L10n.current.subscriptionOtherAccount
              : L10n.current.subscriptionVerifyFailed,
        ),
      );
      // Retryable → keep open so it replays. Rejected → finish on iOS so
      // it doesn't loop; on Android leave unacknowledged (auto-refund).
      return !e.retryable && PurchaseVerificationDataSource.platform == 'ios';
    } catch (e, st) {
      // Unknown failure — treat as retryable, keep the transaction open.
      state = state.copyWith(lastFailure: mapToFailure(e, st));
      return false;
    }
  }

  @override
  void dispose() {
    _iapSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}
