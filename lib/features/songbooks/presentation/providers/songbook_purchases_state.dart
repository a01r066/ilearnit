import 'package:flutter/foundation.dart';

/// Hand-rolled (no codegen) state for songbook purchases.
@immutable
class SongbookPurchasesState {
  const SongbookPurchasesState({
    this.inFlight = const <String>{},
    this.priceByProductId = const <String, String>{},
    this.lastError,
  });

  /// productIds currently being bought.
  final Set<String> inFlight;

  /// productId → localized store price ("$4.99", "₫99.000").
  final Map<String, String> priceByProductId;

  /// Localized, user-facing error from the last attempt (null = none).
  final String? lastError;

  bool isBuying(String productId) => inFlight.contains(productId);

  SongbookPurchasesState copyWith({
    Set<String>? inFlight,
    Map<String, String>? priceByProductId,
    String? lastError,
    bool clearError = false,
  }) =>
      SongbookPurchasesState(
        inFlight: inFlight ?? this.inFlight,
        priceByProductId: priceByProductId ?? this.priceByProductId,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );
}
