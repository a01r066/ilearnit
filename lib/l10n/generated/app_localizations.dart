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

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please try again.'**
  String get errTimeout;

  /// No description provided for @errRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed.'**
  String get errRequestFailed;

  /// No description provided for @errRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled.'**
  String get errRequestCancelled;

  /// No description provided for @errBadCertificate.
  ///
  /// In en, this message translates to:
  /// **'Secure connection failed.'**
  String get errBadCertificate;

  /// No description provided for @errUnknownNetwork.
  ///
  /// In en, this message translates to:
  /// **'Unknown network error.'**
  String get errUnknownNetwork;

  /// No description provided for @errNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errNoInternet;

  /// No description provided for @authErrInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address is invalid.'**
  String get authErrInvalidEmail;

  /// No description provided for @authErrDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrDisabled;

  /// No description provided for @authErrInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get authErrInvalidCredentials;

  /// No description provided for @authErrEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for that email.'**
  String get authErrEmailInUse;

  /// No description provided for @authErrWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get authErrWeakPassword;

  /// No description provided for @authErrTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authErrTooManyRequests;

  /// No description provided for @authErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed.'**
  String get authErrGeneric;

  /// No description provided for @valEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get valEmailRequired;

  /// No description provided for @valEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get valEmailInvalid;

  /// No description provided for @valPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get valPasswordRequired;

  /// No description provided for @valPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters.'**
  String get valPasswordMin;

  /// No description provided for @valFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required.'**
  String valFieldRequired(String field);

  /// No description provided for @valThisField.
  ///
  /// In en, this message translates to:
  /// **'This field'**
  String get valThisField;

  /// No description provided for @valMismatch.
  ///
  /// In en, this message translates to:
  /// **'{field} does not match.'**
  String valMismatch(String field);

  /// No description provided for @valConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get valConfirmation;

  /// No description provided for @navMyLearning.
  ///
  /// In en, this message translates to:
  /// **'My learning'**
  String get navMyLearning;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found.'**
  String get routeNotFound;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String timeMinutesAgo(String n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String timeHoursAgo(String n);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String timeDaysAgo(String n);

  /// No description provided for @timeMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String timeMinutesShort(String n);

  /// No description provided for @timeHoursShort.
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String timeHoursShort(String n);

  /// No description provided for @timeDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String timeDaysShort(String n);

  /// No description provided for @authErrNoUser.
  ///
  /// In en, this message translates to:
  /// **'Sign-in did not complete. Please try again.'**
  String get authErrNoUser;

  /// No description provided for @authErrGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed.'**
  String get authErrGoogleFailed;

  /// No description provided for @authErrCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled.'**
  String get authErrCancelled;

  /// No description provided for @authErrAppleOnly.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple is only available on Apple devices.'**
  String get authErrAppleOnly;

  /// No description provided for @authErrAppleFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed.'**
  String get authErrAppleFailed;

  /// No description provided for @authErrNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You are not signed in.'**
  String get authErrNotSignedIn;

  /// No description provided for @authErrNoEmailReauth.
  ///
  /// In en, this message translates to:
  /// **'Your account has no email — try Google or Apple re-auth.'**
  String get authErrNoEmailReauth;

  /// No description provided for @authErrReauthFailed.
  ///
  /// In en, this message translates to:
  /// **'Re-authentication failed.'**
  String get authErrReauthFailed;

  /// No description provided for @authErrReauthCancelled.
  ///
  /// In en, this message translates to:
  /// **'Re-authentication cancelled.'**
  String get authErrReauthCancelled;

  /// No description provided for @authErrDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Account deletion failed.'**
  String get authErrDeleteFailed;

  /// No description provided for @authSkipGuestTooltip.
  ///
  /// In en, this message translates to:
  /// **'Skip — continue as guest'**
  String get authSkipGuestTooltip;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your lessons.'**
  String get authSignInSubtitle;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get authContinueAsGuest;

  /// No description provided for @authEnterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above first.'**
  String get authEnterEmailFirst;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent.'**
  String get authResetSent;

  /// No description provided for @authResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send reset email.'**
  String get authResetFailed;

  /// No description provided for @authAcceptTermsFirst.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms and Community Guidelines to continue.'**
  String get authAcceptTermsFirst;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up your instrument — guitar, piano or violin.'**
  String get authSignUpSubtitle;

  /// No description provided for @authDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get authDisplayName;

  /// No description provided for @authAgreePrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get authAgreePrefix;

  /// No description provided for @authAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get authAgreeTerms;

  /// No description provided for @authAgreeAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authAgreeAnd;

  /// No description provided for @authAgreeGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Community Guidelines'**
  String get authAgreeGuidelines;

  /// No description provided for @authAgreeSuffix.
  ///
  /// In en, this message translates to:
  /// **'. I will not post abusive, illegal, or objectionable content.'**
  String get authAgreeSuffix;

  /// No description provided for @profileGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get profileGuest;

  /// No description provided for @profilePlanActive.
  ///
  /// In en, this message translates to:
  /// **'Personal Plan · active'**
  String get profilePlanActive;

  /// No description provided for @profilePlanCta.
  ///
  /// In en, this message translates to:
  /// **'Unlock all courses with Personal Plan'**
  String get profilePlanCta;

  /// No description provided for @profileModerationQueue.
  ///
  /// In en, this message translates to:
  /// **'Moderation queue'**
  String get profileModerationQueue;

  /// No description provided for @profileModerationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review reported content'**
  String get profileModerationSubtitle;

  /// No description provided for @profileGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your progress'**
  String get profileGuestTitle;

  /// No description provided for @profileGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to unlock courses, save bookmarks, take notes, and pick up where you left off across devices.'**
  String get profileGuestBody;

  /// No description provided for @myLearningLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your library.'**
  String get myLearningLoadFailed;

  /// No description provided for @commonTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get commonTryAgainLater;

  /// No description provided for @myLearningEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing in your library yet.'**
  String get myLearningEmptyTitle;

  /// No description provided for @myLearningEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start any lecture and it will show up here so you can pick up where you left off.'**
  String get myLearningEmptyBody;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @progressCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get progressCompleted;

  /// No description provided for @progressPercentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String progressPercentComplete(String percent);

  /// No description provided for @purchaseContinueCourse.
  ///
  /// In en, this message translates to:
  /// **'Continue course'**
  String get purchaseContinueCourse;

  /// No description provided for @purchaseIncludedInPlan.
  ///
  /// In en, this message translates to:
  /// **'Included in your Personal Plan'**
  String get purchaseIncludedInPlan;

  /// No description provided for @purchaseSignInToUnlockCourse.
  ///
  /// In en, this message translates to:
  /// **'Sign in to unlock this course.'**
  String get purchaseSignInToUnlockCourse;

  /// No description provided for @purchaseSignInToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Sign in to unlock'**
  String get purchaseSignInToUnlock;

  /// No description provided for @purchaseUnlockFor.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {price}'**
  String purchaseUnlockFor(String price);

  /// No description provided for @purchaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'In-app purchases aren\'t available on this device.'**
  String get purchaseUnavailable;

  /// No description provided for @purchaseRestoreDone.
  ///
  /// In en, this message translates to:
  /// **'Restore complete. Your purchases will appear shortly.'**
  String get purchaseRestoreDone;

  /// No description provided for @purchaseRestoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync purchases made with your App Store or Google Play account.'**
  String get purchaseRestoreSubtitle;

  /// No description provided for @purchaseProductUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item is not available in the store right now.'**
  String get purchaseProductUnavailable;

  /// No description provided for @purchaseStoreDeclined.
  ///
  /// In en, this message translates to:
  /// **'The store could not start the purchase. Please try again.'**
  String get purchaseStoreDeclined;

  /// No description provided for @purchaseNotSupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'In-app purchases are not supported on this platform.'**
  String get purchaseNotSupportedPlatform;

  /// No description provided for @purchaseAlreadyOwned.
  ///
  /// In en, this message translates to:
  /// **'You already own this course.'**
  String get purchaseAlreadyOwned;

  /// No description provided for @purchaseCourseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This course is not available for purchase.'**
  String get purchaseCourseUnavailable;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase could not be completed. Please try again.'**
  String get purchaseFailed;

  /// No description provided for @subscriptionVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm your subscription. Please try again or use Restore purchases.'**
  String get subscriptionVerifyFailed;

  /// No description provided for @subscriptionOtherAccount.
  ///
  /// In en, this message translates to:
  /// **'This subscription is linked to another iLearnIt account.'**
  String get subscriptionOtherAccount;

  /// No description provided for @errLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load data. Please try again.'**
  String get errLoadFailed;

  /// No description provided for @courseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Course not found.'**
  String get courseNotFound;

  /// No description provided for @videoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video unavailable. Please try again.'**
  String get videoUnavailable;

  /// No description provided for @notesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your note.'**
  String get notesSaveFailed;

  /// No description provided for @qaPostQuestionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not post your question.'**
  String get qaPostQuestionFailed;

  /// No description provided for @qaPostReplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not post your reply.'**
  String get qaPostReplyFailed;

  /// No description provided for @durationHM.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}min'**
  String durationHM(String h, String m);

  /// No description provided for @durationM.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String durationM(String m);

  /// No description provided for @durationS.
  ///
  /// In en, this message translates to:
  /// **'{s}s'**
  String durationS(String s);

  /// No description provided for @courseTaughtBy.
  ///
  /// In en, this message translates to:
  /// **'Taught by '**
  String get courseTaughtBy;

  /// No description provided for @courseAbout.
  ///
  /// In en, this message translates to:
  /// **'About this course'**
  String get courseAbout;

  /// No description provided for @courseCurriculumSoon.
  ///
  /// In en, this message translates to:
  /// **'Curriculum coming soon.'**
  String get courseCurriculumSoon;

  /// No description provided for @courseCurriculum.
  ///
  /// In en, this message translates to:
  /// **'Curriculum'**
  String get courseCurriculum;

  /// No description provided for @courseCurriculumSummary.
  ///
  /// In en, this message translates to:
  /// **'{sections} sections • {lectures} lectures • {duration}'**
  String courseCurriculumSummary(
    String sections,
    String lectures,
    String duration,
  );

  /// No description provided for @courseLessons.
  ///
  /// In en, this message translates to:
  /// **'{count} lessons'**
  String courseLessons(String count);

  /// No description provided for @courseEnrolled.
  ///
  /// In en, this message translates to:
  /// **'{count} enrolled'**
  String courseEnrolled(String count);

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @coursesShowingFeatured.
  ///
  /// In en, this message translates to:
  /// **'Showing featured courses'**
  String get coursesShowingFeatured;

  /// No description provided for @coursesShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all courses'**
  String get coursesShowAll;

  /// No description provided for @instructorsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No instructors yet.'**
  String get instructorsEmpty;

  /// No description provided for @instructorStudents.
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String instructorStudents(String count);

  /// No description provided for @commonLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Pull down to try again.'**
  String get commonLoadFailed;

  /// No description provided for @courseByInstructor.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String courseByInstructor(String name);

  /// No description provided for @lectureNotFound.
  ///
  /// In en, this message translates to:
  /// **'Lecture not found.'**
  String get lectureNotFound;

  /// No description provided for @lectureMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get lectureMinimize;

  /// No description provided for @lectureVideoMissing.
  ///
  /// In en, this message translates to:
  /// **'Video unavailable.'**
  String get lectureVideoMissing;

  /// No description provided for @lectureAudioMissing.
  ///
  /// In en, this message translates to:
  /// **'Audio unavailable.'**
  String get lectureAudioMissing;

  /// No description provided for @lecturePurchaseToWatch.
  ///
  /// In en, this message translates to:
  /// **'Purchase this course to watch this lecture.'**
  String get lecturePurchaseToWatch;

  /// No description provided for @lectureEncoding.
  ///
  /// In en, this message translates to:
  /// **'Video still encoding — try again in a minute.'**
  String get lectureEncoding;

  /// No description provided for @lectureResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get lectureResources;

  /// No description provided for @lecturePurchaseToOpen.
  ///
  /// In en, this message translates to:
  /// **'Purchase this course to open this lecture.'**
  String get lecturePurchaseToOpen;

  /// No description provided for @lectureLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this lecture. Please try again.'**
  String get lectureLoadFailed;

  /// No description provided for @audioLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load audio.'**
  String get audioLoadFailed;

  /// No description provided for @playerBack10.
  ///
  /// In en, this message translates to:
  /// **'Back 10 seconds'**
  String get playerBack10;

  /// No description provided for @playerForward30.
  ///
  /// In en, this message translates to:
  /// **'Forward 30 seconds'**
  String get playerForward30;

  /// No description provided for @playerBack15.
  ///
  /// In en, this message translates to:
  /// **'Back 15 seconds'**
  String get playerBack15;

  /// No description provided for @playerForward15.
  ///
  /// In en, this message translates to:
  /// **'Forward 15 seconds'**
  String get playerForward15;

  /// No description provided for @playerPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// No description provided for @playerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @videoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load video.'**
  String get videoLoadFailed;

  /// No description provided for @levelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelAdvanced;

  /// No description provided for @lectureTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get lectureTypeVideo;

  /// No description provided for @lectureTypeAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get lectureTypeAudio;

  /// No description provided for @lectureTypePdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get lectureTypePdf;

  /// No description provided for @lectureTypeDoc.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get lectureTypeDoc;

  /// No description provided for @reasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reasonSpam;

  /// No description provided for @reasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get reasonHarassment;

  /// No description provided for @reasonHate.
  ///
  /// In en, this message translates to:
  /// **'Hate speech or symbols'**
  String get reasonHate;

  /// No description provided for @reasonSexual.
  ///
  /// In en, this message translates to:
  /// **'Nudity or sexual content'**
  String get reasonSexual;

  /// No description provided for @reasonViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence or dangerous content'**
  String get reasonViolence;

  /// No description provided for @reasonSelfHarm.
  ///
  /// In en, this message translates to:
  /// **'Self-harm or suicide'**
  String get reasonSelfHarm;

  /// No description provided for @reasonMisinformation.
  ///
  /// In en, this message translates to:
  /// **'False information'**
  String get reasonMisinformation;

  /// No description provided for @reasonIp.
  ///
  /// In en, this message translates to:
  /// **'Copyright / IP infringement'**
  String get reasonIp;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reasonOther;

  /// No description provided for @ugcReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get ugcReview;

  /// No description provided for @ugcQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get ugcQuestion;

  /// No description provided for @ugcAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get ugcAnswer;

  /// No description provided for @ugcNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get ugcNote;

  /// No description provided for @lectureAdditionalResources.
  ///
  /// In en, this message translates to:
  /// **'Additional resources'**
  String get lectureAdditionalResources;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @downloadPurchaseToDownload.
  ///
  /// In en, this message translates to:
  /// **'Purchase this course to download.'**
  String get downloadPurchaseToDownload;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed.'**
  String get downloadFailed;

  /// No description provided for @commonCancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get commonCancelDownload;

  /// No description provided for @lecturePreviewBadge.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get lecturePreviewBadge;

  /// No description provided for @lectureLockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lectureLockedLabel;

  /// No description provided for @sectionNumber.
  ///
  /// In en, this message translates to:
  /// **'Section {n}'**
  String sectionNumber(String n);

  /// No description provided for @sectionSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} lectures • {duration}'**
  String sectionSummary(String count, String duration);

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ratings & Reviews'**
  String get reviewsTitle;

  /// No description provided for @reviewsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load reviews.'**
  String get reviewsLoadFailed;

  /// No description provided for @reviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet — be the first.'**
  String get reviewsEmpty;

  /// No description provided for @reviewsCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 review'**
  String get reviewsCountOne;

  /// No description provided for @reviewsCountMany.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCountMany(String count);

  /// No description provided for @reviewSignInToWrite.
  ///
  /// In en, this message translates to:
  /// **'Sign in to write a review'**
  String get reviewSignInToWrite;

  /// No description provided for @reviewEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit your review'**
  String get reviewEdit;

  /// No description provided for @reviewWrite.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get reviewWrite;

  /// No description provided for @reviewSignInSnack.
  ///
  /// In en, this message translates to:
  /// **'Sign in to leave a review.'**
  String get reviewSignInSnack;

  /// No description provided for @reviewAccessGate.
  ///
  /// In en, this message translates to:
  /// **'Unlock this course (or subscribe) to leave a review.'**
  String get reviewAccessGate;

  /// No description provided for @reviewBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Your review (optional)'**
  String get reviewBodyLabel;

  /// No description provided for @reviewBodyHint.
  ///
  /// In en, this message translates to:
  /// **'What did you think of the course?'**
  String get reviewBodyHint;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @reviewDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your review?'**
  String get reviewDeleteTitle;

  /// No description provided for @reviewDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove your rating and review from this course.'**
  String get reviewDeleteBody;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @reviewDeleteMine.
  ///
  /// In en, this message translates to:
  /// **'Delete my review'**
  String get reviewDeleteMine;

  /// No description provided for @instructorCoursesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load courses.'**
  String get instructorCoursesLoadFailed;

  /// No description provided for @commonCouldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link.'**
  String get commonCouldNotOpenLink;

  /// No description provided for @playerForward10.
  ///
  /// In en, this message translates to:
  /// **'Forward 10 seconds'**
  String get playerForward10;

  /// No description provided for @eulaAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your acceptance. Please try again.'**
  String get eulaAcceptFailed;

  /// No description provided for @eulaUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Updated agreement'**
  String get eulaUpdatedTitle;

  /// No description provided for @eulaUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ve updated our Terms and Community Guidelines ({date}). Please review and accept to continue using iLearnIt.'**
  String eulaUpdatedBody(String date);

  /// No description provided for @eulaReadTerms.
  ///
  /// In en, this message translates to:
  /// **'Read terms'**
  String get eulaReadTerms;

  /// No description provided for @eulaReadGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Read guidelines'**
  String get eulaReadGuidelines;

  /// No description provided for @eulaAccept.
  ///
  /// In en, this message translates to:
  /// **'I accept'**
  String get eulaAccept;

  /// No description provided for @blockFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not block this user. Please try again.'**
  String get blockFailed;

  /// No description provided for @blockThisUser.
  ///
  /// In en, this message translates to:
  /// **'this user'**
  String get blockThisUser;

  /// No description provided for @blockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String blockTitle(String name);

  /// No description provided for @blockBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see any reviews, questions, answers, or notes from {name}. They won\'t be notified.'**
  String blockBody(String name);

  /// No description provided for @blockAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockAction;

  /// No description provided for @reportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks — our team will review this shortly.'**
  String get reportThanks;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit the report. Please try again.'**
  String get reportFailed;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {type}'**
  String reportTitle(String type);

  /// No description provided for @reportIntro.
  ///
  /// In en, this message translates to:
  /// **'Help us keep this community safe. Reports are reviewed within 24 hours.'**
  String get reportIntro;

  /// No description provided for @reportReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportReason;

  /// No description provided for @reportNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional notes (optional)'**
  String get reportNotes;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmit;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @ugcReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get ugcReport;

  /// No description provided for @ugcBlockName.
  ///
  /// In en, this message translates to:
  /// **'Block {name}'**
  String ugcBlockName(String name);

  /// No description provided for @ugcUnblockName.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}'**
  String ugcUnblockName(String name);

  /// No description provided for @ugcUserFallback.
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get ugcUserFallback;

  /// No description provided for @modTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get modTitle;

  /// No description provided for @modNoAccess.
  ///
  /// In en, this message translates to:
  /// **'You do not have access.'**
  String get modNoAccess;

  /// No description provided for @modOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String modOpenCount(String count);

  /// No description provided for @modNoOpenReports.
  ///
  /// In en, this message translates to:
  /// **'No open reports'**
  String get modNoOpenReports;

  /// No description provided for @modNothingToTriage.
  ///
  /// In en, this message translates to:
  /// **'Nothing to triage'**
  String get modNothingToTriage;

  /// No description provided for @modEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Reports tied to your courses will appear here.'**
  String get modEmptyHint;

  /// No description provided for @modActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Please try again.'**
  String get modActionFailed;

  /// No description provided for @modHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get modHide;

  /// No description provided for @modDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get modDismiss;

  /// No description provided for @notesSignInSnack.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save notes.'**
  String get notesSignInSnack;

  /// No description provided for @qaSignInToReply.
  ///
  /// In en, this message translates to:
  /// **'Sign in to reply'**
  String get qaSignInToReply;

  /// No description provided for @qaSignInToJoin.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join the conversation.'**
  String get qaSignInToJoin;

  /// No description provided for @qaSignInToAsk.
  ///
  /// In en, this message translates to:
  /// **'Sign in to ask a question.'**
  String get qaSignInToAsk;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @filterInstrument.
  ///
  /// In en, this message translates to:
  /// **'Instrument'**
  String get filterInstrument;

  /// No description provided for @filterLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get filterLevel;

  /// No description provided for @filterMinRating.
  ///
  /// In en, this message translates to:
  /// **'Minimum rating'**
  String get filterMinRating;

  /// No description provided for @filterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get filterAny;

  /// No description provided for @filterMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get filterMaxPrice;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @learningPathCourseLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this course.'**
  String get learningPathCourseLoadFailed;

  /// No description provided for @legalCommunityGuidelinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Community Guidelines'**
  String get legalCommunityGuidelinesTitle;

  /// No description provided for @songbookLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this songbook.'**
  String get songbookLoadFailed;

  /// No description provided for @songbookSectionFailed.
  ///
  /// In en, this message translates to:
  /// **'{section} — failed to load.'**
  String songbookSectionFailed(String section);

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'iLearnIt notifications'**
  String get notifChannelName;

  /// No description provided for @notifChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Course updates, application status, and announcements.'**
  String get notifChannelDesc;

  /// No description provided for @a11yShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get a11yShowPassword;

  /// No description provided for @a11yHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get a11yHidePassword;

  /// No description provided for @a11yRateStars.
  ///
  /// In en, this message translates to:
  /// **'Rate {n} out of 5 stars'**
  String a11yRateStars(String n);

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version of iLearnIt is no longer supported. Please update to keep learning.'**
  String get updateRequiredBody;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'A new version of iLearnIt is available.'**
  String get updateAvailableBody;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get updateLater;

  /// No description provided for @songbookPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing your songbook…'**
  String get songbookPreparing;

  /// No description provided for @songbookNoViewer.
  ///
  /// In en, this message translates to:
  /// **'No app on this device can open PDF files.'**
  String get songbookNoViewer;

  /// No description provided for @songbookLocked.
  ///
  /// In en, this message translates to:
  /// **'Get this songbook (or the Personal Plan) to open it.'**
  String get songbookLocked;

  /// No description provided for @songbookOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the songbook. Please try again.'**
  String get songbookOpenFailed;

  /// No description provided for @songbookSamplePage.
  ///
  /// In en, this message translates to:
  /// **'Sample · {page}/{total}'**
  String songbookSamplePage(String page, String total);

  /// No description provided for @songbookOpen.
  ///
  /// In en, this message translates to:
  /// **'Open songbook'**
  String get songbookOpen;

  /// No description provided for @songbookSignInToGet.
  ///
  /// In en, this message translates to:
  /// **'Sign in to get this songbook.'**
  String get songbookSignInToGet;

  /// No description provided for @songbookGetForPrice.
  ///
  /// In en, this message translates to:
  /// **'Get Songbook · {price}'**
  String songbookGetForPrice(String price);

  /// No description provided for @songbookOtherAccount.
  ///
  /// In en, this message translates to:
  /// **'This purchase is linked to another iLearnIt account.'**
  String get songbookOtherAccount;
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
