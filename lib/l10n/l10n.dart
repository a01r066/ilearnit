import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// `context.l10n.someKey` — shorthand for `AppLocalizations.of(context)`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localized strings for code that has no [BuildContext]: error mapping,
/// validators, data-layer messages and enum labels.
///
/// Kept in sync with the app's active locale by `MaterialApp.builder`
/// (see app.dart / admin_app.dart). Defaults to English until the first
/// frame, so it is always safe to read.
class L10n {
  L10n._();

  static AppLocalizations? _current;

  static AppLocalizations get current =>
      _current ??= lookupAppLocalizations(const Locale('en'));

  static void update(AppLocalizations localizations) {
    _current = localizations;
    // Date / number formatting without an explicit locale follows the
    // app language too (DateFormat.yMMMd(), NumberFormat…).
    Intl.defaultLocale = localizations.localeName;
  }
}
