import 'package:flutter/material.dart';

enum Flavor {
  dev,
  prod,
}

/// Flavor accessor (set once in `main.dart` via [F.appFlavor]).
///
/// Flavorizr generates the base of this file; the helpers below are project
/// extensions used by the Dio client, theme, and routing layers.
class F {
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.dev:
        return 'iLearnIt Dev';
      case Flavor.prod:
        return 'iLearnIt';
    }
  }

  // ─── Project extensions ──────────────────────────────────────────────

  static bool get isDev => appFlavor == Flavor.dev;
  static bool get isProd => appFlavor == Flavor.prod;

  static String get apiBaseUrl {
    switch (appFlavor) {
      case Flavor.dev:
        return 'https://api.dev.ilearnit.app';
      case Flavor.prod:
        return 'https://api.ilearnit.app';
    }
  }

  static String get firebaseProjectId {
    switch (appFlavor) {
      case Flavor.dev:
        return 'ilearnit-dev';
      case Flavor.prod:
        return 'ilearnit-31f41';
    }
  }

  /// Color used for the dev-mode flavor banner.
  static Color get bannerColor => isDev
      ? const Color(0xFFE8B931) // gold
      : const Color(0xFF6C5CE7); // brand violet
}
