import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/notifications/data/fcm_service.dart';
import 'core/notifications/presentation/notification_providers.dart';
import 'core/observability/observability_bootstrap.dart';
import 'core/observability/observability_providers.dart';
import 'core/storage/prefs_service.dart';
import 'features/purchases/presentation/providers/purchases_providers.dart';
import 'features/subscriptions/presentation/providers/subscription_providers.dart';
import 'firebase_options_dev.dart' as dev_opts;
import 'firebase_options_prod.dart' as prod_opts;
import 'flavors.dart';
import 'shared/providers/storage_providers.dart';

/// Single bootstrap entry — initializes Flutter bindings, Firebase, prefs,
/// and runs the [App] inside a [ProviderScope].
///
/// `main.dart` calls this AFTER setting `F.appFlavor`. The bootstrap reads
/// `F.appFlavor` to pick the correct Firebase options.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: _firebaseOptions(), name: 'ilearnit');

  // Register the FCM background message handler immediately after Firebase
  // is up — must happen before runApp so the OS-spawned isolate can find it.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final prefs = await PrefsService.create();
  // Stamp the first-launch timestamp — gates the 7-day floor on the
  // in-app rating prompt (P1-12). No-op on subsequent launches.
  await prefs.setInstalledAtIfMissing(DateTime.now());

  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
    ],
  );

  // ----- Observability ----------------------------------------------------
  //
  // Wire Crashlytics' global error handlers before any other code can
  // throw so the first crash on a cold-start path is captured. Honour
  // the user opt-out flag stored in prefs (defaults to "opted-in" but
  // still gated on `kReleaseMode` for Crashlytics — see the policy
  // method).
  final userOptIn = !prefs.observabilityOptOut;
  final crashlytics = container.read(crashlyticsServiceProvider);
  await crashlytics.installErrorHandlers();
  await crashlytics.applyCollectionPolicy(userOptIn: userOptIn);

  final performance = container.read(performanceServiceProvider);
  await performance.setEnabled(userOptIn);

  final analytics = container.read(analyticsServiceProvider);
  await analytics.setEnabled(userOptIn);
  // Fire-and-forget — the first `app_start` event also unsticks the
  // Analytics dashboard latency on debug devices.
  unawaited(analytics.logAppStart());

  // Activate the auth → Crashlytics/Analytics user-identity link. The
  // provider attaches a `ref.listen` on `currentUserProvider`; reading
  // it once is enough to keep the subscription alive.
  container.read(observabilityAuthLinkProvider);

  // Catch anything FlutterError.onError doesn't already handle and
  // fall back to console logging in debug.
  if (kDebugMode) {
    final prev = FlutterError.onError;
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
      prev?.call(details);
    };
  }

  // Eagerly initialize the IAP listener so background purchases that the
  // OS delivers before any UI renders are still captured. Reading the
  // provider triggers its constructor → subscribes to purchaseStream.
  container.read(purchasesNotifierProvider);

  // Same reasoning for the subscription notifier — it listens to the IAP
  // stream and writes entitlements to Firestore.
  container.read(subscriptionNotifierProvider);

  // Eagerly init the notification bootstrap so the FCM/local stack is up
  // and listening before the first UI render.
  container.read(notificationBootstrapProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
}

FirebaseOptions _firebaseOptions() {
  switch (F.appFlavor) {
    case Flavor.dev:
      return dev_opts.DefaultFirebaseOptions.currentPlatform;
    case Flavor.prod:
      return prod_opts.DefaultFirebaseOptions.currentPlatform;
  }
}
