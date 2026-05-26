// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'iLearnIt';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get navHome => 'Home';

  @override
  String get navCourses => 'Courses';

  @override
  String get navInstructors => 'Instructors';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeWelcomeAnon => 'Welcome to iLearnIt';

  @override
  String homeWelcomeNamed(String name) {
    return 'Hello, $name 👋';
  }

  @override
  String get homeWelcomeSubtitle => 'What will you practice today?';

  @override
  String get homeBrowseByInstrument => 'Browse by instrument';

  @override
  String get homeFeaturedCourses => 'Featured courses';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeNoFeaturedYet => 'No featured courses yet.';

  @override
  String get instrumentGuitar => 'Guitar';

  @override
  String get instrumentPiano => 'Piano';

  @override
  String get instrumentViolin => 'Violin';

  @override
  String get coursesTitle => 'Courses';

  @override
  String get coursesFilterAll => 'All';

  @override
  String get coursesEmpty => 'No courses found.';

  @override
  String get instructorsTitle => 'Instructors';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDescription =>
      'Pick a look for the app. System follows your device\'s light/dark setting.';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeVibrant => 'Vibrant';

  @override
  String get settingsThemeProfessional => 'Professional';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDescription =>
      'Choose your preferred language for the app interface.';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authOrContinueWith => 'or continue with';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonEmpty => 'Nothing here yet';

  @override
  String get purchaseBuy => 'Buy';

  @override
  String purchaseBuyForPrice(String price) {
    return 'Buy for $price';
  }

  @override
  String get purchaseOwned => 'Owned';

  @override
  String get purchaseRestore => 'Restore purchases';

  @override
  String get purchaseRestoring => 'Restoring…';

  @override
  String get purchaseRestored => 'Purchases restored.';

  @override
  String get lectureLocked =>
      'This lecture is locked. Purchase the course to unlock.';

  @override
  String get lectureFreePreview => 'Free preview';
}
