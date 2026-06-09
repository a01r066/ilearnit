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

  /// No description provided for @legalPrivacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyPolicyTitle;

  /// No description provided for @legalTermsOfServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalTermsOfServiceTitle;

  /// No description provided for @legalLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this document. Please try again.'**
  String get legalLoadFailed;

  /// No description provided for @legalAgreementPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our '**
  String get legalAgreementPrefix;

  /// No description provided for @legalAgreementAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get legalAgreementAnd;

  /// No description provided for @legalAgreementPeriod.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get legalAgreementPeriod;

  /// No description provided for @legalAbout.
  ///
  /// In en, this message translates to:
  /// **'About iLearnIt'**
  String get legalAbout;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarningHeader.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account'**
  String get deleteAccountWarningHeader;

  /// No description provided for @deleteAccountWarningBody.
  ///
  /// In en, this message translates to:
  /// **'We will delete your profile, enrollments, reviews you authored, instructor application, and any files you uploaded. This cannot be undone.'**
  String get deleteAccountWarningBody;

  /// No description provided for @deleteAccountSubscriptionNote.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are managed by the App Store or Google Play and must be canceled separately. Deleting your account here does not cancel a paid subscription.'**
  String get deleteAccountSubscriptionNote;

  /// No description provided for @deleteAccountReauthIntro.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password to continue.'**
  String get deleteAccountReauthIntro;

  /// No description provided for @deleteAccountReauthIntroSocial.
  ///
  /// In en, this message translates to:
  /// **'Please re-sign in to confirm your identity.'**
  String get deleteAccountReauthIntroSocial;

  /// No description provided for @deleteAccountReauthGoogle.
  ///
  /// In en, this message translates to:
  /// **'Re-sign in with Google'**
  String get deleteAccountReauthGoogle;

  /// No description provided for @deleteAccountReauthApple.
  ///
  /// In en, this message translates to:
  /// **'Re-sign in with Apple'**
  String get deleteAccountReauthApple;

  /// No description provided for @deleteAccountConfirmCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I understand that this action is permanent.'**
  String get deleteAccountConfirmCheckbox;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm. We cannot recover your data once this is done.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAccountConfirmHint;

  /// No description provided for @deleteAccountSubmit.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountSubmit;

  /// No description provided for @deleteAccountInProgress.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account…'**
  String get deleteAccountInProgress;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get deleteAccountSuccess;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not delete your account. Please try again or contact support.'**
  String get deleteAccountFailed;

  /// Section header on the Home tab for in-progress courses.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get continueLearningTitle;

  /// Progress copy on the course detail card.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} lectures completed'**
  String courseProgressInProgress(int completed, int total);

  /// No description provided for @courseProgressFinished.
  ///
  /// In en, this message translates to:
  /// **'Course completed'**
  String get courseProgressFinished;

  /// No description provided for @courseProgressResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get courseProgressResume;

  /// No description provided for @courseProgressUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled course'**
  String get courseProgressUntitled;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get onboardingDone;

  /// No description provided for @onboardingEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get onboardingEnableNotifications;

  /// No description provided for @onboardingInstrumentTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you play?'**
  String get onboardingInstrumentTitle;

  /// No description provided for @onboardingInstrumentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your primary instrument. You can change this anytime in Settings.'**
  String get onboardingInstrumentSubtitle;

  /// No description provided for @onboardingLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you in your journey?'**
  String get onboardingLevelTitle;

  /// No description provided for @onboardingLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll tune your recommendations to match.'**
  String get onboardingLevelSubtitle;

  /// No description provided for @onboardingLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get onboardingLevelBeginner;

  /// No description provided for @onboardingLevelBeginnerBlurb.
  ///
  /// In en, this message translates to:
  /// **'New to the instrument — start with the fundamentals.'**
  String get onboardingLevelBeginnerBlurb;

  /// No description provided for @onboardingLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get onboardingLevelIntermediate;

  /// No description provided for @onboardingLevelIntermediateBlurb.
  ///
  /// In en, this message translates to:
  /// **'Comfortable with basics — ready to explore technique and repertoire.'**
  String get onboardingLevelIntermediateBlurb;

  /// No description provided for @onboardingLevelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get onboardingLevelAdvanced;

  /// No description provided for @onboardingLevelAdvancedBlurb.
  ///
  /// In en, this message translates to:
  /// **'Years of practice — focused on mastery and performance.'**
  String get onboardingLevelAdvancedBlurb;

  /// No description provided for @onboardingNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on track'**
  String get onboardingNotificationsTitle;

  /// No description provided for @onboardingNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications so iLearnIt can keep your practice habit going.'**
  String get onboardingNotificationsSubtitle;

  /// No description provided for @onboardingNotificationsReason1.
  ///
  /// In en, this message translates to:
  /// **'Get notified when your instructors release new lessons.'**
  String get onboardingNotificationsReason1;

  /// No description provided for @onboardingNotificationsReason2.
  ///
  /// In en, this message translates to:
  /// **'Hear about new courses in the instruments you love.'**
  String get onboardingNotificationsReason2;

  /// No description provided for @onboardingNotificationsReason3.
  ///
  /// In en, this message translates to:
  /// **'Get friendly daily reminders to practice.'**
  String get onboardingNotificationsReason3;

  /// No description provided for @onboardingNotificationsThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks — you\'re all set.'**
  String get onboardingNotificationsThanks;

  /// No description provided for @onboardingNotificationsCanChange.
  ///
  /// In en, this message translates to:
  /// **'No worries. You can enable notifications anytime from Settings.'**
  String get onboardingNotificationsCanChange;

  /// No description provided for @notificationsInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsInboxTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.\nNew alerts will appear here.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get notificationsClearAll;

  /// No description provided for @notificationsClearAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications?'**
  String get notificationsClearAllConfirmTitle;

  /// No description provided for @notificationsClearAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove every notification from your inbox.'**
  String get notificationsClearAllConfirmBody;

  /// No description provided for @notificationsPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsPrefsTitle;

  /// No description provided for @notificationsPrefsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what kinds of push notifications you want to receive. Changes apply across your devices.'**
  String get notificationsPrefsSubtitle;

  /// No description provided for @notificationsPrefsSubtitleShort.
  ///
  /// In en, this message translates to:
  /// **'Choose what alerts you receive'**
  String get notificationsPrefsSubtitleShort;

  /// No description provided for @notificationsPrefsTopicAll.
  ///
  /// In en, this message translates to:
  /// **'All updates'**
  String get notificationsPrefsTopicAll;

  /// No description provided for @notificationsPrefsTopicAllBlurb.
  ///
  /// In en, this message translates to:
  /// **'Get every announcement we send to the community.'**
  String get notificationsPrefsTopicAllBlurb;

  /// No description provided for @notificationsPrefsTopicInstrumentBlurb.
  ///
  /// In en, this message translates to:
  /// **'New courses, lessons, and tips for this instrument.'**
  String get notificationsPrefsTopicInstrumentBlurb;

  /// No description provided for @notificationsPrefsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update — please try again.'**
  String get notificationsPrefsUpdateFailed;

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @downloadsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t downloaded any lectures yet.\nTap the download button on any lecture to save it for offline viewing.'**
  String get downloadsEmpty;

  /// No description provided for @downloadsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Remove all downloads'**
  String get downloadsClearAll;

  /// No description provided for @downloadsClearAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all downloads?'**
  String get downloadsClearAllConfirmTitle;

  /// No description provided for @downloadsClearAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete every downloaded lecture from this device. You can re-download anytime.'**
  String get downloadsClearAllConfirmBody;

  /// Storage usage indicator on the Downloads page header.
  ///
  /// In en, this message translates to:
  /// **'{size} used'**
  String downloadsUsed(String size);

  /// No description provided for @downloadCta.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadCta;

  /// No description provided for @downloadInProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadInProgress;

  /// No description provided for @downloadResume.
  ///
  /// In en, this message translates to:
  /// **'Resume download'**
  String get downloadResume;

  /// No description provided for @downloadCompleted.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloadCompleted;

  /// No description provided for @downloadDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete download'**
  String get downloadDelete;

  /// No description provided for @coursesLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more courses…'**
  String get coursesLoadingMore;

  /// No description provided for @coursesEndOfList.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the end.'**
  String get coursesEndOfList;

  /// No description provided for @wishlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved courses'**
  String get wishlistTitle;

  /// No description provided for @wishlistSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Bookmark a course to come back to it'**
  String get wishlistSubtitleEmpty;

  /// Pluralized subtitle on the Profile → Saved tile.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 course saved} other{{count} courses saved}}'**
  String wishlistSubtitleCount(int count);

  /// No description provided for @wishlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved courses yet'**
  String get wishlistEmptyTitle;

  /// No description provided for @wishlistEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any course card to save it for later. You\'ll be notified when the price drops.'**
  String get wishlistEmptyBody;

  /// No description provided for @wishlistBrowseCta.
  ///
  /// In en, this message translates to:
  /// **'Browse courses'**
  String get wishlistBrowseCta;

  /// No description provided for @wishlistAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save for later'**
  String get wishlistAddTooltip;

  /// No description provided for @wishlistRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get wishlistRemoveTooltip;

  /// No description provided for @wishlistError.
  ///
  /// In en, this message translates to:
  /// **'Could not update — please try again.'**
  String get wishlistError;

  /// No description provided for @wishlistSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save courses.'**
  String get wishlistSignInPrompt;

  /// No description provided for @wishlistUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled course'**
  String get wishlistUntitled;

  /// No description provided for @learningPathsTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning paths'**
  String get learningPathsTitle;

  /// No description provided for @learningPathEyebrow.
  ///
  /// In en, this message translates to:
  /// **'LEARNING PATH'**
  String get learningPathEyebrow;

  /// No description provided for @learningPathCourseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 course} other{{count} courses}}'**
  String learningPathCourseCount(int count);

  /// No description provided for @learningPathTotalHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr'**
  String learningPathTotalHours(String hours);

  /// No description provided for @learningPathCurriculumHeader.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll cover'**
  String get learningPathCurriculumHeader;

  /// No description provided for @learningPathCourseMissing.
  ///
  /// In en, this message translates to:
  /// **'(Course no longer available)'**
  String get learningPathCourseMissing;

  /// No description provided for @learningPathNotFound.
  ///
  /// In en, this message translates to:
  /// **'Learning path not found.'**
  String get learningPathNotFound;

  /// No description provided for @practiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice tools'**
  String get practiceTitle;

  /// No description provided for @practiceTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Metronome + tuner'**
  String get practiceTileSubtitle;

  /// No description provided for @practiceMetronome.
  ///
  /// In en, this message translates to:
  /// **'Metronome'**
  String get practiceMetronome;

  /// No description provided for @practiceTuner.
  ///
  /// In en, this message translates to:
  /// **'Tuner'**
  String get practiceTuner;

  /// No description provided for @metronomeTimeSignature.
  ///
  /// In en, this message translates to:
  /// **'Time signature'**
  String get metronomeTimeSignature;

  /// No description provided for @metronomeTapTempo.
  ///
  /// In en, this message translates to:
  /// **'Tap tempo'**
  String get metronomeTapTempo;

  /// No description provided for @metronomeTapHere.
  ///
  /// In en, this message translates to:
  /// **'Tap here in rhythm'**
  String get metronomeTapHere;

  /// No description provided for @metronomeStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get metronomeStart;

  /// No description provided for @metronomeStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get metronomeStop;

  /// No description provided for @tunerStart.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get tunerStart;

  /// No description provided for @tunerStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get tunerStop;

  /// No description provided for @tunerListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get tunerListening;

  /// No description provided for @tunerHint.
  ///
  /// In en, this message translates to:
  /// **'Play a single note close to the mic. Best in a quiet room.'**
  String get tunerHint;

  /// No description provided for @tunerHintSilent.
  ///
  /// In en, this message translates to:
  /// **'Play a note to begin.'**
  String get tunerHintSilent;

  /// No description provided for @tunerHintInTune.
  ///
  /// In en, this message translates to:
  /// **'In tune.'**
  String get tunerHintInTune;

  /// No description provided for @tunerHintFlat.
  ///
  /// In en, this message translates to:
  /// **'Tune up.'**
  String get tunerHintFlat;

  /// No description provided for @tunerHintSharp.
  ///
  /// In en, this message translates to:
  /// **'Tune down.'**
  String get tunerHintSharp;

  /// No description provided for @tunerPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is required. Re-enable it in Settings → iLearnIt → Microphone.'**
  String get tunerPermissionDenied;

  /// No description provided for @qaSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get qaSectionHeader;

  /// No description provided for @qaAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get qaAsk;

  /// No description provided for @qaAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get qaAskTitle;

  /// No description provided for @qaQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Your question'**
  String get qaQuestionLabel;

  /// No description provided for @qaQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind? Be specific so the instructor can help.'**
  String get qaQuestionHint;

  /// No description provided for @qaPostQuestion.
  ///
  /// In en, this message translates to:
  /// **'Post question'**
  String get qaPostQuestion;

  /// No description provided for @qaEmptyAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Sign in to ask the first question on this lecture.'**
  String get qaEmptyAnonymous;

  /// No description provided for @qaEmptyAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'No questions yet — be the first to ask.'**
  String get qaEmptyAuthenticated;

  /// No description provided for @qaSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all {count}'**
  String qaSeeAll(int count);

  /// No description provided for @qaReplyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No replies} =1{1 reply} other{{count} replies}}'**
  String qaReplyCount(int count);

  /// No description provided for @qaThreadTitle.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get qaThreadTitle;

  /// No description provided for @qaThreadMissing.
  ///
  /// In en, this message translates to:
  /// **'This question is no longer available.'**
  String get qaThreadMissing;

  /// No description provided for @qaReplies.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get qaReplies;

  /// No description provided for @qaNoRepliesYet.
  ///
  /// In en, this message translates to:
  /// **'No replies yet. Start the conversation.'**
  String get qaNoRepliesYet;

  /// No description provided for @qaAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get qaAnonymous;

  /// No description provided for @qaReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply…'**
  String get qaReplyHint;

  /// No description provided for @qaSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get qaSend;

  /// No description provided for @qaVerifiedInstructor.
  ///
  /// In en, this message translates to:
  /// **'Verified instructor'**
  String get qaVerifiedInstructor;

  /// No description provided for @notesSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'My notes'**
  String get notesSectionHeader;

  /// No description provided for @notesAddCta.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get notesAddCta;

  /// No description provided for @notesAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get notesAddTitle;

  /// No description provided for @notesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get notesEditTitle;

  /// No description provided for @notesBodyHint.
  ///
  /// In en, this message translates to:
  /// **'What did you notice? Jot it down.'**
  String get notesBodyHint;

  /// No description provided for @notesNoTimestamp.
  ///
  /// In en, this message translates to:
  /// **'No timestamp'**
  String get notesNoTimestamp;

  /// No description provided for @notesClearTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get notesClearTimestamp;

  /// No description provided for @notesSaveNew.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get notesSaveNew;

  /// No description provided for @notesSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get notesSaveChanges;

  /// No description provided for @notesEmptyAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Sign in to start taking notes on this lecture.'**
  String get notesEmptyAnonymous;

  /// No description provided for @notesEmptyAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'No notes yet — tap \"Add note\" to capture a thought.'**
  String get notesEmptyAuthenticated;

  /// No description provided for @notesMoreInProfile.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more in My notes} other{{count} more in My notes}}'**
  String notesMoreInProfile(int count);

  /// No description provided for @notesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get notesEdit;

  /// No description provided for @notesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get notesDelete;

  /// No description provided for @notesCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get notesCancel;

  /// No description provided for @notesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get notesDeleted;

  /// No description provided for @notesDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get notesDeleteConfirmTitle;

  /// No description provided for @notesDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get notesDeleteConfirmBody;

  /// No description provided for @notesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'My notes'**
  String get notesPageTitle;

  /// No description provided for @notesProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your timestamped thoughts across every lecture.'**
  String get notesProfileSubtitle;

  /// No description provided for @notesEmptyPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get notesEmptyPageTitle;

  /// No description provided for @notesEmptyPageBody.
  ///
  /// In en, this message translates to:
  /// **'Open any lecture and tap \"Add note\" to start your library.'**
  String get notesEmptyPageBody;

  /// No description provided for @settingsPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacySection;

  /// No description provided for @settingsAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Send anonymous usage data'**
  String get settingsAnalyticsTitle;

  /// No description provided for @settingsAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps us spot crashes and improve the app. Toggle off to stop all collection.'**
  String get settingsAnalyticsSubtitle;
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
