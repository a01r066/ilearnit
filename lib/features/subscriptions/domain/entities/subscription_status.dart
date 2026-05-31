import 'subscription_plan.dart';

/// User-facing subscription state. Stored at `users/{uid}.subscription` as
/// a single embedded map (cheaper than a sub-collection for a 1:1 doc).
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.plan,
    required this.startedAt,
    required this.expiresAt,
    required this.autoRenew,
    required this.productId,
    this.canceledAt,
    this.platform,
    this.originalTransactionId,
  });

  /// Convenience: the user has no subscription on file at all.
  factory SubscriptionStatus.none() => SubscriptionStatus(
        plan: null,
        startedAt: null,
        expiresAt: null,
        autoRenew: false,
        productId: null,
      );

  final SubscriptionPlan? plan;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final bool autoRenew;
  final String? productId;
  final DateTime? canceledAt;

  /// 'ios' | 'android' — handy for support tickets.
  final String? platform;

  /// Apple's `originalTransactionId` / Play's `purchaseToken`. Lets a
  /// server-side verifier de-dupe across reinstalls.
  final String? originalTransactionId;

  /// Active = an entitlement currently exists. We treat `auto-renew off but
  /// still within the paid period` as active too — the user keeps access
  /// until the period ends.
  bool get isActive {
    if (plan == null || expiresAt == null) return false;
    return expiresAt!.isAfter(DateTime.now());
  }

  /// Cancelled-but-still-in-paid-period. UI shows "Cancels on <date>".
  bool get isCanceledButActive =>
      isActive && !autoRenew && canceledAt != null;

  SubscriptionStatus copyWith({
    SubscriptionPlan? plan,
    DateTime? startedAt,
    DateTime? expiresAt,
    bool? autoRenew,
    String? productId,
    DateTime? canceledAt,
    String? platform,
    String? originalTransactionId,
  }) =>
      SubscriptionStatus(
        plan: plan ?? this.plan,
        startedAt: startedAt ?? this.startedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        autoRenew: autoRenew ?? this.autoRenew,
        productId: productId ?? this.productId,
        canceledAt: canceledAt ?? this.canceledAt,
        platform: platform ?? this.platform,
        originalTransactionId:
            originalTransactionId ?? this.originalTransactionId,
      );
}
