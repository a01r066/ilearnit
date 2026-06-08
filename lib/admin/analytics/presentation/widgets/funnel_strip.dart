import 'package:flutter/material.dart';

import '../../domain/entities/cohort_matrix.dart';

/// Horizontal funnel: total users → onboarded → any payment → active
/// subscribers. We render as four equal-width cards because the
/// numbers themselves are usually small and clean stacked-area is
/// hard to read at low N.
class FunnelStrip extends StatelessWidget {
  const FunnelStrip({super.key, required this.funnel});
  final FunnelCounts funnel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Stage(
          label: 'Signed up',
          value: funnel.totalUsers,
          rate: 1.0,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        _Stage(
          label: 'Onboarded',
          value: funnel.onboarded,
          rate: funnel.onboardedRate,
          color: theme.colorScheme.secondaryContainer,
        ),
        _Stage(
          label: 'Made a payment',
          value: funnel.payingUsers,
          rate: funnel.conversionRate,
          color: theme.colorScheme.primaryContainer,
        ),
        _Stage(
          label: 'Active subscribers',
          value: funnel.activeSubscribers,
          rate: funnel.subscriptionRate,
          color: theme.colorScheme.primary,
          inverted: true,
        ),
      ],
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.label,
    required this.value,
    required this.rate,
    required this.color,
    this.inverted = false,
  });
  final String label;
  final int value;
  final double rate;
  final Color color;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onColor = inverted
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onColor.withValues(alpha: 0.85),
                )),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: theme.textTheme.displaySmall?.copyWith(
                color: onColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(rate * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: onColor.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
