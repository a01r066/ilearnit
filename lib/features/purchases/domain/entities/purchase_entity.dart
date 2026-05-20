import 'package:freezed_annotation/freezed_annotation.dart';

import 'purchase_status.dart';

part 'purchase_entity.freezed.dart';

/// A single owned-course record persisted to
/// `users/{uid}/purchases/{courseId}` and surfaced to the UI to gate access.
@freezed
abstract class PurchaseEntity with _$PurchaseEntity {
  const factory PurchaseEntity({
    required String courseId,
    required String productId,
    required PurchaseStatus status,
    String? transactionId,
    String? originalTransactionId, // iOS — for renewal / restore correlation
    String? source, // 'purchase' | 'restore' | 'admin' (manual grant)
    DateTime? purchasedAt,
  }) = _PurchaseEntity;
}
