import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../flavors.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: F.title,
      debugShowCheckedModeBanner: F.isDev,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
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
