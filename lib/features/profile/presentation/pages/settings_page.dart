import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilearnit/features/profile/presentation/providers/locale_provider.dart';
import 'package:ilearnit/features/profile/presentation/providers/locale_state.dart';
import 'package:ilearnit/features/profile/presentation/providers/theme_provider.dart';
import 'package:ilearnit/features/profile/presentation/providers/theme_state.dart';
import 'package:ilearnit/l10n/generated/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: _buildBody(context, ref, t),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AppLocalizations t) {
    final themeState = ref.watch(themeStateNotifierProvider);
    final localeState = ref.watch(localeStateNotifierProvider);
    final isDark = themeState.themeType == ThemeType.dark;

    return ListView(
      children: [
        // --- Appearance ---
        _SectionHeader(label: t.settingsAppearance),
        ListTile(
          leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          title: Text(t.settingsTheme),
          subtitle: Text(_themeLabel(t, themeState.themeType)),
          trailing: Switch(
            value: isDark,
            onChanged: (_) => _toggleTheme(ref),
          ),
          onTap: () => _toggleTheme(ref),
        ),

        const Divider(height: 1),

        // --- Language ---
        _SectionHeader(label: t.settingsLanguage),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            t.settingsLanguageDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final lang in AppLanguage.values)
          RadioListTile<AppLanguage>(
            value: lang,
            groupValue: localeState.language,
            title: Text(_languageLabel(t, lang)),
            secondary: const Icon(Icons.language),
            onChanged: (v) {
              if (v == null) return;
              ref.read(localeStateNotifierProvider.notifier).setLanguage(v);
            },
          ),
      ],
    );
  }

  String _themeLabel(AppLocalizations t, ThemeType type) {
    switch (type) {
      case ThemeType.system:
        return t.settingsThemeSystem;
      case ThemeType.light:
        return t.settingsThemeLight;
      case ThemeType.dark:
        return t.settingsThemeDark;
    }
  }

  String _languageLabel(AppLocalizations t, AppLanguage lang) {
    switch (lang) {
      case AppLanguage.en:
        return t.languageEnglish;
      case AppLanguage.vi:
        return t.languageVietnamese;
    }
  }

  Future<void> _toggleTheme(WidgetRef ref) async {
    final themeState = ref.read(themeStateNotifierProvider);
    final isDark = themeState.themeType == ThemeType.dark;
    final notifier = ref.read(themeStateNotifierProvider.notifier);
    await notifier.setThemeMode(isDark ? ThemeType.light : ThemeType.dark);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
