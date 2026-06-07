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
  String homePopularInstrument(String instrument) {
    return 'Popular $instrument Courses';
  }

  @override
  String get homeNoPopularYet => 'No popular courses yet.';

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

  @override
  String get songbooksTitle => 'Songbooks';

  @override
  String get songbooksSearchHint => 'Search for Songbooks';

  @override
  String get songbooksRecentlyViewed => 'Recently Viewed';

  @override
  String get songbooksBestsellers => 'Bestsellers';

  @override
  String get songbooksTrialTitle => 'Start 7-day free trial';

  @override
  String get songbooksTrialSubtitle => 'Tap to unlock your 7-day free trial';

  @override
  String get songbookGet => 'Get Songbook';

  @override
  String get songbookSave => 'Save';

  @override
  String get songbookSample => 'Sample';

  @override
  String get songbookIncludes => 'Includes';

  @override
  String get songbookViewAll => 'view all';

  @override
  String get songbookInstrument => 'INSTRUMENT';

  @override
  String get songbookTopics => 'TOPICS';

  @override
  String get songbookPublisher => 'PUBLISHER';

  @override
  String get songbookReviews => 'Reviews';

  @override
  String get songbookYouMightAlsoLike => 'You might also like';

  @override
  String get songbookNotFound => 'Songbook not found.';

  @override
  String get songbookNoReviewsYet => 'No reviews yet.';

  @override
  String get instructorTitle => 'Instructor';

  @override
  String get instructorTotalStudents => 'Total students';

  @override
  String get instructorReviews => 'Reviews';

  @override
  String get instructorAboutMe => 'About me';

  @override
  String instructorAboutName(String name) {
    return 'About $name';
  }

  @override
  String get instructorShowMore => 'Show more';

  @override
  String get instructorShowLess => 'Show less';

  @override
  String instructorMyCoursesCount(int count) {
    return 'My courses ($count)';
  }

  @override
  String get instructorNoCoursesYet => 'No published courses yet.';

  @override
  String get instructorNotFound => 'Instructor not found.';

  @override
  String get instructorLinkWebsite => 'Website';

  @override
  String get instructorLinkFacebook => 'Facebook';

  @override
  String get instructorLinkTwitter => 'X / Twitter';

  @override
  String get instructorLinkYouTube => 'YouTube';

  @override
  String get instructorLinkInstagram => 'Instagram';

  @override
  String get legalPrivacyPolicyTitle => 'Privacy Policy';

  @override
  String get legalTermsOfServiceTitle => 'Terms of Service';

  @override
  String get legalLoadFailed =>
      'Could not load this document. Please try again.';

  @override
  String get legalAgreementPrefix => 'By continuing you agree to our ';

  @override
  String get legalAgreementAnd => ' and ';

  @override
  String get legalAgreementPeriod => '.';

  @override
  String get legalAbout => 'About iLearnIt';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountWarningHeader =>
      'This will permanently delete your account';

  @override
  String get deleteAccountWarningBody =>
      'We will delete your profile, enrollments, reviews you authored, instructor application, and any files you uploaded. This cannot be undone.';

  @override
  String get deleteAccountSubscriptionNote =>
      'Subscriptions are managed by the App Store or Google Play and must be canceled separately. Deleting your account here does not cancel a paid subscription.';

  @override
  String get deleteAccountReauthIntro =>
      'Please confirm your password to continue.';

  @override
  String get deleteAccountReauthIntroSocial =>
      'Please re-sign in to confirm your identity.';

  @override
  String get deleteAccountReauthGoogle => 'Re-sign in with Google';

  @override
  String get deleteAccountReauthApple => 'Re-sign in with Apple';

  @override
  String get deleteAccountConfirmCheckbox =>
      'I understand that this action is permanent.';

  @override
  String get deleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get deleteAccountConfirmBody =>
      'Type DELETE to confirm. We cannot recover your data once this is done.';

  @override
  String get deleteAccountConfirmHint => 'DELETE';

  @override
  String get deleteAccountSubmit => 'Delete my account';

  @override
  String get deleteAccountInProgress => 'Deleting your account…';

  @override
  String get deleteAccountSuccess => 'Your account has been deleted.';

  @override
  String get deleteAccountFailed =>
      'We could not delete your account. Please try again or contact support.';

  @override
  String get continueLearningTitle => 'Continue learning';

  @override
  String courseProgressInProgress(int completed, int total) {
    return '$completed of $total lectures completed';
  }

  @override
  String get courseProgressFinished => 'Course completed';

  @override
  String get courseProgressResume => 'Resume';

  @override
  String get courseProgressUntitled => 'Untitled course';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingDone => 'Done';

  @override
  String get onboardingEnableNotifications => 'Enable notifications';

  @override
  String get onboardingInstrumentTitle => 'What do you play?';

  @override
  String get onboardingInstrumentSubtitle =>
      'Pick your primary instrument. You can change this anytime in Settings.';

  @override
  String get onboardingLevelTitle => 'Where are you in your journey?';

  @override
  String get onboardingLevelSubtitle =>
      'We\'ll tune your recommendations to match.';

  @override
  String get onboardingLevelBeginner => 'Beginner';

  @override
  String get onboardingLevelBeginnerBlurb =>
      'New to the instrument — start with the fundamentals.';

  @override
  String get onboardingLevelIntermediate => 'Intermediate';

  @override
  String get onboardingLevelIntermediateBlurb =>
      'Comfortable with basics — ready to explore technique and repertoire.';

  @override
  String get onboardingLevelAdvanced => 'Advanced';

  @override
  String get onboardingLevelAdvancedBlurb =>
      'Years of practice — focused on mastery and performance.';

  @override
  String get onboardingNotificationsTitle => 'Stay on track';

  @override
  String get onboardingNotificationsSubtitle =>
      'Enable notifications so iLearnIt can keep your practice habit going.';

  @override
  String get onboardingNotificationsReason1 =>
      'Get notified when your instructors release new lessons.';

  @override
  String get onboardingNotificationsReason2 =>
      'Hear about new courses in the instruments you love.';

  @override
  String get onboardingNotificationsReason3 =>
      'Get friendly daily reminders to practice.';

  @override
  String get onboardingNotificationsThanks => 'Thanks — you\'re all set.';

  @override
  String get onboardingNotificationsCanChange =>
      'No worries. You can enable notifications anytime from Settings.';

  @override
  String get notificationsInboxTitle => 'Notifications';

  @override
  String get notificationsEmpty =>
      'You\'re all caught up.\nNew alerts will appear here.';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsClearAll => 'Clear all';

  @override
  String get notificationsClearAllConfirmTitle => 'Clear all notifications?';

  @override
  String get notificationsClearAllConfirmBody =>
      'This will permanently remove every notification from your inbox.';

  @override
  String get notificationsPrefsTitle => 'Notifications';

  @override
  String get notificationsPrefsSubtitle =>
      'Choose what kinds of push notifications you want to receive. Changes apply across your devices.';

  @override
  String get notificationsPrefsSubtitleShort =>
      'Choose what alerts you receive';

  @override
  String get notificationsPrefsTopicAll => 'All updates';

  @override
  String get notificationsPrefsTopicAllBlurb =>
      'Get every announcement we send to the community.';

  @override
  String get notificationsPrefsTopicInstrumentBlurb =>
      'New courses, lessons, and tips for this instrument.';

  @override
  String get notificationsPrefsUpdateFailed =>
      'Could not update — please try again.';
}
