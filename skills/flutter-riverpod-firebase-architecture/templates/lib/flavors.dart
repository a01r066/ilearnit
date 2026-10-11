enum Flavor { dev, prod }

/// Set once in main.dart. Keep per-flavor constants here (titles, package
/// names for store links, public URLs) — never secrets.
class F {
  static late final Flavor appFlavor;

  static bool get isDev => appFlavor == Flavor.dev;
  static bool get isProd => appFlavor == Flavor.prod;

  static String get title => switch (appFlavor) {
        Flavor.dev => 'MyApp Dev',
        Flavor.prod => 'MyApp',
      };

  /// Android applicationId (store deep links, "manage subscription").
  static String get androidPackageName => switch (appFlavor) {
        Flavor.dev => 'com.example.app.dev',
        Flavor.prod => 'com.example.app',
      };
}
