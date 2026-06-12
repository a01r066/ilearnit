import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';

/// One purchase event. Persisted at `transactions/{id}`.
///
/// **Privacy by design**: this model only carries *masked* payment
/// details ([last4] — never the full PAN) and a [processorRef] used
/// for cross-checking against the underlying store receipt. Full card
/// numbers, CVVs, and billing addresses are NEVER stored — those live
/// inside the App Store / Play Store and the storefront receipt is the
/// authoritative record.
///
/// `instructorId` is denormalized so per-instructor reads use a single
/// `where('instructorId', '==', uid)` query without an N+1 join
/// through `courses/{id}`.
@freezed
abstract class TransactionEntity with _$TransactionEntity {
  const TransactionEntity._();

  const factory TransactionEntity({
    required String id,
    required String courseId,
    @Default('') String courseTitle,
    required String instructorId,
    @Default('') String instructorName,
    required String studentUid,
    @Default('') String studentName,
    @Default('') String studentEmail,
    @Default(0) double amountUsd,
    @Default(0) int amountVnd,
    @Default('USD') String currency,
    @Default('ios') String platform, // ios | android | web
    @Default('paid') String status, // paid | refunded | pending
    String? last4, // masked card / payment last 4 — display only
    String? processorRef, // App Store transactionId or Play purchaseToken
    required DateTime createdAt,
    DateTime? refundedAt,
    String? refundReason,
    String? refundedByUid, // admin who clicked Refund
  }) = _TransactionEntity;

  bool get isRefunded => status == 'refunded';
  bool get isPaid => status == 'paid';
}
