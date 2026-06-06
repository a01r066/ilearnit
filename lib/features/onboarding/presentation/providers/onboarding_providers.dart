import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/notifications/presentation/notification_providers.dart';
import '../../../../shared/providers/storage_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'onboarding_notifier.dart';
import 'onboarding_state.dart';

/// Scoped to the lifetime of the OnboardingPage. AutoDispose so the state
/// resets if the user backs out (shouldn't happen — the router gates it —
/// but defensively correct).
final onboardingNotifierProvider = StateNotifierProvider.autoDispose<
    OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(
    authRepo: ref.watch(authRepositoryProvider),
    prefs: ref.watch(prefsProvider),
    fcm: ref.watch(fcmServiceProvider),
  ),
);
