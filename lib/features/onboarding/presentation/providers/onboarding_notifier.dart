import 'package:firebase_messaging/firebase_messaging.dart'
    show AuthorizationStatus;
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/notifications/data/fcm_service.dart';
import '../../../../core/storage/prefs_service.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../courses/domain/entities/instrument_category.dart';
import 'onboarding_state.dart';

/// Drives the 3-screen onboarding flow.
///
/// All step transitions go through this class so the page widget stays
/// purely presentational — the PageView swipes are driven by `state.step`.
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier({
    required AuthRepository authRepo,
    required PrefsService prefs,
    required FcmService fcm,
  })  : _authRepo = authRepo,
        _prefs = prefs,
        _fcm = fcm,
        super(const OnboardingState());

  final AuthRepository _authRepo;
  final PrefsService _prefs;
  final FcmService _fcm;

  void selectInstrument(InstrumentCategory category) {
    state = state.copyWith(instrument: category);
  }

  void selectLevel(CourseLevel level) {
    state = state.copyWith(level: level);
  }

  /// Advance to the next step. Idempotent — pages call this from their
  /// "Continue" buttons without worrying about being on the right page.
  void next() {
    switch (state.step) {
      case OnboardingStep.instrument:
        if (!state.canContinueFromInstrument) return;
        state = state.copyWith(step: OnboardingStep.level);
        break;
      case OnboardingStep.level:
        if (!state.canContinueFromLevel) return;
        state = state.copyWith(step: OnboardingStep.notifications);
        break;
      case OnboardingStep.notifications:
      case OnboardingStep.completed:
        break;
    }
  }

  void back() {
    switch (state.step) {
      case OnboardingStep.notifications:
        state = state.copyWith(step: OnboardingStep.level);
        break;
      case OnboardingStep.level:
        state = state.copyWith(step: OnboardingStep.instrument);
        break;
      case OnboardingStep.instrument:
      case OnboardingStep.completed:
        break;
    }
  }

  /// Triggers the OS permission prompt. Stores the result in state but
  /// does **not** advance the step — the user must press the "Done" CTA so
  /// declining and accepting end up at the same explicit moment.
  Future<void> requestNotifications() async {
    state = state.copyWith(isBusy: true, lastFailure: null);
    try {
      final status = await _fcm.requestPermission();
      state = state.copyWith(
        isBusy: false,
        notificationsRequested: true,
        notificationsGranted: status.isAuthorizedLike,
      );
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        notificationsRequested: true,
        lastFailure: Failure.unexpected(message: e.toString(), error: e),
      );
    }
  }

  /// Final commit. The flow now runs PRE-AUTH (Splash → Onboarding →
  /// Login/Signup → Home), so onboarding can complete with no Firebase
  /// user yet.
  ///
  ///   1. If a Firebase user is already signed in, persist
  ///      `primaryInstrument` + `skillLevel` to `users/{uid}` via the
  ///      auth repo (same behaviour as before).
  ///   2. If NOT signed in (the common case in the new flow), stash
  ///      both values in PrefsService so the auth bootstrap can sync
  ///      them on first sign-in.
  ///   3. Persist `onboardingDone = true` so the router stops
  ///      redirecting to /onboarding.
  ///   4. Move to the `completed` step — the page widget listens and
  ///      routes to /login (not /home).
  ///
  /// If the user skipped the picker steps both branches above no-op;
  /// we still flip the prefs flag so we don't re-prompt.
  Future<void> finish({bool skip = false}) async {
    state = state.copyWith(isBusy: true, lastFailure: null);

    if (!skip) {
      final signedIn = await _authRepo.currentUser();
      if (signedIn != null) {
        // Authenticated path: write straight to users/{uid}.
        final result = await _authRepo.updateProfile(
          primaryInstrument: state.instrument?.id,
          skillLevel: state.level?.id,
        );
        final failure = result.fold<Failure?>((f) => f, (_) => null);
        if (failure != null) {
          state =
              state.copyWith(isBusy: false, lastFailure: failure);
          return;
        }
      } else {
        // Guest path: stash locally — auth bootstrap will sync to
        // Firestore on the next successful sign-in.
        await _prefs.setPendingPrimaryInstrument(state.instrument?.id);
        await _prefs.setPendingSkillLevel(state.level?.id);
      }
    }

    await _prefs.setOnboardingDone(true);
    state = state.copyWith(
      isBusy: false,
      step: OnboardingStep.completed,
    );
  }
}

/// Helper — `FirebaseMessaging` returns `authorized` on iOS and
/// `provisional` for the silent-auth case; treat both as a yes so we
/// don't lie to the rollup.
extension on AuthorizationStatus {
  bool get isAuthorizedLike =>
      this == AuthorizationStatus.authorized ||
      this == AuthorizationStatus.provisional;
}
