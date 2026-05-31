import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/subscription_plan.dart';
import '../providers/subscription_providers.dart';

/// Screen 2 of the subscription flow — mirrors the attached design:
///
///   • Yearly / Monthly radio cards (Yearly shows a savings badge)
///   • Feature checkmarks
///   • Summary with "Total due today"
///   • Bold disclaimer + Terms of Use link
///   • Purple "Start subscription" CTA
class SubscriptionCheckoutPage extends ConsumerStatefulWidget {
  const SubscriptionCheckoutPage({super.key});

  @override
  ConsumerState<SubscriptionCheckoutPage> createState() =>
      _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState
    extends ConsumerState<SubscriptionCheckoutPage> {
  SubscriptionPlan _selected = SubscriptionPlan.yearly;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionNotifierProvider);
    final t = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    final yearlyTotal = state.priceByProductId[
            SubscriptionPlan.yearly.productId] ??
        SubscriptionPlan.yearly.fallbackLabelFor(localeCode);

    final monthlyTotal = state.priceByProductId[
            SubscriptionPlan.monthly.productId] ??
        SubscriptionPlan.monthly.fallbackLabelFor(localeCode);

    final selectedTotal =
        _selected == SubscriptionPlan.yearly ? yearlyTotal : monthlyTotal;

    return Scaffold(
      appBar: AppBar(title: Text(t.checkoutTitle)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 280),
            children: [
              Text(t.checkoutTitle,
                  style: context.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 24),
              Text(t.personalPlan,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 16),

              // ---------- Yearly card ----------
              _PlanCard(
                title: t.yearlyAccess,
                selected: _selected == SubscriptionPlan.yearly,
                onTap: () =>
                    setState(() => _selected = SubscriptionPlan.yearly),
                priceLine:
                    '${SubscriptionPlan.yearly.fallbackPerMonthLabelFor(localeCode)}/mo',
                periodLabel: t.billedYearly,
                badge: _savingsLabel(localeCode, t),
              ),
              const SizedBox(height: 12),

              // ---------- Monthly card ----------
              _PlanCard(
                title: t.monthlyAccess,
                selected: _selected == SubscriptionPlan.monthly,
                onTap: () =>
                    setState(() => _selected = SubscriptionPlan.monthly),
                priceLine:
                    '${SubscriptionPlan.monthly.fallbackPerMonthLabelFor(localeCode)}/mo',
                periodLabel: t.billedMonthly,
              ),
              const SizedBox(height: 24),

              _Feature(text: t.checkoutFeature1),
              const SizedBox(height: 12),
              _Feature(text: t.checkoutFeature2),
              const SizedBox(height: 12),
              _Feature(text: t.checkoutFeature3),
              const SizedBox(height: 32),

              Text(t.summary,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.totalDueToday,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
                  Text(selectedTotal,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
                ],
              ),
            ],
          ),

          // Bottom sheet: disclaimer + CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomCta(
              disclaimer: _disclaimer(t, selectedTotal),
              ctaLabel: t.startSubscription,
              ctaEnabled: !state.purchaseInFlight,
              isLoading: state.purchaseInFlight,
              onPressed: () async {
                await ref
                    .read(subscriptionNotifierProvider.notifier)
                    .buy(_selected);
                final failure =
                    ref.read(subscriptionNotifierProvider).lastFailure;
                if (!mounted) return;
                if (failure != null) {
                  context.showSnack(failure.displayMessage);
                } else if (ref
                    .read(subscriptionNotifierProvider)
                    .hasActiveSubscription) {
                  context.pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _savingsLabel(String localeCode, AppLocalizations t) {
    // 12 × monthly price − yearly price = annual savings.
    if (localeCode == 'vi') {
      final saved = SubscriptionPlan.monthly.fallbackVnd * 12 -
          SubscriptionPlan.yearly.fallbackVnd;
      return t.saveAmount('₫${_thousands(saved, ".")}');
    }
    final saved =
        SubscriptionPlan.monthly.fallbackUsd * 12 - SubscriptionPlan.yearly.fallbackUsd;
    return t.saveAmount('\$${saved.toStringAsFixed(2)}');
  }

  String _disclaimer(AppLocalizations t, String total) {
    return t.checkoutBillingDisclaimer(total);
  }

  static String _thousands(int n, String sep) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(sep);
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ---------- helpers -------------------------------------------------------

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.priceLine,
    required this.periodLabel,
    this.badge,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final String priceLine;
  final String periodLabel;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? context.colors.onSurface
                  : context.colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style:
                                context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB5DCC8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Color(0xFF103B2C),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(priceLine,
                            style: context.textTheme.titleMedium),
                        const SizedBox(width: 8),
                        Text(periodLabel,
                            style:
                                context.textTheme.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.disclaimer,
    required this.ctaLabel,
    required this.ctaEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  final String disclaimer;
  final String ctaLabel;
  final bool ctaEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(disclaimer,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  )),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: ctaEnabled ? onPressed : null,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        ctaLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
