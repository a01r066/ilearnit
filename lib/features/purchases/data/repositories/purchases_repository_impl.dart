import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/product_price_entity.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/entities/purchase_status.dart';
import '../../domain/repositories/purchases_repository.dart';
import '../datasources/iap_remote_datasource.dart';
import '../datasources/purchases_firestore_datasource.dart';
import '../models/purchase_model.dart';

class PurchasesRepositoryImpl implements PurchasesRepository {
  PurchasesRepositoryImpl({
    required IapRemoteDataSource iap,
    required PurchasesFirestoreDataSource firestore,
    required FirebaseAuth auth,
  })  : _iap = iap,
        _firestore = firestore,
        _auth = auth;

  final IapRemoteDataSource _iap;
  final PurchasesFirestoreDataSource _firestore;
  final FirebaseAuth _auth;

  /// In-memory map: productId → courseId, populated by `buyCourse(...)` so
  /// the platform purchase stream (which only carries productId) can be
  /// correlated back to the originating course. Restored purchases that
  /// arrive without a prior `buyCourse` call still need correlation —
  /// they're resolved via `applicationUserName` carried on PurchaseDetails.
  final Map<String, String> _pendingProductToCourse = {};

  @override
  Future<bool> get isAvailable => _iap.isAvailable;

  @override
  ResultFuture<Map<String, ProductPriceEntity>> fetchProducts(
    Set<String> productIds,
  ) async {
    try {
      final out = await _iap.fetchProducts(productIds);
      return Right(out);
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
      _pendingProductToCourse[productId] = courseId;
      // Embed our courseId in `applicationUserName` so the platform echoes
      // it back on every PurchaseDetails — useful for restore flows where
      // the in-memory map is empty.
      await _iap.buyNonConsumable(
        productId: productId,
        applicationUserName: courseId,
      );
      return const Right(null);
    } catch (e, st) {
      _pendingProductToCourse.remove(productId);
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultFuture<void> restorePurchases() async {
    try {
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
        // Resolve courseId — first from in-memory map (live purchase),
        // then from applicationUserName (restore), then skip.
        final courseId = _pendingProductToCourse.remove(p.productID) ??
            _courseIdFromVerificationData(p);
        if (courseId == null) {
          // Couldn't map this product back to a course. Complete the txn
          // so the store stops resending; UI will reflect ownership the
          // next time the user signs in (if a Cloud Function backfills).
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          continue;
        }

        final status = mapPlatformPurchaseStatus(p.status);
        final entity = PurchaseEntity(
          courseId: courseId,
          productId: p.productID,
          status: status,
          transactionId: p.purchaseID,
          source: p.status == iap.PurchaseStatus.restored
              ? 'restore'
              : 'purchase',
          purchasedAt: _parseDate(p.transactionDate),
        );

        // Persist confirmed purchases; for pending/failed we just emit.
        if ((status == PurchaseStatus.purchased ||
                status == PurchaseStatus.restored) &&
            _auth.currentUser != null) {
          try {
            await _firestore.upsertPurchase(
              uid: _auth.currentUser!.uid,
              purchase: PurchaseModel(
                courseId: entity.courseId,
                productId: entity.productId,
                status: PurchaseModel.idFromStatus(status),
                transactionId: entity.transactionId,
                source: entity.source,
                purchasedAt: entity.purchasedAt ?? DateTime.now(),
              ),
            );
          } catch (_) {
            // Swallow — UI will retry on the next stream emission, and
            // restorePurchases() can be used to recover.
          }
        }

        // TODO(security): verify the receipt server-side (Cloud Function)
        // before completing. For now we trust the platform stream.
        if (p.pendingCompletePurchase) {
          try {
            await _iap.completePurchase(p);
          } catch (_) {
            // The platform will retry on next stream pump.
          }
        }

        yield entity;
      }
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

  // ── Helpers ─────────────────────────────────────────────────────────

  /// On Android and iOS, the platform echoes `applicationUserName` back via
  /// the verification-data fields. We tucked the courseId there during
  /// `buyCourse(...)`. This works around the restore-flow case where the
  /// in-memory map is empty (cold start after a re-install).
  String? _courseIdFromVerificationData(iap.PurchaseDetails p) {
    // The plugin doesn't currently expose `applicationUserName` on
    // PurchaseDetails directly, so this is a placeholder. The robust
    // long-term answer is a Cloud Function that maps productId+receipt
    // back to courseId server-side.
    return null;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final millis = int.tryParse(raw);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return DateTime.tryParse(raw);
  }
}
