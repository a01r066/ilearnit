import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin/admin_app.dart';
import 'core/storage/prefs_service.dart';
import 'firebase_options_dev.dart' as dev_opts;
import 'firebase_options_prod.dart' as prod_opts;
import 'flavors.dart';
import 'shared/providers/storage_providers.dart';

/// Bootstrap entry point for the admin web portal.
///
/// Mirrors `bootstrap.dart` but:
///   - skips orientation locks (web)
///   - skips the IAP listener (admin doesn't need in-app purchases)
///   - mounts [AdminApp] instead of the consumer [App]
Future<void> bootstrapAdmin() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: _firebaseOptions());

  final prefs = await PrefsService.create();

  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
    // TODO(observability): forward to Crashlytics in prod.
  };

  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AdminApp(),
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
