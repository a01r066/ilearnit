import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Thin wrapper over `shared_preferences` for non-sensitive flags.
class PrefsService {
  PrefsService(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsService> create() async =>
      PrefsService(await SharedPreferences.getInstance());

  // Onboarding
  bool get onboardingDone =>
      _prefs.getBool(AppConstants.kOnboardingDone) ?? false;

  Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(AppConstants.kOnboardingDone, value);

  // Theme mode
  String? get themeMode => _prefs.getString(AppConstants.kThemeMode);
  Future<void> setThemeMode(String value) =>
      _prefs.setString(AppConstants.kThemeMode, value);

  // Locale
  String? get locale => _prefs.getString(AppConstants.kLocale);
  Future<void> setLocale(String value) =>
      _prefs.setString(AppConstants.kLocale, value);

  Future<void> clearAll() => _prefs.clear();
}
