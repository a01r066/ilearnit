import 'package:flutter/services.dart';

import 'bootstrap.dart';
import 'flavors.dart';

/// Run with `flutter run --flavor dev` / `--flavor prod`. Flutter exposes the
/// flavor name as the global [appFlavor]; map it onto our enum.
Future<void> main() async {
  F.appFlavor = Flavor.values.firstWhere(
    (e) => e.name == appFlavor,
    orElse: () => Flavor.dev,
  );
  await bootstrap();
}
