import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../courses/domain/entities/instrument_category.dart';
import '../providers/onboarding_providers.dart';

/// Step 2 — pick your skill level. Drives recommendations on the Home rail
/// and the default filter on the Courses list.
class LevelStep extends ConsumerWidget {
  const LevelStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text(
          t.onboardingLevelTitle,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.onboardingLevelSubtitle,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        for (final l in CourseLevel.values) ...[
          _LevelTile(
            level: l,
            selected: state.level == l,
            onTap: () => notifier.selectLevel(l),
            title: _title(t, l),
            blurb: _blurb(t, l),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  String _title(AppLocalizations t, CourseLevel l) {
    switch (l) {
      case CourseLevel.beginner:
        return t.onboardingLevelBeginner;
      case CourseLevel.intermediate:
        return t.onboardingLevelIntermediate;
      case CourseLevel.advanced:
        return t.onboardingLevelAdvanced;
    }
  }

  String _blurb(AppLocalizations t, CourseLevel l) {
    switch (l) {
      case CourseLevel.beginner:
        return t.onboardingLevelBeginnerBlurb;
      case CourseLevel.intermediate:
        return t.onboardingLevelIntermediateBlurb;
      case CourseLevel.advanced:
        return t.onboardingLevelAdvancedBlurb;
    }
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.selected,
    required this.onTap,
    required this.title,
    required this.blurb,
  });

  final CourseLevel level;
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String blurb;

  static const _icons = {
    CourseLevel.beginner: Icons.eco_rounded,
    CourseLevel.intermediate: Icons.trending_up_rounded,
    CourseLevel.advanced: Icons.workspace_premium_rounded,
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                _icons[level],
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    blurb,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
