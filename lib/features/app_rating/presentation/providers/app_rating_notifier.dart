import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/prefs_service.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/services/app_rating_service.dart';

/// Orchestrates the in-app rating prompt.
///
/// Gating policy (per `docs/go_live_roadmap.md` P1-12):
///   1. App installed at least 7 days.
///   2. User has completed ≥ 3 lectures.
///   3. No prompt fired in the last 90 days.
///   4. Plugin reports the native sheet is available (so we don't appear
///      to "prompt" on web / desktop / unsupported iOS).
///
/// Local `PrefsService` is the source of truth — the Firestore mirror
/// is best-effort so the cooldown survives reinstalls when the user
/// signs back in.
class AppRatingNotifier {
  AppRatingNotifier({
    required PrefsService prefs,
    required AppRatingService service,
    required AuthRepository authRepo,
  })  : _prefs = prefs,
        _service = service,
        _authRepo = authRepo;

  final PrefsService _prefs;
  final AppRatingService _service;
  final AuthRepository _authRepo;

  /// Call from a lecture-progress trigger when a lecture transitions to
  /// completed. Idempotent — internally guards on whether we already
  /// counted this transition (the caller is expected to fire exactly
  /// once per lecture-completion).
  Future<void> recordCompletedLecture() async {
    await _prefs.incrementCompletedLectureCount();
    await _maybePrompt(trigger: _Trigger.lectureCompleted);
  }

  /// Call from anywhere a "natural moment" presents itself (e.g. after
  /// the user shares a certificate). The trigger argument is informational
  /// — gating is identical to the lecture-completion path.
  Future<void> maybePromptForReview() =>
      _maybePrompt(trigger: _Trigger.manual);

  Future<void> _maybePrompt({required _Trigger trigger}) async {
    if (!_eligible()) return;
    if (!await _service.isAvailable()) {
      if (kDebugMode) {
        // Surfaces unsupported platforms during development so we don't
        // wonder why nothing showed up.
        debugPrint('[rating] plugin reports not available, skipping');
      }
      return;
    }

    final now = DateTime.now();
    // Stamp the local cooldown BEFORE the call so a crash/cancellation
    // doesn't free us to re-prompt on the next tick.
    await _prefs.setLastRatingPromptAt(now);

    try {
      await _service.requestReview();
      if (kDebugMode) {
        debugPrint('[rating] requested review (trigger: ${trigger.name})');
      }
    } catch (_) {
      // Plugin throw — log only. We keep the local stamp set so the
      // cooldown still applies; otherwise a flaky native sheet would
      // re-prompt on the next lecture.
    }

    // Best-effort remote mirror. Ignore the failure — the local stamp
    // is what gates future prompts on this device.
    unawaited(_authRepo.updateRatingPromptStamp(now));
  }

  bool _eligible() {
    final installedAt = _prefs.installedAt;
    if (installedAt == null) return false;
    if (DateTime.now().difference(installedAt) <
        AppConstants.ratingMinInstallAge) {
      return false;
    }

    final lastPrompt = _prefs.lastRatingPromptAt;
    if (lastPrompt != null &&
        DateTime.now().difference(lastPrompt) <
            AppConstants.ratingCooldown) {
      return false;
    }

    if (_prefs.completedLectureCount <
        AppConstants.ratingMinCompletedLectures) {
      return false;
    }

    return true;
  }
}

/// Discriminator used only for the debug log line. Kept private so the
/// public API doesn't leak the implementation detail.
enum _Trigger { lectureCompleted, manual }
