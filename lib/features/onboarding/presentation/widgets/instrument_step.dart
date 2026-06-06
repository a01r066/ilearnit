import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../courses/domain/entities/instrument_category.dart';
import '../providers/onboarding_providers.dart';

/// Step 1 — pick your primary instrument.
///
/// Persists to `users/{uid}.primaryInstrument` on finish. We avoid writing
/// here directly because the Home rail / recommendations should only flip
/// once the user actually completes the flow.
class InstrumentStep extends ConsumerWidget {
  const InstrumentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text(
          t.onboardingInstrumentTitle,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.onboardingInstrumentSubtitle,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        for (final c in InstrumentCategory.values) ...[
          _InstrumentTile(
            category: c,
            selected: state.instrument == c,
            onTap: () => notifier.selectInstrument(c),
            label: _labelFor(t, c),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  String _labelFor(AppLocalizations t, InstrumentCategory c) {
    switch (c) {
      case InstrumentCategory.guitar:
        return t.instrumentGuitar;
      case InstrumentCategory.piano:
        return t.instrumentPiano;
      case InstrumentCategory.violin:
        return t.instrumentViolin;
    }
  }
}

class _InstrumentTile extends StatelessWidget {
  const _InstrumentTile({
    required this.category,
    required this.selected,
    required this.onTap,
    required this.label,
  });

  final InstrumentCategory category;
  final bool selected;
  final VoidCallback onTap;
  final String label;

  static const _icons = {
    InstrumentCategory.guitar: Icons.music_note_rounded,
    InstrumentCategory.piano: Icons.piano_rounded,
    InstrumentCategory.violin: Icons.queue_music_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.10)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : context.colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                _icons[category],
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? AppColors.primary
                  : context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
