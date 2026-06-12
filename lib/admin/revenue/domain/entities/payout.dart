import 'package:freezed_annotation/freezed_annotation.dart';

part 'payout.freezed.dart';

/// Periodic payout to an instructor. Persisted at `payouts/{id}`.
///
/// v1 is **bookkeeping-only** — there is no real bank-transfer
/// integration. Admin generates a payout for an instructor (typically
/// monthly), assigns the relevant transaction ids, then flips
/// [status] to `paid` after the transfer is processed out-of-band
/// (manual bank wire, Stripe Connect, Wise, etc.).
///
/// [grossUsd] − [platformFee] = [netUsd].
@freezed
abstract class PayoutEntity with _$PayoutEntity {
  const PayoutEntity._();

  const factory PayoutEntity({
    required String id,
    required String instructorUid,
    @Default('') String instructorName,
    required DateTime periodStart,
    required DateTime periodEnd,
    @Default(0) double grossUsd,
    @Default(0) double platformFee,
    @Default(0) double netUsd,
    @Default('pending') String status, // pending | paid | cancelled
    DateTime? paidAt,
    String? paidByUid, // admin who clicked Mark paid
    String? payoutMethod, // 'bank' | 'stripe' | 'wise' | free-form note
    @Default(<String>[]) List<String> txnIds,
    required DateTime createdAt,
  }) = _PayoutEntity;

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
}
