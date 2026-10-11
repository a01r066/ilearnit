import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/price_tier.dart';
import '../../domain/entities/product_price_entity.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/entities/purchase_status.dart';
import '../../domain/repositories/purchases_repository.dart';
import '../datasources/iap_remote_datasource.dart';
import '../datasources/purchase_verification_datasource.dart';
import '../datasources/purchases_firestore_datasource.dart';
import '../../../../l10n/l10n.dart';

/// Course purchases.
///
/// Flow:
///   1. `buyCourse` → `createPurchaseIntent` (server records which course
///      this tier purchase is for and returns the tier product id) →
///      store sheet for a CONSUMABLE tier product.
///   2. The platform stream delivers the transaction → `verifyPurchase`
///      validates the receipt, grants `users/{uid}/purchases/{courseId}`
///      and (Android) consumes the token.
///   3. Only after the server answers do we finish the store transaction.
///
/// Nothing here writes entitlements to Firestore — rules forbid it.
class PurchasesRepositoryImpl implements PurchasesRepository {
  PurchasesRepositoryImpl({
    required IapRemoteDataSource iap,
    required PurchasesFirestoreDataSource firestore,
    required PurchaseVerificationDataSource verifier,
    required FirebaseAuth auth,
  })  : _iap = iap,
        _firestore = firestore,
        _verifier = verifier,
        _auth = auth;

  final IapRemoteDataSource _iap;
  final PurchasesFirestoreDataSource _firestore;
  final PurchaseVerificationDataSource _verifier;
  final FirebaseAuth _auth;

  /// productId → courseId for purchases started in THIS process. Only a
  /// hint: after an app kill the server resolves the course from the
  /// intent recorded in step 1.
  final Map<String, String> _courseHints = {};

  @override
  Future<bool> get isAvailable => _iap.isAvailable;

  @override
  ResultFuture<Map<String, ProductPriceEntity>> fetchProducts(
    Set<String> productIds,
  ) async {
    try {
      return Right(await _iap.fetchProducts(productIds));
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultFuture<void> buyCourse({
    required String courseId,
    required String productId,
  }) async {
    try {
      // The server derives the product from the course tier; trust it
      // over the client-side value so a stale build can't pay the wrong
      // tier.
      final serverProductId = await _verifier.createIntent(courseId);
      _courseHints[serverProductId] = courseId;
      await _iap.buyConsumable(
        productId: serverProductId,
        applicationUserName: _auth.currentUser?.uid,
      );
      return const Right(null);
    } on PurchaseVerificationException catch (e) {
      final t = L10n.current;
      return Left(Failure.server(
        message: switch (e.code) {
          'already-exists' => t.purchaseAlreadyOwned,
          'failed-precondition' || 'not-found' => t.purchaseCourseUnavailable,
          'unauthenticated' => t.purchaseSignInToUnlockCourse,
          _ => t.purchaseFailed,
        },
      ));
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultFuture<void> restorePurchases() async {
    try {
      // iOS: replays non-consumables only — course tiers are consumables,
      // so this mainly re-delivers unfinished Android purchases. Course
      // ownership itself lives server-side on the account.
      await _iap.restorePurchases();
      return const Right(null);
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  Stream<PurchaseEntity> purchaseUpdates() async* {
    await for (final batch in _iap.purchaseStream) {
      for (final p in batch) {
        // Subscriptions are handled by SubscriptionNotifier on the same
        // stream — leave them alone.
        if (PriceTier.fromProductId(p.productID) == null) continue;

        final entity = await _handle(p);
        if (entity != null) yield entity;
      }
    }
  }

  Future<PurchaseEntity?> _handle(iap.PurchaseDetails p) async {
    final hint = _courseHints[p.productID];
    PurchaseEntity entityFor(String courseId, PurchaseStatus status) =>
        PurchaseEntity(
          courseId: courseId,
          productId: p.productID,
          status: status,
          transactionId: p.purchaseID,
          source: p.status == iap.PurchaseStatus.restored
              ? 'restore'
              : 'purchase',
          purchasedAt: _parseDate(p.transactionDate),
        );

    switch (p.status) {
      case iap.PurchaseStatus.pending:
        // Ask to Buy / slow card. Keep waiting; the store emits again.
        return hint == null ? null : entityFor(hint, PurchaseStatus.pending);

      case iap.PurchaseStatus.canceled:
      case iap.PurchaseStatus.error:
        // StoreKit keeps failed transactions queued until finished —
        // leaving them open blocks the next purchase of the same product.
        await _safeComplete(p);
        _courseHints.remove(p.productID);
        return hint == null ? null : entityFor(hint, PurchaseStatus.failed);

      case iap.PurchaseStatus.purchased:
      case iap.PurchaseStatus.restored:
        break;
    }

    // Wait for Firebase Auth to restore the session on cold start before
    // deciding there's no user.
    final user = _auth.currentUser ?? await _auth.authStateChanges().first;
    if (user == null) {
      // Leave the transaction open; it is re-delivered after sign-in.
      return null;
    }

    try {
      final result = await _verifier.verifyCourse(p, courseIdHint: hint);
      _courseHints.remove(p.productID);
      // Android: the server consumed the token (which also acknowledges
      // it). Acknowledging a consumed purchase errors, so skip it.
      if (!result.consumed) await _safeComplete(p);
      return entityFor(result.courseId, PurchaseStatus.purchased);
    } on PurchaseVerificationException catch (e) {
      if (!e.retryable) {
        _courseHints.remove(p.productID);
        // iOS: finish so a bad / unmatched receipt doesn't loop forever
        // (the server logged it for support). Android: leave it
        // unacknowledged — Play auto-refunds after 3 days.
        if (PurchaseVerificationDataSource.platform == 'ios') {
          await _safeComplete(p);
        }
      }
      // Retryable: keep the transaction open so it replays on next launch.
      return hint == null ? null : entityFor(hint, PurchaseStatus.failed);
    } catch (_) {
      // Unknown failure — treat as retryable.
      return hint == null ? null : entityFor(hint, PurchaseStatus.failed);
    }
  }

  Future<void> _safeComplete(iap.PurchaseDetails p) async {
    if (!p.pendingCompletePurchase) return;
    try {
      await _iap.completePurchase(p);
    } catch (_) {
      // The platform re-delivers on the next stream pump.
    }
  }

  @override
  Stream<Set<String>> ownedCourseIds() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(<String>{});
    return _firestore.ownedCourseIdsStream(user.uid);
  }

  @override
  ResultFuture<List<PurchaseEntity>> fetchUserPurchases() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const Right(<PurchaseEntity>[]);
      final models = await _firestore.fetchAll(user.uid);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final millis = int.tryParse(raw);
    if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
    return DateTime.tryParse(raw);
  }
}
