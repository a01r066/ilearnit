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
}
