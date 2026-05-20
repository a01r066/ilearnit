import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/entities/purchase_status.dart';

part 'purchase_model.freezed.dart';
part 'purchase_model.g.dart';

@freezed
abstract class PurchaseModel with _$PurchaseModel {
  const PurchaseModel._();

  const factory PurchaseModel({
    required String courseId,
    required String productId,
    @Default('pending') String status,
    String? transactionId,
    String? originalTransactionId,
    String? source,
    @TimestampConverter() DateTime? purchasedAt,
  }) = _PurchaseModel;

  factory PurchaseModel.fromJson(Map<String, dynamic> json) =>
      _$PurchaseModelFromJson(json);

  factory PurchaseModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PurchaseModel.fromJson({...data, 'courseId': doc.id});
  }

  PurchaseEntity toEntity() => PurchaseEntity(
        courseId: courseId,
        productId: productId,
        status: _statusFromId(status),
        transactionId: transactionId,
        originalTransactionId: originalTransactionId,
        source: source,
        purchasedAt: purchasedAt,
      );

  static String idFromStatus(PurchaseStatus s) => s.name;

  static PurchaseStatus _statusFromId(String id) =>
      PurchaseStatus.values.firstWhere(
        (e) => e.name == id,
        orElse: () => PurchaseStatus.pending,
      );
}
