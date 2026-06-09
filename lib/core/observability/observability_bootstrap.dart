import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'analytics_service.dart';
import 'crashlytics_service.dart';
import 'observability_providers.dart';

/// Keeps Crashlytics + Analytics user identity in lock-step with the
/// auth state.
///
/// Activated by reading [observabilityAuthLinkProvider] once in the
/// bootstrap — Riverpod's `ref.listen` keeps the subscription alive
/// for the lifetime of the container.
final observabilityAuthLinkProvider = Provider<void>((ref) {
  // Capture the services up-front so the listener doesn't need to
  // call `ref.read` on every auth change.
  final crashlytics = ref.read(crashlyticsServiceProvider);
  final analytics = ref.read(analyticsServiceProvider);

  ref.listen<UserEntity?>(
    currentUserProvider,
    (previous, next) {
      _syncUserIdentity(
        crashlytics: crashlytics,
        analytics: analytics,
        user: next,
      );
    },
    fireImmediately: true,
  );
});

Future<void> _syncUserIdentity({
  required CrashlyticsService crashlytics,
  required AnalyticsService analytics,
  required UserEntity? user,
}) async {
  if (user == null) {
    await crashlytics.setUserId(null);
    await analytics.setUserId(null);
    await analytics.setRole(null);
    await analytics.setSkillLevel(null);
    await analytics.setPrimaryInstrument(null);
    return;
  }
  await crashlytics.setUserId(user.id);
  await crashlytics.setCustomKey('role', user.role.id);
  await analytics.setUserId(user.id);
  await analytics.setRole(user.role.id);
  await analytics.setSkillLevel(user.skillLevel);
  // `primaryInstrument` lives on UserEntity once onboarding sets it —
  // call site is optional. We send what we have today; an empty
  // string clears the previous value.
  await analytics.setPrimaryInstrument(user.primaryInstrument);
}
