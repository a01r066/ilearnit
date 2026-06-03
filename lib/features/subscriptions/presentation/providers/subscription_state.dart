import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/subscription_status.dart';

part 'subscription_state.freezed.dart';

/// Snapshot for [SubscriptionNotifier].
///
/// Default-constructed state means "no subscription, no failure, idle" —
/// which is what we want on cold start before the Firestore stream emits.
@freezed
abstract class SubscriptionState with _$SubscriptionState {
  const SubscriptionState._();

  const factory SubscriptionState({
    @Default(SubscriptionStatus()) SubscriptionStatus status,
    @Default(false) bool isLoading,
    @Default(<String, String>{}) Map<String, String> priceByProductId,
    @Default(false) bool purchaseInFlight,
    Failure? lastFailure,
  }) = _SubscriptionState;

  bool get hasActiveSubscription => status.isActive;
}
