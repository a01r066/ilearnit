import 'package:freezed_annotation/freezed_annotation.dart';

import 'subscription_plan.dart';

part 'subscription_status.freezed.dart';

/// User-facing subscription state. Stored at `users/{uid}.subscription` as
/// a single embedded map (cheaper than a sub-collection for a 1:1 doc).
///
/// A "no subscription" status is just `const SubscriptionStatus()` —
/// every field is optional / defaults to a falsy value.
@freezed
abstract class SubscriptionStatus with _$SubscriptionStatus {
  const SubscriptionStatus._();

  const factory SubscriptionStatus({
    SubscriptionPlan? plan,
    DateTime? startedAt,
    DateTime? expiresAt,
    @Default(false) bool autoRenew,
    String? productId,
    DateTime? canceledAt,
    String? platform,
    String? originalTransactionId,
  }) = _SubscriptionStatus;

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
}
