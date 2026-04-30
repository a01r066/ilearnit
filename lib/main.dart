import 'dart:ui';

import 'package:flutter/services.dart';

import 'bootstrap.dart';
import 'flavors.dart';

/// Single entry point. Run with `--flavor dev` or `--flavor prod` and Flutter
/// passes the flavor name to the runtime [appFlavor] global, which we map to
/// our [Flavor] enum.
///
///     flutter run --flavor dev
///     flutter run --flavor prod
Future<void> main() async {
  F.appFlavor = Flavor.values.firstWhere(
    (e) => e.name == appFlavor,
    orElse: () => Flavor.dev,
  );
  await bootstrap();
}
