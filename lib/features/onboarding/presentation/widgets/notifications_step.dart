import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/onboarding_providers.dart';

/// Step 3 — notifications soft-ask.
///
/// Apple + Google strongly recommend explaining the value of notifications
/// before triggering the OS prompt; users who decline the system prompt
/// rarely re-enable from Settings. We show three concrete reasons here.
///
/// The actual permission call is fired by the footer button on the
/// [OnboardingPage] (via the notifier). This widget is presentational so
/// the screen stays consistent with the other two steps.
class NotificationsStep extends ConsumerWidget {
  const NotificationsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(onboardingNotifierProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          t.onboardingNotificationsTitle,
          textAlign: TextAlign.center,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.onboardingNotificationsSubtitle,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        _BulletRow(
          icon: Icons.school_rounded,
          text: t.onboardingNotificationsReason1,
        ),
        const SizedBox(height: 16),
        _BulletRow(
          icon: Icons.new_releases_rounded,
          text: t.onboardingNotificationsReason2,
        ),
        const SizedBox(height: 16),
        _BulletRow(
          icon: Icons.event_available_rounded,
          text: t.onboardingNotificationsReason3,
        ),
        if (state.notificationsRequested) ...[
          const SizedBox(height: 32),
          Center(
            child: Text(
              state.notificationsGranted
                  ? t.onboardingNotificationsThanks
                  : t.onboardingNotificationsCanChange,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: context.textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}
