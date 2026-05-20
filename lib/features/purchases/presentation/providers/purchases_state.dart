import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';

part 'purchases_state.freezed.dart';

/// Tracks the global IAP machine state (price catalogue + currently in-flight
/// purchase). Per-course ownership lives in a separate stream provider so
/// the UI can subscribe without re-rendering on every transient flow change.
@freezed
abstract class PurchasesState with _$PurchasesState {
  const PurchasesState._();

  const factory PurchasesState({
    /// Set of course IDs the user is currently trying to buy. UI uses this
    /// to disable the BuyButton + show a spinner.
    @Default(<String>{}) Set<String> coursesInFlight,

    /// Whether the platform supports IAP at all (StoreKit / Play Services
    /// reachability). Falsy → hide the buy buttons completely.
    @Default(true) bool isAvailable,

    /// productId → localized price string from the store (e.g. "$9.99"),
    /// populated once at app start.
    @Default(<String, String>{}) Map<String, String> priceByProductId,

    /// Surfaces non-fatal flow errors (cancel, network, etc).
    Failure? lastFailure,
  }) = _PurchasesState;

  bool isBuying(String courseId) => coursesInFlight.contains(courseId);

  String? priceFor(String productId) => priceByProductId[productId];
}
