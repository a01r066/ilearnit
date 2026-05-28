import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/profile/presentation/providers/locale_provider.dart';
import '../flavors.dart';
import '../l10n/generated/app_localizations.dart';
import 'routing/admin_router.dart';

/// Root widget of the admin web portal.
///
/// Built separately from the consumer mobile app: its [MaterialApp.router]
/// uses [adminGoRouterProvider] instead of the consumer router, and ignores
/// the [ThemeNotifier] in favour of a fixed Vibrant theme — the admin UI is
/// chrome and doesn't need to expose the user-facing theme picker.
class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminGoRouterProvider);
    final localeState = ref.watch(localeStateNotifierProvider);

    return MaterialApp.router(
      title: '${F.title} · Admin',
      debugShowCheckedModeBanner: F.isDev,
      theme: AppTheme.vibrant(),
      darkTheme: AppTheme.systemDark(),
      themeMode: ThemeMode.light,
      routerConfig: router,

      // --- Localization ---
      locale: localeState.language.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      builder: (context, child) {
        if (!F.isDev) return child ?? const SizedBox.shrink();
        return Banner(
          message: 'ADMIN · ${F.name.toUpperCase()}',
          location: BannerLocation.topEnd,
          color: F.bannerColor,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
