import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../features/auth/data/models/user_model.dart'
    show TimestampConverter;
import '../../domain/entities/payout.dart';

part 'payout_model.freezed.dart';
part 'payout_model.g.dart';

@freezed
abstract class PayoutModel with _$PayoutModel {
  const PayoutModel._();

  const factory PayoutModel({
    @Default('') String id,
    @Default('') String instructorUid,
    @Default('') String instructorName,
    @TimestampConverter() DateTime? periodStart,
    @TimestampConverter() DateTime? periodEnd,
    @Default(0) double grossUsd,
    @Default(0) double platformFee,
    @Default(0) double netUsd,
    @Default('pending') String status,
    @TimestampConverter() DateTime? paidAt,
    String? paidByUid,
    String? payoutMethod,
    @Default(<String>[]) List<String> txnIds,
    @TimestampConverter() DateTime? createdAt,
  }) = _PayoutModel;

  factory PayoutModel.fromJson(Map<String, dynamic> json) =>
      _$PayoutModelFromJson(json);

  factory PayoutModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PayoutModel.fromJson({...data, 'id': doc.id});
  }

  // Mirror of PayoutEntity's status getters so the UI layer can
  // consume the model directly without going through .toEntity().
  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';

  PayoutEntity toEntity() => PayoutEntity(
        id: id,
        instructorUid: instructorUid,
        instructorName: instructorName,
        periodStart: periodStart ?? DateTime.fromMillisecondsSinceEpoch(0),
        periodEnd: periodEnd ?? DateTime.fromMillisecondsSinceEpoch(0),
        grossUsd: grossUsd,
        platformFee: platformFee,
        netUsd: netUsd,
        status: status,
        paidAt: paidAt,
        paidByUid: paidByUid,
        payoutMethod: payoutMethod,
        txnIds: txnIds,
        createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}
