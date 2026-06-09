import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ilearnit/core/observability/observability_providers.dart';
import 'package:ilearnit/core/routing/route_names.dart';
import 'package:ilearnit/core/theme/app_colors.dart';
import 'package:ilearnit/shared/providers/storage_providers.dart';
import 'package:ilearnit/features/legal/presentation/pages/legal_document_page.dart';
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

    return ListView(
      children: [
        // --- Appearance ---
        _SectionHeader(label: t.settingsAppearance),
        _SectionDescription(text: t.settingsThemeDescription),
        for (final type in ThemeType.values)
          RadioListTile<ThemeType>(
            value: type,
            groupValue: themeState.themeType,
            title: Text(_themeLabel(t, type)),
            secondary: Icon(_themeIcon(type)),
            onChanged: (v) {
              if (v == null) return;
              ref.read(themeStateNotifierProvider.notifier).setThemeType(v);
            },
          ),

        const Divider(height: 1),

        // --- Language ---
        _SectionHeader(label: t.settingsLanguage),
        _SectionDescription(text: t.settingsLanguageDescription),
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

        const Divider(height: 1),

        // --- Notifications ---
        _SectionHeader(label: t.notificationsPrefsTitle),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: Text(t.notificationsPrefsTitle),
          subtitle: Text(t.notificationsPrefsSubtitleShort),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              context.pushNamed(RouteNames.notificationPreferences),
        ),

        const Divider(height: 1),

        // --- Legal ---
        _SectionHeader(label: t.legalAbout),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(t.legalPrivacyPolicyTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushNamed(
            RouteNames.legal,
            pathParameters: {'slug': LegalDocument.privacyPolicy.slug},
          ),
        ),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: Text(t.legalTermsOfServiceTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushNamed(
            RouteNames.legal,
            pathParameters: {'slug': LegalDocument.termsOfService.slug},
          ),
        ),

        const Divider(height: 32),

        // --- Privacy --------------------------------------------------
        // Single toggle for Analytics + Performance + Crashlytics.
        // Off → all three SDKs stop collecting on next launch (the
        // bootstrap reads this on init); already-buffered events are
        // dropped per SDK semantics.
        _PrivacyToggle(),

        const Divider(height: 32),

        // --- Danger zone ---
        ListTile(
          leading: const Icon(Icons.delete_forever_rounded,
              color: AppColors.error),
          title: Text(
            t.deleteAccountTitle,
            style: const TextStyle(color: AppColors.error),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.error),
          onTap: () => context.pushNamed(RouteNames.deleteAccount),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _themeLabel(AppLocalizations t, ThemeType type) {
    switch (type) {
      case ThemeType.system:
        return t.settingsThemeSystem;
      case ThemeType.vibrant:
        return t.settingsThemeVibrant;
      case ThemeType.professional:
        return t.settingsThemeProfessional;
    }
  }

  IconData _themeIcon(ThemeType type) {
    switch (type) {
      case ThemeType.system:
        return Icons.brightness_auto_rounded;
      case ThemeType.vibrant:
        return Icons.palette_rounded;
      case ThemeType.professional:
        return Icons.work_outline_rounded;
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

class _SectionDescription extends StatelessWidget {
  const _SectionDescription({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Master switch for Crashlytics + Performance + Analytics. The
/// stored value is the *opt-out* boolean — a fresh install is
/// opted-in. Toggling flips all three SDKs immediately and is
/// re-applied at the next launch by `bootstrap.dart`.
class _PrivacyToggle extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PrivacyToggle> createState() => _PrivacyToggleState();
}

class _PrivacyToggleState extends ConsumerState<_PrivacyToggle> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = !ref.read(prefsProvider).observabilityOptOut;
  }

  Future<void> _onChanged(bool value) async {
    setState(() => _enabled = value);
    await ref.read(prefsProvider).setObservabilityOptOut(!value);
    await ref.read(crashlyticsServiceProvider).applyCollectionPolicy(
          userOptIn: value,
        );
    await ref.read(performanceServiceProvider).setEnabled(value);
    await ref.read(analyticsServiceProvider).setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(label: t.settingsPrivacySection),
        SwitchListTile(
          secondary: const Icon(Icons.privacy_tip_outlined),
          title: Text(t.settingsAnalyticsTitle),
          subtitle: Text(t.settingsAnalyticsSubtitle),
          value: _enabled,
          onChanged: _onChanged,
        ),
      ],
    );
  }
}
