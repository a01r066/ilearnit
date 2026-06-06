import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/onboarding_notifier.dart';
import '../providers/onboarding_providers.dart';
import '../providers/onboarding_state.dart';
import '../widgets/instrument_step.dart';
import '../widgets/level_step.dart';
import '../widgets/notifications_step.dart';

/// Three-screen onboarding shown once per install after the first
/// successful sign-in:
///
///   1. Pick your primary instrument (writes
///      `users/{uid}.primaryInstrument`).
///   2. Pick your skill level (writes `users/{uid}.skillLevel`).
///   3. Notifications soft-ask — we explain why before triggering the OS
///      prompt.
///
/// On completion we set `PrefsService.onboardingDone = true` so the router
/// stops redirecting here. The two profile fields are best-effort: if the
/// user skips, the writes are no-ops but the prefs flag still flips so we
/// don't re-prompt forever.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    _pages = PageController();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Keep the PageView in sync with the state machine — every step is
  /// authoritative on the notifier and the PageView is a view-only mirror.
  void _syncPage(OnboardingStep step) {
    if (!_pages.hasClients) return;
    final target = switch (step) {
      OnboardingStep.instrument => 0,
      OnboardingStep.level => 1,
      OnboardingStep.notifications => 2,
      OnboardingStep.completed => 2,
    };
    if (_pages.page?.round() != target) {
      _pages.animateToPage(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    ref.listen<OnboardingState>(onboardingNotifierProvider, (_, next) {
      _syncPage(next.step);
      if (next.step == OnboardingStep.completed) {
        // Drop the PageView, route to the real app.
        context.go(RoutePaths.home);
      }
      if (next.lastFailure != null) {
        context.showSnack(next.lastFailure!.displayMessage);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              step: state.step,
              onBack: notifier.back,
              onSkip: () => notifier.finish(skip: true),
              skipLabel: t.onboardingSkip,
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  InstrumentStep(),
                  LevelStep(),
                  NotificationsStep(),
                ],
              ),
            ),
            _Footer(state: state, notifier: notifier),
          ],
        ),
      ),
    );
  }
}

// ---------- Header --------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.onBack,
    required this.onSkip,
    required this.skipLabel,
  });

  final OnboardingStep step;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    final canGoBack = step != OnboardingStep.instrument &&
        step != OnboardingStep.completed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          if (canGoBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          _StepDots(step: step),
          const Spacer(),
          TextButton(onPressed: onSkip, child: Text(skipLabel)),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});
  final OnboardingStep step;

  static const _steps = [
    OnboardingStep.instrument,
    OnboardingStep.level,
    OnboardingStep.notifications,
  ];

  @override
  Widget build(BuildContext context) {
    final activeIndex = _steps.indexOf(step).clamp(0, _steps.length - 1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: i == activeIndex ? 18 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= activeIndex
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          if (i != _steps.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

// ---------- Footer --------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.notifier});

  final OnboardingState state;
  final OnboardingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final (label, enabled, onPressed) = switch (state.step) {
      OnboardingStep.instrument => (
          t.onboardingContinue,
          state.canContinueFromInstrument,
          notifier.next,
        ),
      OnboardingStep.level => (
          t.onboardingContinue,
          state.canContinueFromLevel,
          notifier.next,
        ),
      OnboardingStep.notifications => (
          state.notificationsRequested
              ? t.onboardingDone
              : t.onboardingEnableNotifications,
          true,
          state.notificationsRequested
              ? () => notifier.finish()
              : notifier.requestNotifications,
        ),
      OnboardingStep.completed => (t.onboardingDone, false, null),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: (enabled && !state.isBusy) ? onPressed : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: state.isBusy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}
