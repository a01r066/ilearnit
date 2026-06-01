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

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get subscriptionActivePlans => 'Active plans';

  @override
  String get subscriptionNoneActive =>
      'You don\'t have any active subscriptions';

  @override
  String get subscriptionAvailable => 'Subscription plans available';

  @override
  String get personalPlan => 'Personal plan';

  @override
  String get personalPlanIntro =>
      'New opportunities await. Sign up for Personal Plan to get all this and more:';

  @override
  String get personalPlanFeature1 => 'Access to all classical music courses';

  @override
  String get personalPlanFeature2 => 'Courses in guitar, piano, and violin';

  @override
  String get personalPlanFeature3 => 'Sheet music, exercises, and Q&A';

  @override
  String get personalPlanLearnMoreTitle => 'About the Personal Plan';

  @override
  String get personalPlanLearnMoreBody =>
      'The Personal Plan gives you unlimited access to every course on iLearnIt for a single monthly or yearly price. Switch instruments any time, study at your own pace, and cancel whenever.';

  @override
  String get startSubscription => 'Start subscription';

  @override
  String get learnMore => 'Learn more';

  @override
  String startingAtPerMonth(String price) {
    return 'Starting at $price per month. Cancel any time.';
  }

  @override
  String subscriptionRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String subscriptionCancelsOn(String date) {
    return 'Cancels on $date';
  }

  @override
  String get planBilledYearly => 'Billed yearly';

  @override
  String get planBilledMonthly => 'Billed monthly';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get yearlyAccess => 'Yearly access';

  @override
  String get monthlyAccess => 'Monthly access';

  @override
  String get billedYearly => 'billed yearly';

  @override
  String get billedMonthly => 'billed monthly';

  @override
  String saveAmount(String amount) {
    return 'Save $amount';
  }

  @override
  String get checkoutFeature1 => 'Access to every iLearnIt course, anytime';

  @override
  String get checkoutFeature2 =>
      'Hands-on lessons across guitar, piano, and violin';

  @override
  String get checkoutFeature3 => 'Course recommendations based on your goals';

  @override
  String get summary => 'Summary';

  @override
  String get totalDueToday => 'Total due today:';

  @override
  String checkoutBillingDisclaimer(String total) {
    return 'Cancel anytime by visiting the Subscriptions page in your account. Your subscription begins at checkout and a charge of $total (plus applicable taxes) will apply immediately and automatically each billing period until you cancel. By placing this order, you agree to our Terms of Use and authorize this recurring charge. No refunds unless required by law.';
  }

  @override
  String get searchHint => 'Search courses';

  @override
  String get searchCancel => 'Cancel';

  @override
  String get searchRecentSearches => 'Recent searches';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchEmptyState => 'Search for courses, instructors, or topics.';

  @override
  String searchNoMatchesForQuery(String query) {
    return 'No matches for \"$query\"';
  }

  @override
  String get searchTryDifferent =>
      'Try a different term or adjust your filters.';

  @override
  String get badgeBestseller => 'Bestseller';

  @override
  String get badgeHighestRated => 'Highest rated';

  @override
  String get badgeNew => 'New';
}
