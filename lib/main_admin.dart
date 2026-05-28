import 'bootstrap_admin.dart';
import 'flavors.dart';

/// Admin web portal entry point. Build with:
///
///     flutter build web -t lib/main_admin.dart --flavor dev
///     flutter build web -t lib/main_admin.dart --flavor prod
///
/// Or run locally:
///
///     flutter run -d chrome -t lib/main_admin.dart --flavor dev
Future<void> main() async {
  // Web doesn't propagate the `--flavor` flag to `appFlavor` like mobile
  // does, so fall back to the default `Flavor.dev` if unset.
  F.appFlavor = Flavor.values.firstWhere(
    (e) => e.name == const String.fromEnvironment('FLAVOR', defaultValue: 'dev'),
    orElse: () => Flavor.dev,
  );
  await bootstrapAdmin();
}
