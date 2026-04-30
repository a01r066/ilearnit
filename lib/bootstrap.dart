import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/storage/prefs_service.dart';
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

  await Firebase.initializeApp(options: _firebaseOptions());

  final prefs = await PrefsService.create();

  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
    // TODO(observability): forward to Crashlytics in prod once configured.
  };

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
      ],
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
