import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';
import '../../../courses/domain/entities/instrument_category.dart';

/// Stage of the 3-screen onboarding PageView.
enum OnboardingStep { instrument, level, notifications, completed }

/// Hand-rolled immutable state (no freezed → no codegen needed to compile).
@immutable
class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.instrument,
    this.instrument,
    this.level,
    this.notificationsRequested = false,
    this.notificationsGranted = false,
    this.isBusy = false,
    this.lastFailure,
  });

  final OnboardingStep step;
  final InstrumentCategory? instrument;
  final CourseLevel? level;

  /// True once we've called `FcmService.requestPermission()` — used to
  /// flip the soft-ask CTA from "Enable notifications" → "Done".
  final bool notificationsRequested;

  /// True if the user granted permission on the system prompt. We persist
  /// the choice but do not block the user from finishing onboarding if
  /// they decline.
  final bool notificationsGranted;

  final bool isBusy;
  final Failure? lastFailure;

  bool get canContinueFromInstrument => instrument != null;
  bool get canContinueFromLevel => level != null;

  OnboardingState copyWith({
    OnboardingStep? step,
    Object? instrument = _unset,
    Object? level = _unset,
    bool? notificationsRequested,
    bool? notificationsGranted,
    bool? isBusy,
    Object? lastFailure = _unset,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      instrument: identical(instrument, _unset)
          ? this.instrument
          : instrument as InstrumentCategory?,
      level: identical(level, _unset) ? this.level : level as CourseLevel?,
      notificationsRequested:
          notificationsRequested ?? this.notificationsRequested,
      notificationsGranted:
          notificationsGranted ?? this.notificationsGranted,
      isBusy: isBusy ?? this.isBusy,
      lastFailure: identical(lastFailure, _unset)
          ? this.lastFailure
          : lastFailure as Failure?,
    );
  }

  static const Object _unset = Object();
}
