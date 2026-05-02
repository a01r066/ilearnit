import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilearnit/core/utils/extensions.dart';
import 'package:ilearnit/features/profile/presentation/providers/theme_provider.dart';
import 'package:ilearnit/features/profile/presentation/providers/theme_state.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref){
    final themeState = ref.watch(themeStateNotifierProvider);
    final isDark = themeState.themeType == ThemeType.dark;

    return ListView(
      children: [
        ListTile(
          leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          title: Text('${themeState.themeType.name.capitalize()} theme'),
          trailing: Switch(value: isDark, onChanged: (value){
            toggleTheme(ref);
          }),
          onTap: () {
            toggleTheme(ref);
          },
        ),
      ],
    );
  }

  Future<void> toggleTheme(WidgetRef ref) async {
    final themeState = ref.watch(themeStateNotifierProvider);
    final isDark = themeState.themeType == ThemeType.dark;

    final themeNotifier = ref.read(themeStateNotifierProvider.notifier);
    await themeNotifier.setThemeMode(isDark ? ThemeType.light : ThemeType.dark);
  }
}
