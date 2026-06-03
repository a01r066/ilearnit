import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_status.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

/// Firestore DTO that maps the embedded `subscription` map on the
/// `users/{uid}` doc to/from a [SubscriptionStatus].
///
/// Reuses [TimestampConverter] from the auth module so all Firestore
/// timestamps are handled identically.
@freezed
abstract class SubscriptionModel with _$SubscriptionModel {
  const SubscriptionModel._();

  const factory SubscriptionModel({
    String? planId,
    String? productId,
    @TimestampConverter() DateTime? startedAt,
    @TimestampConverter() DateTime? expiresAt,
    @Default(true) bool autoRenew,
    @TimestampConverter() DateTime? canceledAt,
    String? platform,
    String? originalTransactionId,
  }) = _SubscriptionModel;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);

  SubscriptionStatus toEntity() => SubscriptionStatus(
        plan: SubscriptionPlan.fromId(planId),
        startedAt: startedAt,
        expiresAt: expiresAt,
        autoRenew: autoRenew,
        productId: productId,
        canceledAt: canceledAt,
        platform: platform,
        originalTransactionId: originalTransactionId,
      );
}
