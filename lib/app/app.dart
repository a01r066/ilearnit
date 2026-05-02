import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilearnit/features/profile/presentation/providers/theme_provider.dart';

import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/profile/presentation/providers/theme_state.dart';
import '../flavors.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    final themeState = ref.watch(themeStateNotifierProvider);
    ThemeData lightTheme;
    ThemeData? darkTheme;

    switch (themeState.themeType) {
      case ThemeType.light:
        lightTheme = AppTheme.light();
        break;
      case ThemeType.dark:
        lightTheme = AppTheme.dark();
        break;
      case ThemeType.system:
      // Use default Material 3 themes for system mode
        lightTheme = ThemeData(useMaterial3: true);
        darkTheme = ThemeData(useMaterial3: true);
        break;
    }

    ThemeMode themeMode;
    if (themeState.themeType == ThemeType.system) {
      themeMode = ThemeMode.system;
    } else {
      themeMode = themeState.themeType == ThemeType.dark ? ThemeMode.dark : ThemeMode.light;
    }

    return MaterialApp.router(
      title: F.title,
      debugShowCheckedModeBanner: F.isDev,
      theme: lightTheme,
      // darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
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
}
