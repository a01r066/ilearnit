import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_status.dart';

/// Firestore DTO that maps the embedded `subscription` map on the
/// `users/{uid}` doc to/from a [SubscriptionStatus].
///
/// We don't use Freezed here — the embedded shape is tiny and avoiding the
/// generated files keeps the integration light.
class SubscriptionModel {
  const SubscriptionModel({
    required this.planId,
    required this.productId,
    required this.startedAt,
    required this.expiresAt,
    required this.autoRenew,
    this.canceledAt,
    this.platform,
    this.originalTransactionId,
  });

  final String? planId;
  final String? productId;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final bool autoRenew;
  final DateTime? canceledAt;
  final String? platform;
  final String? originalTransactionId;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionModel(
        planId: json['planId'] as String?,
        productId: json['productId'] as String?,
        startedAt: _toDate(json['startedAt']),
        expiresAt: _toDate(json['expiresAt']),
        autoRenew: json['autoRenew'] as bool? ?? true,
        canceledAt: _toDate(json['canceledAt']),
        platform: json['platform'] as String?,
        originalTransactionId: json['originalTransactionId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'productId': productId,
        'startedAt': startedAt == null ? null : Timestamp.fromDate(startedAt!),
        'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
        'autoRenew': autoRenew,
        'canceledAt':
            canceledAt == null ? null : Timestamp.fromDate(canceledAt!),
        'platform': platform,
        'originalTransactionId': originalTransactionId,
      };

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

  static DateTime? _toDate(Object? raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return null;
  }
}
