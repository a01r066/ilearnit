import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../features/auth/data/models/user_model.dart'
    show TimestampConverter;
import '../../domain/entities/transaction.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
abstract class TransactionModel with _$TransactionModel {
  const TransactionModel._();

  const factory TransactionModel({
    @Default('') String id,
    @Default('') String courseId,
    @Default('') String courseTitle,
    @Default('') String instructorId,
    @Default('') String instructorName,
    @Default('') String studentUid,
    @Default('') String studentName,
    @Default('') String studentEmail,
    @Default(0) double amountUsd,
    @Default(0) int amountVnd,
    @Default('USD') String currency,
    @Default('ios') String platform,
    @Default('paid') String status,
    String? last4,
    String? processorRef,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? refundedAt,
    String? refundReason,
    String? refundedByUid,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  factory TransactionModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return TransactionModel.fromJson({...data, 'id': doc.id});
  }

  // Mirror of TransactionEntity's status getters so the UI layer can
  // consume the model directly without round-tripping through .toEntity().
  bool get isPaid => status == 'paid';
  bool get isRefunded => status == 'refunded';
  bool get isPending => status == 'pending';

  TransactionEntity toEntity() => TransactionEntity(
        id: id,
        courseId: courseId,
        courseTitle: courseTitle,
        instructorId: instructorId,
        instructorName: instructorName,
        studentUid: studentUid,
        studentName: studentName,
        studentEmail: studentEmail,
        amountUsd: amountUsd,
        amountVnd: amountVnd,
        currency: currency,
        platform: platform,
        status: status,
        last4: last4,
        processorRef: processorRef,
        createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        refundedAt: refundedAt,
        refundReason: refundReason,
        refundedByUid: refundedByUid,
      );
}
