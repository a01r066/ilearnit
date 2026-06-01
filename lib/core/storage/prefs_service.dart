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

  // Recent searches (MRU, capped at AppConstants.recentSearchesLimit).
  List<String> get recentSearches =>
      _prefs.getStringList(AppConstants.kRecentSearches) ?? const [];

  Future<void> pushRecentSearch(String query) {
    final term = query.trim();
    if (term.isEmpty) return Future.value();
    final list = [...recentSearches];
    list.removeWhere((q) => q.toLowerCase() == term.toLowerCase());
    list.insert(0, term);
    if (list.length > AppConstants.recentSearchesLimit) {
      list.removeRange(AppConstants.recentSearchesLimit, list.length);
    }
    return _prefs.setStringList(AppConstants.kRecentSearches, list);
  }

  Future<void> clearRecentSearches() =>
      _prefs.remove(AppConstants.kRecentSearches);

  // Recently viewed songbooks (MRU list of songbook ids).
  List<String> get recentSongbookIds =>
      _prefs.getStringList(AppConstants.kRecentSongbooks) ?? const [];

  Future<void> pushRecentSongbook(String id) {
    if (id.isEmpty) return Future.value();
    final list = [...recentSongbookIds];
    list.removeWhere((x) => x == id);
    list.insert(0, id);
    if (list.length > AppConstants.recentSongbooksLimit) {
      list.removeRange(AppConstants.recentSongbooksLimit, list.length);
    }
    return _prefs.setStringList(AppConstants.kRecentSongbooks, list);
  }

  Future<void> clearRecentSongbooks() =>
      _prefs.remove(AppConstants.kRecentSongbooks);

  Future<void> clearAll() => _prefs.clear();
}
