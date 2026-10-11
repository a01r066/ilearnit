// lib/app/app.dart — the l10n-relevant parts of MaterialApp.router.
//
// MaterialApp.router(
//   routerConfig: router,
//   locale: ref.watch(localeProvider),          // null = follow device
//   localizationsDelegates: AppLocalizations.localizationsDelegates,
//   supportedLocales: AppLocalizations.supportedLocales,
//   onGenerateTitle: (context) => context.l10n.appTitle,
//   builder: (context, child) {
//     // Keep L10n.current + Intl.defaultLocale in sync with the UI locale
//     // so error mappers, validators and DateFormat follow the app language.
//     L10n.update(AppLocalizations.of(context));
//     return AppUpdateGate(child: child!);
//   },
// );

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Enum pattern: wire value for storage, englishLabel for logs/admin
/// exports, label for UI (follows the app language).
enum Difficulty {
  beginner('beginner'),
  intermediate('intermediate'),
  advanced('advanced');

  const Difficulty(this.wire);
  final String wire;

  static Difficulty fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => beginner);

  String get englishLabel => switch (this) {
        beginner => 'Beginner',
        intermediate => 'Intermediate',
        advanced => 'Advanced',
      };

  String get label => switch (this) {
        beginner => L10n.current.difficultyBeginner,
        intermediate => L10n.current.difficultyIntermediate,
        advanced => L10n.current.difficultyAdvanced,
      };
}

/// Localized markdown asset with English fallback:
///   assets/legal/privacy_policy.md      (English, authoritative)
///   assets/legal/privacy_policy_vi.md   (translation)
Future<String> loadLocalizedAsset(
  AssetBundle bundle,
  String englishPath,
  String languageCode,
) async {
  if (languageCode != 'en') {
    try {
      return await bundle.loadString(englishPath.replaceFirst('.md', '_$languageCode.md'));
    } catch (_) {/* fall back to English */}
  }
  return bundle.loadString(englishPath);
}
