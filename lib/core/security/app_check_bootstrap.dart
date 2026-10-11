import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../../flavors.dart';

/// reCAPTCHA v3 site key for the admin web portal. Pass at build time:
///   flutter build web -t lib/main_admin.dart \
///     --dart-define=FLAVOR=prod --dart-define=RECAPTCHA_SITE_KEY=<key>
const _recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

/// Activates Firebase App Check right after `Firebase.initializeApp`.
///
/// • prod  — Play Integrity (Android), App Attest with DeviceCheck
///           fallback (iOS), reCAPTCHA v3 (web).
/// • dev / debug builds — debug providers. The first run logs a debug
///   token; register it in Firebase Console → App Check → Apps →
///   Manage debug tokens so emulators / simulators keep working once
///   enforcement is on.
///
/// Enforcement itself is switched on per product in the Firebase Console
/// (Firestore, Storage) and for callables via the `ENFORCE_APP_CHECK`
/// functions param — start in monitor mode (see
/// docs/production_migration.md §2.8). Activation never throws: a failure
/// is logged and the app continues (requests just carry no token).
Future<void> activateAppCheck() async {
  final useDebug = F.isDev || !kReleaseMode;
  try {
    if (kIsWeb) {
      if (_recaptchaSiteKey.isEmpty) {
        if (kDebugMode) {
          debugPrint('[app-check] RECAPTCHA_SITE_KEY not set — skipped on web');
        }
        return;
      }
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(_recaptchaSiteKey),
      );
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerAndroid: useDebug
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: useDebug
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  } catch (e) {
    if (kDebugMode) debugPrint('[app-check] activation failed: $e');
  }
}
