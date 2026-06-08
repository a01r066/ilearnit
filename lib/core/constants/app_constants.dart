/// Cross-cutting constants. Anything flavor-specific lives in `F` (flavors.dart).
class AppConstants {
  const AppConstants._();

  static const String appName = 'iLearnIt';

  // Pagination
  static const int defaultPageSize = 20;

  // Network
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  // Secure storage keys
  static const String kAccessToken = 'access_token';
  static const String kRefreshToken = 'refresh_token';

  // SharedPreferences keys
  static const String kOnboardingDone = 'onboarding_done';
  static const String kThemeMode = 'theme_mode';
  static const String kLocale = 'locale';
  static const String kRecentSearches = 'recent_searches';
  static const String kRecentSongbooks = 'recent_songbooks';

  // App rating prompt — set on first launch, bumped on each completed
  // lecture, and stamped when we show the system rating dialog.
  static const String kInstalledAt = 'installed_at';
  static const String kCompletedLectureCount = 'completed_lecture_count';
  static const String kLastRatingPromptAt = 'last_rating_prompt_at';

  // Search
  static const int recentSearchesLimit = 8;
  // Songbooks
  static const int recentSongbooksLimit = 12;

  // App-rating gating thresholds. Centralised so an A/B test on the
  // cooldown is a one-line change.
  static const Duration ratingMinInstallAge = Duration(days: 7);
  static const Duration ratingCooldown = Duration(days: 90);
  static const int ratingMinCompletedLectures = 3;
}
