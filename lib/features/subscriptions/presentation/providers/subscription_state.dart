import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/subscription_status.dart';

/// Snapshot for [SubscriptionNotifier].
@immutable
class SubscriptionState {
  const SubscriptionState({
    this.status = const _NoneSentinel(),
    this.isLoading = false,
    this.priceByProductId = const {},
    this.purchaseInFlight = false,
    this.lastFailure,
  });

  /// Current entitlement on the user's Firestore doc. Live-streamed.
  final SubscriptionStatus status;

  /// True while we're hydrating prices / firing a buy.
  final bool isLoading;

  /// Localized prices returned by the store — populated once on init.
  /// Maps `productId` → display string (e.g. `"$9.99"`, `"₫800,000/mo"`).
  final Map<String, String> priceByProductId;

  /// True between [SubscriptionNotifier.buy] and the matching success/fail
  /// emission on the purchase stream. Drives the CTA spinner.
  final bool purchaseInFlight;

  final Failure? lastFailure;

  bool get hasActiveSubscription => status.isActive;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    bool? isLoading,
    Map<String, String>? priceByProductId,
    bool? purchaseInFlight,
    Failure? lastFailure,
    bool clearFailure = false,
  }) =>
      SubscriptionState(
        status: status ?? this.status,
        isLoading: isLoading ?? this.isLoading,
        priceByProductId: priceByProductId ?? this.priceByProductId,
        purchaseInFlight: purchaseInFlight ?? this.purchaseInFlight,
        lastFailure: clearFailure ? null : (lastFailure ?? this.lastFailure),
      );
}

/// Const-able stand-in for [SubscriptionStatus.none()] so SubscriptionState
/// itself can be `const`.
class _NoneSentinel implements SubscriptionStatus {
  const _NoneSentinel();
  @override
  bool get autoRenew => false;
  @override
  DateTime? get canceledAt => null;
  @override
  DateTime? get expiresAt => null;
  @override
  bool get isActive => false;
  @override
  bool get isCanceledButActive => false;
  @override
  String? get originalTransactionId => null;
  @override
  get plan => null;
  @override
  String? get platform => null;
  @override
  String? get productId => null;
  @override
  DateTime? get startedAt => null;
  @override
  SubscriptionStatus copyWith({
    plan,
    DateTime? startedAt,
    DateTime? expiresAt,
    bool? autoRenew,
    String? productId,
    DateTime? canceledAt,
    String? platform,
    String? originalTransactionId,
  }) =>
      SubscriptionStatus.none();
}
