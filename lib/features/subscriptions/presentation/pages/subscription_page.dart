import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_status.dart';
import '../providers/subscription_providers.dart';
import '../providers/subscription_state.dart';

/// Screen 1 of the subscription flow — mirrors the attached Tonebase-style
/// design:
///
///   • "Active plans" section (shows current subscription if any)
///   • "Subscription plans available" section with the Personal Plan card
///   • Bullet list of features, Start subscription + Learn more CTAs
///   • "Starting at ₫250.000 per month. Cancel any time." caption
class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionNotifierProvider);
    final t = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(t.subscriptionTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // --- Active plans ---
          _SectionLabel(label: t.subscriptionActivePlans),
          const SizedBox(height: 8),
          if (state.hasActiveSubscription)
            _ActiveSubscriptionCard(status: state.status)
          else
            Text(
              t.subscriptionNoneActive,
              style: context.textTheme.bodyLarge,
            ),

          const SizedBox(height: 32),
          // --- Available plans ---
          _SectionLabel(label: t.subscriptionAvailable),
          const SizedBox(height: 8),
          _PersonalPlanCard(
            state: state,
            localeCode: localeCode,
            onStart: state.hasActiveSubscription
                ? null
                : () => context.goNamed(RouteNames.subscriptionCheckout),
            onLearnMore: () =>
                _showLearnMoreSheet(context, t, state, localeCode),
          ),

          const SizedBox(height: 16),
          if (state.lastFailure != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                state.lastFailure!.displayMessage,
                style: TextStyle(color: context.colors.error),
              ),
            ),
        ],
      ),
    );
  }

  void _showLearnMoreSheet(
    BuildContext context,
    AppLocalizations t,
    SubscriptionState state,
    String localeCode,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.personalPlanLearnMoreTitle,
                  style: context.textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(t.personalPlanLearnMoreBody),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.commonOk),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- subwidgets ----------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}

class _ActiveSubscriptionCard extends StatelessWidget {
  const _ActiveSubscriptionCard({required this.status});
  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final plan = status.plan;
    final dateFmt = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final endLabel = status.expiresAt == null
        ? '—'
        : dateFmt.format(status.expiresAt!);
    final t = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: context.colors.primary),
                const SizedBox(width: 8),
                Text(t.personalPlan,
                    style: context.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan == SubscriptionPlan.yearly
                  ? t.planBilledYearly
                  : t.planBilledMonthly,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              status.isCanceledButActive
                  ? t.subscriptionCancelsOn(endLabel)
                  : t.subscriptionRenewsOn(endLabel),
              style: context.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalPlanCard extends StatelessWidget {
  const _PersonalPlanCard({
    required this.state,
    required this.localeCode,
    required this.onStart,
    required this.onLearnMore,
  });

  final SubscriptionState state;
  final String localeCode;
  final VoidCallback? onStart;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // Per-month price for the monthly plan: prefer store-delivered string,
    // fall back to locale-aware hard-coded value.
    final monthlyPrice = state.priceByProductId[
            SubscriptionPlan.monthly.productId] ??
        SubscriptionPlan.monthly.fallbackPerMonthLabelFor(localeCode);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.personalPlan,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 12),
            Text(t.personalPlanIntro),
            const SizedBox(height: 16),
            _Feature(text: t.personalPlanFeature1),
            const SizedBox(height: 8),
            _Feature(text: t.personalPlanFeature2),
            const SizedBox(height: 8),
            _Feature(text: t.personalPlanFeature3),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onStart,
                child: Text(
                  t.startSubscription,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onLearnMore,
                child: Text(
                  t.learnMore,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.startingAtPerMonth(monthlyPrice),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.check, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: context.textTheme.bodyLarge)),
      ],
    );
  }
}
