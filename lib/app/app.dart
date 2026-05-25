import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilearnit/features/profile/presentation/providers/locale_provider.dart';
import 'package:ilearnit/features/profile/presentation/providers/theme_provider.dart';

import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/profile/presentation/providers/theme_state.dart';
import '../flavors.dart';
import '../l10n/generated/app_localizations.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    final themeState = ref.watch(themeStateNotifierProvider);
    final localeState = ref.watch(localeStateNotifierProvider);

    final spec = _resolveTheme(themeState.themeType);

    return MaterialApp.router(
      title: F.title,
      debugShowCheckedModeBanner: F.isDev,
      theme: spec.light,
      darkTheme: spec.dark,
      themeMode: spec.mode,
      routerConfig: router,

      // --- Localization ---
      locale: localeState.language.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      builder: (context, child) {
        if (!F.isDev) return child ?? const SizedBox.shrink();
        return Banner(
          message: F.name.toUpperCase(),
          location: BannerLocation.topEnd,
          color: F.bannerColor,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  /// Resolve a [ThemeType] into the concrete `(light, dark, mode)` triple
  /// that [MaterialApp.router] expects.
  ///
  /// - Vibrant / Professional lock to light mode so the picked look is what
  ///   the user sees regardless of OS preference.
  /// - System provides both a light + dark ThemeData and lets the OS pick.
  static _ThemeSpec _resolveTheme(ThemeType type) {
    switch (type) {
      case ThemeType.vibrant:
        return _ThemeSpec(
          light: AppTheme.vibrant(),
          dark: null,
          mode: ThemeMode.light,
        );
      case ThemeType.professional:
        return _ThemeSpec(
          light: AppTheme.professional(),
          dark: null,
          mode: ThemeMode.light,
        );
      case ThemeType.system:
        return _ThemeSpec(
          light: AppTheme.systemLight(),
          dark: AppTheme.systemDark(),
          mode: ThemeMode.system,
        );
    }
  }
}

class _ThemeSpec {
  const _ThemeSpec({required this.light, required this.dark, required this.mode});
  final ThemeData light;
  final ThemeData? dark;
  final ThemeMode mode;
}
