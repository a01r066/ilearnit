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

  // Pending onboarding answers — used when the user completes the
  // 3-step onboarding flow BEFORE signing in (new Splash → Onboarding
  // → Login flow). The auth bootstrap reads these on the first
  // successful sign-in and writes them to users/{uid}, then clears
  // the local copies via clearPendingOnboarding().
  String? get pendingPrimaryInstrument =>
      _prefs.getString(_kPendingPrimaryInstrument);
  Future<void> setPendingPrimaryInstrument(String? v) async {
    if (v == null) {
      await _prefs.remove(_kPendingPrimaryInstrument);
    } else {
      await _prefs.setString(_kPendingPrimaryInstrument, v);
    }
  }

  String? get pendingSkillLevel =>
      _prefs.getString(_kPendingSkillLevel);
  Future<void> setPendingSkillLevel(String? v) async {
    if (v == null) {
      await _prefs.remove(_kPendingSkillLevel);
    } else {
      await _prefs.setString(_kPendingSkillLevel, v);
    }
  }

  Future<void> clearPendingOnboarding() async {
    await _prefs.remove(_kPendingPrimaryInstrument);
    await _prefs.remove(_kPendingSkillLevel);
  }

  static const _kPendingPrimaryInstrument =
      'pending_primary_instrument';
  static const _kPendingSkillLevel = 'pending_skill_level';

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

  // ---------- App rating prompt ------------------------------------------

  /// First-launch timestamp. Set once by [setInstalledAtIfMissing];
  /// never overwritten so the 7-day floor survives every relaunch.
  DateTime? get installedAt {
    final raw = _prefs.getInt(AppConstants.kInstalledAt);
    return raw == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(raw);
  }

  Future<void> setInstalledAtIfMissing(DateTime now) async {
    if (_prefs.containsKey(AppConstants.kInstalledAt)) return;
    await _prefs.setInt(
      AppConstants.kInstalledAt,
      now.millisecondsSinceEpoch,
    );
  }

  /// Monotonic count of completed lectures across all courses. Drives
  /// the "after the user finishes their 3rd lecture" rule.
  int get completedLectureCount =>
      _prefs.getInt(AppConstants.kCompletedLectureCount) ?? 0;

  Future<void> incrementCompletedLectureCount() => _prefs.setInt(
        AppConstants.kCompletedLectureCount,
        completedLectureCount + 1,
      );

  DateTime? get lastRatingPromptAt {
    final raw = _prefs.getInt(AppConstants.kLastRatingPromptAt);
    return raw == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(raw);
  }

  Future<void> setLastRatingPromptAt(DateTime when) => _prefs.setInt(
        AppConstants.kLastRatingPromptAt,
        when.millisecondsSinceEpoch,
      );

  /// QA helper — clears all three rating-related keys so the prompt
  /// can be re-tested without a clean install. Not exposed in the UI;
  /// invoke from a debug menu or `flutter run --dart-define=…`.
  Future<void> resetRatingPromptForQa() async {
    await _prefs.remove(AppConstants.kCompletedLectureCount);
    await _prefs.remove(AppConstants.kLastRatingPromptAt);
    await _prefs.remove(AppConstants.kInstalledAt);
  }

  // ----- Observability opt-out -----------------------------------------

  /// `false` (default) → Crashlytics / Performance / Analytics may run
  /// per the build-mode policy (debug off, release on). When the user
  /// flips this to `true` we shut them down at the SDK layer.
  bool get observabilityOptOut =>
      _prefs.getBool(AppConstants.kObservabilityOptOut) ?? false;

  Future<void> setObservabilityOptOut(bool value) =>
      _prefs.setBool(AppConstants.kObservabilityOptOut, value);

  Future<void> clearAll() => _prefs.clear();
}
