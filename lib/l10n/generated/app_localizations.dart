import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// The application title shown in MaterialApp.title and the launcher label.
  ///
  /// In en, this message translates to:
  /// **'iLearnIt'**
  String get appTitle;

  /// Native name of the English language as shown in the language picker.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Native name of the Vietnamese language as shown in the language picker.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get navCourses;

  /// No description provided for @navInstructors.
  ///
  /// In en, this message translates to:
  /// **'Instructors'**
  String get navInstructors;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @homeWelcomeAnon.
  ///
  /// In en, this message translates to:
  /// **'Welcome to iLearnIt'**
  String get homeWelcomeAnon;

  /// Greeting shown when the user is signed in. {name} is the user's first name.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name} 👋'**
  String homeWelcomeNamed(String name);

  /// No description provided for @homeWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What will you practice today?'**
  String get homeWelcomeSubtitle;

  /// No description provided for @homeBrowseByInstrument.
  ///
  /// In en, this message translates to:
  /// **'Browse by instrument'**
  String get homeBrowseByInstrument;

  /// No description provided for @homeFeaturedCourses.
  ///
  /// In en, this message translates to:
  /// **'Featured courses'**
  String get homeFeaturedCourses;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeNoFeaturedYet.
  ///
  /// In en, this message translates to:
  /// **'No featured courses yet.'**
  String get homeNoFeaturedYet;

  /// Section heading on the Home tab for popular courses of a single instrument.
  ///
  /// In en, this message translates to:
  /// **'Popular {instrument} Courses'**
  String homePopularInstrument(String instrument);

  /// No description provided for @homeNoPopularYet.
  ///
  /// In en, this message translates to:
  /// **'No popular courses yet.'**
  String get homeNoPopularYet;

  /// No description provided for @instrumentGuitar.
  ///
  /// In en, this message translates to:
  /// **'Guitar'**
  String get instrumentGuitar;

  /// No description provided for @instrumentPiano.
  ///
  /// In en, this message translates to:
  /// **'Piano'**
  String get instrumentPiano;

  /// No description provided for @instrumentViolin.
  ///
  /// In en, this message translates to:
  /// **'Violin'**
  String get instrumentViolin;

  /// No description provided for @coursesTitle.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get coursesTitle;

  /// No description provided for @coursesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get coursesFilterAll;

  /// No description provided for @coursesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No courses found.'**
  String get coursesEmpty;

  /// No description provided for @instructorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Instructors'**
  String get instructorsTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Pick a look for the app. System follows your device\'s light/dark setting.'**
  String get settingsThemeDescription;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeVibrant.
  ///
  /// In en, this message translates to:
  /// **'Vibrant'**
  String get settingsThemeVibrant;

  /// No description provided for @settingsThemeProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get settingsThemeProfessional;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language for the app interface.'**
  String get settingsLanguageDescription;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get authOrContinueWith;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @commonEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get commonEmpty;

  /// No description provided for @purchaseBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get purchaseBuy;

  /// Buy button on a course detail page, including the formatted price.
  ///
  /// In en, this message translates to:
  /// **'Buy for {price}'**
  String purchaseBuyForPrice(String price);

  /// No description provided for @purchaseOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get purchaseOwned;

  /// No description provided for @purchaseRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get purchaseRestore;

  /// No description provided for @purchaseRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get purchaseRestoring;

  /// No description provided for @purchaseRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get purchaseRestored;

  /// No description provided for @lectureLocked.
  ///
  /// In en, this message translates to:
  /// **'This lecture is locked. Purchase the course to unlock.'**
  String get lectureLocked;

  /// No description provided for @lectureFreePreview.
  ///
  /// In en, this message translates to:
  /// **'Free preview'**
  String get lectureFreePreview;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionActivePlans.
  ///
  /// In en, this message translates to:
  /// **'Active plans'**
  String get subscriptionActivePlans;

  /// No description provided for @subscriptionNoneActive.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any active subscriptions'**
  String get subscriptionNoneActive;

  /// No description provided for @subscriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'Subscription plans available'**
  String get subscriptionAvailable;

  /// No description provided for @personalPlan.
  ///
  /// In en, this message translates to:
  /// **'Personal plan'**
  String get personalPlan;

  /// No description provided for @personalPlanIntro.
  ///
  /// In en, this message translates to:
  /// **'New opportunities await. Sign up for Personal Plan to get all this and more:'**
  String get personalPlanIntro;

  /// No description provided for @personalPlanFeature1.
  ///
  /// In en, this message translates to:
  /// **'Access to all classical music courses'**
  String get personalPlanFeature1;

  /// No description provided for @personalPlanFeature2.
  ///
  /// In en, this message translates to:
  /// **'Courses in guitar, piano, and violin'**
  String get personalPlanFeature2;

  /// No description provided for @personalPlanFeature3.
  ///
  /// In en, this message translates to:
  /// **'Sheet music, exercises, and Q&A'**
  String get personalPlanFeature3;

  /// No description provided for @personalPlanLearnMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'About the Personal Plan'**
  String get personalPlanLearnMoreTitle;

  /// No description provided for @personalPlanLearnMoreBody.
  ///
  /// In en, this message translates to:
  /// **'The Personal Plan gives you unlimited access to every course on iLearnIt for a single monthly or yearly price. Switch instruments any time, study at your own pace, and cancel whenever.'**
  String get personalPlanLearnMoreBody;

  /// No description provided for @startSubscription.
  ///
  /// In en, this message translates to:
  /// **'Start subscription'**
  String get startSubscription;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @startingAtPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Starting at {price} per month. Cancel any time.'**
  String startingAtPerMonth(String price);

  /// No description provided for @subscriptionRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String subscriptionRenewsOn(String date);

  /// No description provided for @subscriptionCancelsOn.
  ///
  /// In en, this message translates to:
  /// **'Cancels on {date}'**
  String subscriptionCancelsOn(String date);

  /// No description provided for @planBilledYearly.
  ///
  /// In en, this message translates to:
  /// **'Billed yearly'**
  String get planBilledYearly;

  /// No description provided for @planBilledMonthly.
  ///
  /// In en, this message translates to:
  /// **'Billed monthly'**
  String get planBilledMonthly;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @yearlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Yearly access'**
  String get yearlyAccess;

  /// No description provided for @monthlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Monthly access'**
  String get monthlyAccess;

  /// No description provided for @billedYearly.
  ///
  /// In en, this message translates to:
  /// **'billed yearly'**
  String get billedYearly;

  /// No description provided for @billedMonthly.
  ///
  /// In en, this message translates to:
  /// **'billed monthly'**
  String get billedMonthly;

  /// No description provided for @saveAmount.
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String saveAmount(String amount);

  /// No description provided for @checkoutFeature1.
  ///
  /// In en, this message translates to:
  /// **'Access to every iLearnIt course, anytime'**
  String get checkoutFeature1;

  /// No description provided for @checkoutFeature2.
  ///
  /// In en, this message translates to:
  /// **'Hands-on lessons across guitar, piano, and violin'**
  String get checkoutFeature2;

  /// No description provided for @checkoutFeature3.
  ///
  /// In en, this message translates to:
  /// **'Course recommendations based on your goals'**
  String get checkoutFeature3;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @totalDueToday.
  ///
  /// In en, this message translates to:
  /// **'Total due today:'**
  String get totalDueToday;

  /// No description provided for @checkoutBillingDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime by visiting the Subscriptions page in your account. Your subscription begins at checkout and a charge of {total} (plus applicable taxes) will apply immediately and automatically each billing period until you cancel. By placing this order, you agree to our Terms of Use and authorize this recurring charge. No refunds unless required by law.'**
  String checkoutBillingDisclaimer(String total);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search courses'**
  String get searchHint;

  /// No description provided for @searchCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get searchCancel;

  /// No description provided for @searchRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecentSearches;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClear;

  /// No description provided for @searchEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Search for courses, instructors, or topics.'**
  String get searchEmptyState;

  /// No description provided for @searchNoMatchesForQuery.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\"'**
  String searchNoMatchesForQuery(String query);

  /// No description provided for @searchTryDifferent.
  ///
  /// In en, this message translates to:
  /// **'Try a different term or adjust your filters.'**
  String get searchTryDifferent;

  /// No description provided for @badgeBestseller.
  ///
  /// In en, this message translates to:
  /// **'Bestseller'**
  String get badgeBestseller;

  /// No description provided for @badgeHighestRated.
  ///
  /// In en, this message translates to:
  /// **'Highest rated'**
  String get badgeHighestRated;

  /// No description provided for @badgeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get badgeNew;

  /// No description provided for @songbooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Songbooks'**
  String get songbooksTitle;

  /// No description provided for @songbooksSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for Songbooks'**
  String get songbooksSearchHint;

  /// No description provided for @songbooksRecentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'Recently Viewed'**
  String get songbooksRecentlyViewed;

  /// No description provided for @songbooksBestsellers.
  ///
  /// In en, this message translates to:
  /// **'Bestsellers'**
  String get songbooksBestsellers;

  /// No description provided for @songbooksTrialTitle.
  ///
  /// In en, this message translates to:
  /// **'Start 7-day free trial'**
  String get songbooksTrialTitle;

  /// No description provided for @songbooksTrialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to unlock your 7-day free trial'**
  String get songbooksTrialSubtitle;

  /// No description provided for @songbookGet.
  ///
  /// In en, this message translates to:
  /// **'Get Songbook'**
  String get songbookGet;

  /// No description provided for @songbookSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get songbookSave;

  /// No description provided for @songbookSample.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get songbookSample;

  /// No description provided for @songbookIncludes.
  ///
  /// In en, this message translates to:
  /// **'Includes'**
  String get songbookIncludes;

  /// No description provided for @songbookViewAll.
  ///
  /// In en, this message translates to:
  /// **'view all'**
  String get songbookViewAll;

  /// No description provided for @songbookInstrument.
  ///
  /// In en, this message translates to:
  /// **'INSTRUMENT'**
  String get songbookInstrument;

  /// No description provided for @songbookTopics.
  ///
  /// In en, this message translates to:
  /// **'TOPICS'**
  String get songbookTopics;

  /// No description provided for @songbookPublisher.
  ///
  /// In en, this message translates to:
  /// **'PUBLISHER'**
  String get songbookPublisher;

  /// No description provided for @songbookReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get songbookReviews;

  /// No description provided for @songbookYouMightAlsoLike.
  ///
  /// In en, this message translates to:
  /// **'You might also like'**
  String get songbookYouMightAlsoLike;

  /// No description provided for @songbookNotFound.
  ///
  /// In en, this message translates to:
  /// **'Songbook not found.'**
  String get songbookNotFound;

  /// No description provided for @songbookNoReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get songbookNoReviewsYet;

  /// No description provided for @instructorTitle.
  ///
  /// In en, this message translates to:
  /// **'Instructor'**
  String get instructorTitle;

  /// No description provided for @instructorTotalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total students'**
  String get instructorTotalStudents;

  /// No description provided for @instructorReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get instructorReviews;

  /// No description provided for @instructorAboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get instructorAboutMe;

  /// No description provided for @instructorAboutName.
  ///
  /// In en, this message translates to:
  /// **'About {name}'**
  String instructorAboutName(String name);

  /// No description provided for @instructorShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get instructorShowMore;

  /// No description provided for @instructorShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get instructorShowLess;

  /// No description provided for @instructorMyCoursesCount.
  ///
  /// In en, this message translates to:
  /// **'My courses ({count})'**
  String instructorMyCoursesCount(int count);

  /// No description provided for @instructorNoCoursesYet.
  ///
  /// In en, this message translates to:
  /// **'No published courses yet.'**
  String get instructorNoCoursesYet;

  /// No description provided for @instructorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Instructor not found.'**
  String get instructorNotFound;

  /// No description provided for @instructorLinkWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get instructorLinkWebsite;

  /// No description provided for @instructorLinkFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get instructorLinkFacebook;

  /// No description provided for @instructorLinkTwitter.
  ///
  /// In en, this message translates to:
  /// **'X / Twitter'**
  String get instructorLinkTwitter;

  /// No description provided for @instructorLinkYouTube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get instructorLinkYouTube;

  /// No description provided for @instructorLinkInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instructorLinkInstagram;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
