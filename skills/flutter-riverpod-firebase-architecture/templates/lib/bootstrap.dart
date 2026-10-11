import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/session_cleanup.dart';
import 'core/security/app_check_bootstrap.dart';
import 'firebase_options_dev.dart' as dev_opts;
import 'firebase_options_prod.dart' as prod_opts;
import 'flavors.dart';
import 'shared/providers/core_providers.dart';

/// Top-level so the OS-spawned background isolate can find it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: _firebaseOptions());
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  // DEFAULT app from the flavor's options. iOS bundles no
  // GoogleService-Info.plist on purpose, so a dev build can never reach prod.
  await Firebase.initializeApp(options: _firebaseOptions());

  // Before any Firestore / Functions / Storage call.
  await activateAppCheck();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  if (kReleaseMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [prefsProvider.overrideWithValue(prefs)],
  );

  // Eager listeners — must exist before the first frame:
  //   container.read(purchasesNotifierProvider);   // IAP purchase stream
  //   container.read(notificationBootstrapProvider);
  container.read(sessionCleanupProvider);

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}

FirebaseOptions _firebaseOptions() => switch (F.appFlavor) {
      Flavor.dev => dev_opts.DefaultFirebaseOptions.currentPlatform,
      Flavor.prod => prod_opts.DefaultFirebaseOptions.currentPlatform,
    };
