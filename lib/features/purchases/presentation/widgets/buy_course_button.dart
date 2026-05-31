import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../subscriptions/presentation/providers/subscription_providers.dart';
import '../providers/purchases_providers.dart';
import '../providers/purchases_state.dart';

/// The primary call-to-action on the course detail page.
///
/// Renders three states:
///   • Owned        → "Continue" filled button, calls [onStart].
///   • Buyable      → "Buy {price}" filled button.
///   • In-flight    → spinner, button disabled.
///
/// Hides itself if the platform doesn't support IAP (e.g. running in a
/// simulator/emulator without store mock-up).
class BuyCourseButton extends ConsumerWidget {
  const BuyCourseButton({
    super.key,
    required this.course,
    required this.onStart,
  });

  final CourseEntity course;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwned = ref.watch(isCoursePurchasedProvider(course.id));
    final hasSubscription = ref.watch(hasActiveSubscriptionProvider);
    final purchases = ref.watch(purchasesNotifierProvider);
    final notifier = ref.read(purchasesNotifierProvider.notifier);

    // Show snackbar on IAP errors and clear the failure once consumed.
    ref.listen<PurchasesState>(purchasesNotifierProvider, (_, next) {
      final f = next.lastFailure;
      if (f != null) {
        context.showSnack(f.displayMessage);
        notifier.clearFailure();
      }
    });

    if (!purchases.isAvailable) {
      return _UnavailableNotice();
    }

    // Subscription bypass — the user has unlimited access. Same CTA as
    // owned, with a subtle "included in subscription" affordance below.
    if (hasSubscription || isOwned) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Continue course'),
          ),
          if (hasSubscription && !isOwned) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Included in your Personal Plan',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ],
      );
    }

    final inFlight = purchases.isBuying(course.id);
    final livePrice = purchases.priceFor(course.productId);
    final priceLabel = livePrice ?? course.fallbackPrice;

    return FilledButton(
      onPressed: inFlight
          ? null
          : () => notifier.buyCourse(
                courseId: course.id,
                productId: course.productId,
              ),
      child: inFlight
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_open_rounded, size: 18),
                const SizedBox(width: 8),
                Text('Unlock for $priceLabel'),
              ],
            ),
    );
  }
}

class _UnavailableNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'In-app purchases aren\'t available on this device.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
