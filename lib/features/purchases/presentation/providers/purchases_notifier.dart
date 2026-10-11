import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/price_tier.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/entities/purchase_status.dart';
import '../../domain/repositories/purchases_repository.dart';
import 'purchases_state.dart';

/// Manages the IAP pipeline:
///   1. On init: probes platform availability + fetches tier prices.
///   2. Subscribes to the purchase stream and persists outcomes via the repo.
///   3. Tracks in-flight buy operations so the UI can show progress.
///
/// Designed to live as a keep-alive provider so the stream subscription
/// persists across navigation.
class PurchasesNotifier extends StateNotifier<PurchasesState> {
  PurchasesNotifier(this._repo) : super(const PurchasesState()) {
    _init();
  }

  final PurchasesRepository _repo;
  StreamSubscription<PurchaseEntity>? _sub;

  Future<void> _init() async {
    final available = await _repo.isAvailable;
    state = state.copyWith(isAvailable: available);
    if (!available) return;

    // Listen to the platform purchase stream once; emissions are persisted
    // by the repo itself, this notifier only updates UI state.
    _sub = _repo.purchaseUpdates().listen(_onPurchaseUpdate);

    // Android doesn't re-deliver purchases that were paid for but never
    // verified/consumed (app killed mid-flow). Querying past purchases
    // pushes them back through the stream so verifyPurchase can grant
    // them. iOS re-delivers unfinished transactions on its own, and
    // restoreCompletedTransactions can prompt for the Apple ID, so skip.
    if (!kIsWeb && Platform.isAndroid) {
      unawaited(_repo.restorePurchases());
    }

    // Fetch localized prices for all tier products.
    final result = await _repo.fetchProducts(PriceTier.allProductIds);
    result.fold(
      (failure) => state = state.copyWith(lastFailure: failure),
      (products) {
        final priceMap = <String, String>{
          for (final entry in products.entries) entry.key: entry.value.price,
        };
        state = state.copyWith(priceByProductId: priceMap);
      },
    );
  }

  /// Triggered from a BuyCourseButton tap.
  Future<void> buyCourse({
    required String courseId,
    required String productId,
  }) async {
    if (state.isBuying(courseId)) return; // debounce double-tap
    state = state.copyWith(
      coursesInFlight: {...state.coursesInFlight, courseId},
      lastFailure: null,
    );
    final result = await _repo.buyCourse(
      courseId: courseId,
      productId: productId,
    );
    result.fold(
      (failure) {
        state = state.copyWith(
          coursesInFlight: state.coursesInFlight.difference({courseId}),
          lastFailure: failure,
        );
      },
      (_) {
        // Stay in-flight until the stream emits success/failure for this
        // courseId — handled in _onPurchaseUpdate.
      },
    );
  }

  Future<void> restorePurchases() async {
    final result = await _repo.restorePurchases();
    result.fold(
      (failure) => state = state.copyWith(lastFailure: failure),
      (_) {}, // emissions arrive via the stream
    );
  }

  void _onPurchaseUpdate(PurchaseEntity p) {
    final isTerminal = p.status != PurchaseStatus.pending;
    if (!isTerminal) return;
    state = state.copyWith(
      coursesInFlight: state.coursesInFlight.difference({p.courseId}),
    );
  }

  void clearFailure() {
    if (state.lastFailure == null) return;
    state = state.copyWith(lastFailure: null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
