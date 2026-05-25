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

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

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
