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

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsEmpty =>
      'You haven\'t downloaded any lectures yet.\nTap the download button on any lecture to save it for offline viewing.';

  @override
  String get downloadsClearAll => 'Remove all downloads';

  @override
  String get downloadsClearAllConfirmTitle => 'Remove all downloads?';

  @override
  String get downloadsClearAllConfirmBody =>
      'This will delete every downloaded lecture from this device. You can re-download anytime.';

  @override
  String downloadsUsed(String size) {
    return '$size used';
  }

  @override
  String get downloadCta => 'Download';

  @override
  String get downloadInProgress => 'Downloading';

  @override
  String get downloadResume => 'Resume download';

  @override
  String get downloadCompleted => 'Downloaded';

  @override
  String get downloadDelete => 'Delete download';

  @override
  String get coursesLoadingMore => 'Loading more courses…';

  @override
  String get coursesEndOfList => 'You\'ve reached the end.';

  @override
  String get wishlistTitle => 'Saved courses';

  @override
  String get wishlistSubtitleEmpty => 'Bookmark a course to come back to it';

  @override
  String wishlistSubtitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count courses saved',
      one: '1 course saved',
    );
    return '$_temp0';
  }

  @override
  String get wishlistEmptyTitle => 'No saved courses yet';

  @override
  String get wishlistEmptyBody =>
      'Tap the heart on any course card to save it for later. You\'ll be notified when the price drops.';

  @override
  String get wishlistBrowseCta => 'Browse courses';

  @override
  String get wishlistAddTooltip => 'Save for later';

  @override
  String get wishlistRemoveTooltip => 'Remove from saved';

  @override
  String get wishlistError => 'Could not update — please try again.';

  @override
  String get wishlistSignInPrompt => 'Sign in to save courses.';

  @override
  String get wishlistUntitled => 'Untitled course';

  @override
  String get learningPathsTitle => 'Learning paths';

  @override
  String get learningPathEyebrow => 'LEARNING PATH';

  @override
  String learningPathCourseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count courses',
      one: '1 course',
    );
    return '$_temp0';
  }

  @override
  String learningPathTotalHours(String hours) {
    return '$hours hr';
  }

  @override
  String get learningPathCurriculumHeader => 'What you\'ll cover';

  @override
  String get learningPathCourseMissing => '(Course no longer available)';

  @override
  String get learningPathNotFound => 'Learning path not found.';

  @override
  String get practiceTitle => 'Practice tools';

  @override
  String get practiceTileSubtitle => 'Metronome + tuner';

  @override
  String get practiceMetronome => 'Metronome';

  @override
  String get practiceTuner => 'Tuner';

  @override
  String get metronomeTimeSignature => 'Time signature';

  @override
  String get metronomeTapTempo => 'Tap tempo';

  @override
  String get metronomeTapHere => 'Tap here in rhythm';

  @override
  String get metronomeStart => 'Start';

  @override
  String get metronomeStop => 'Stop';

  @override
  String get tunerStart => 'Start listening';

  @override
  String get tunerStop => 'Stop';

  @override
  String get tunerListening => 'Listening…';

  @override
  String get tunerHint =>
      'Play a single note close to the mic. Best in a quiet room.';

  @override
  String get tunerHintSilent => 'Play a note to begin.';

  @override
  String get tunerHintInTune => 'In tune.';

  @override
  String get tunerHintFlat => 'Tune up.';

  @override
  String get tunerHintSharp => 'Tune down.';

  @override
  String get tunerPermissionDenied =>
      'Microphone access is required. Re-enable it in Settings → iLearnIt → Microphone.';

  @override
  String get qaSectionHeader => 'Questions';

  @override
  String get qaAsk => 'Ask a question';

  @override
  String get qaAskTitle => 'Ask a question';

  @override
  String get qaQuestionLabel => 'Your question';

  @override
  String get qaQuestionHint =>
      'What\'s on your mind? Be specific so the instructor can help.';

  @override
  String get qaPostQuestion => 'Post question';

  @override
  String get qaEmptyAnonymous =>
      'Sign in to ask the first question on this lecture.';

  @override
  String get qaEmptyAuthenticated => 'No questions yet — be the first to ask.';

  @override
  String qaSeeAll(int count) {
    return 'See all $count';
  }

  @override
  String qaReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '1 reply',
      zero: 'No replies',
    );
    return '$_temp0';
  }

  @override
  String get qaThreadTitle => 'Question';

  @override
  String get qaThreadMissing => 'This question is no longer available.';

  @override
  String get qaReplies => 'Replies';

  @override
  String get qaNoRepliesYet => 'No replies yet. Start the conversation.';

  @override
  String get qaAnonymous => 'Student';

  @override
  String get qaReplyHint => 'Write a reply…';

  @override
  String get qaSend => 'Send';

  @override
  String get qaVerifiedInstructor => 'Verified instructor';

  @override
  String get notesSectionHeader => 'My notes';

  @override
  String get notesAddCta => 'Add note';

  @override
  String get notesAddTitle => 'New note';

  @override
  String get notesEditTitle => 'Edit note';

  @override
  String get notesBodyHint => 'What did you notice? Jot it down.';

  @override
  String get notesNoTimestamp => 'No timestamp';

  @override
  String get notesClearTimestamp => 'Clear';

  @override
  String get notesSaveNew => 'Save note';

  @override
  String get notesSaveChanges => 'Save changes';

  @override
  String get notesEmptyAnonymous =>
      'Sign in to start taking notes on this lecture.';

  @override
  String get notesEmptyAuthenticated =>
      'No notes yet — tap \"Add note\" to capture a thought.';

  @override
  String notesMoreInProfile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more in My notes',
      one: '1 more in My notes',
    );
    return '$_temp0';
  }

  @override
  String get notesEdit => 'Edit';

  @override
  String get notesDelete => 'Delete';

  @override
  String get notesCancel => 'Cancel';

  @override
  String get notesDeleted => 'Note deleted';

  @override
  String get notesDeleteConfirmTitle => 'Delete this note?';

  @override
  String get notesDeleteConfirmBody => 'This cannot be undone.';

  @override
  String get notesPageTitle => 'My notes';

  @override
  String get notesProfileSubtitle =>
      'Your timestamped thoughts across every lecture.';

  @override
  String get notesEmptyPageTitle => 'Nothing here yet';

  @override
  String get notesEmptyPageBody =>
      'Open any lecture and tap \"Add note\" to start your library.';

  @override
  String get settingsPrivacySection => 'Privacy';

  @override
  String get settingsAnalyticsTitle => 'Send anonymous usage data';

  @override
  String get settingsAnalyticsSubtitle =>
      'Helps us spot crashes and improve the app. Toggle off to stop all collection.';

  @override
  String get errTimeout => 'Connection timed out. Please try again.';

  @override
  String get errRequestFailed => 'Request failed.';

  @override
  String get errRequestCancelled => 'Request cancelled.';

  @override
  String get errBadCertificate => 'Secure connection failed.';

  @override
  String get errUnknownNetwork => 'Unknown network error.';

  @override
  String get errNoInternet => 'No internet connection.';

  @override
  String get authErrInvalidEmail => 'That email address is invalid.';

  @override
  String get authErrDisabled => 'This account has been disabled.';

  @override
  String get authErrInvalidCredentials => 'Invalid email or password.';

  @override
  String get authErrEmailInUse => 'An account already exists for that email.';

  @override
  String get authErrWeakPassword => 'Password is too weak.';

  @override
  String get authErrTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get authErrGeneric => 'Authentication failed.';

  @override
  String get valEmailRequired => 'Email is required.';

  @override
  String get valEmailInvalid => 'Enter a valid email.';

  @override
  String get valPasswordRequired => 'Password is required.';

  @override
  String get valPasswordMin => 'At least 8 characters.';

  @override
  String valFieldRequired(String field) {
    return '$field is required.';
  }

  @override
  String get valThisField => 'This field';

  @override
  String valMismatch(String field) {
    return '$field does not match.';
  }

  @override
  String get valConfirmation => 'Confirmation';

  @override
  String get navMyLearning => 'My learning';

  @override
  String get routeNotFound => 'Page not found.';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(String n) {
    return '${n}m ago';
  }

  @override
  String timeHoursAgo(String n) {
    return '${n}h ago';
  }

  @override
  String timeDaysAgo(String n) {
    return '${n}d ago';
  }

  @override
  String timeMinutesShort(String n) {
    return '${n}m';
  }

  @override
  String timeHoursShort(String n) {
    return '${n}h';
  }

  @override
  String timeDaysShort(String n) {
    return '${n}d';
  }

  @override
  String get authErrNoUser => 'Sign-in did not complete. Please try again.';

  @override
  String get authErrGoogleFailed => 'Google sign-in failed.';

  @override
  String get authErrCancelled => 'Sign-in cancelled.';

  @override
  String get authErrAppleOnly =>
      'Sign in with Apple is only available on Apple devices.';

  @override
  String get authErrAppleFailed => 'Apple sign-in failed.';

  @override
  String get authErrNotSignedIn => 'You are not signed in.';

  @override
  String get authErrNoEmailReauth =>
      'Your account has no email — try Google or Apple re-auth.';

  @override
  String get authErrReauthFailed => 'Re-authentication failed.';

  @override
  String get authErrReauthCancelled => 'Re-authentication cancelled.';

  @override
  String get authErrDeleteFailed => 'Account deletion failed.';

  @override
  String get authSkipGuestTooltip => 'Skip — continue as guest';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authSignInSubtitle => 'Sign in to continue your lessons.';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get authEnterEmailFirst => 'Enter your email above first.';

  @override
  String get authResetSent => 'Password reset email sent.';

  @override
  String get authResetFailed => 'Could not send reset email.';

  @override
  String get authAcceptTermsFirst =>
      'Please accept the Terms and Community Guidelines to continue.';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignUpSubtitle =>
      'Pick up your instrument — guitar, piano or violin.';

  @override
  String get authDisplayName => 'Display name';

  @override
  String get authAgreePrefix => 'I agree to the ';

  @override
  String get authAgreeTerms => 'Terms';

  @override
  String get authAgreeAnd => ' and ';

  @override
  String get authAgreeGuidelines => 'Community Guidelines';

  @override
  String get authAgreeSuffix =>
      '. I will not post abusive, illegal, or objectionable content.';

  @override
  String get profileGuest => 'Guest';

  @override
  String get profilePlanActive => 'Personal Plan · active';

  @override
  String get profilePlanCta => 'Unlock all courses with Personal Plan';

  @override
  String get profileModerationQueue => 'Moderation queue';

  @override
  String get profileModerationSubtitle => 'Review reported content';

  @override
  String get profileGuestTitle => 'Save your progress';

  @override
  String get profileGuestBody =>
      'Sign in to unlock courses, save bookmarks, take notes, and pick up where you left off across devices.';

  @override
  String get myLearningLoadFailed => 'Could not load your library.';

  @override
  String get commonTryAgainLater =>
      'Please check your connection and try again.';

  @override
  String get myLearningEmptyTitle => 'Nothing in your library yet.';

  @override
  String get myLearningEmptyBody =>
      'Start any lecture and it will show up here so you can pick up where you left off.';

  @override
  String get commonSearch => 'Search';

  @override
  String get progressCompleted => 'Completed';

  @override
  String progressPercentComplete(String percent) {
    return '$percent% complete';
  }

  @override
  String get purchaseContinueCourse => 'Continue course';

  @override
  String get purchaseIncludedInPlan => 'Included in your Personal Plan';

  @override
  String get purchaseSignInToUnlockCourse => 'Sign in to unlock this course.';

  @override
  String get purchaseSignInToUnlock => 'Sign in to unlock';

  @override
  String purchaseUnlockFor(String price) {
    return 'Unlock for $price';
  }

  @override
  String get purchaseUnavailable =>
      'In-app purchases aren\'t available on this device.';

  @override
  String get purchaseRestoreDone =>
      'Restore complete. Your purchases will appear shortly.';

  @override
  String get purchaseRestoreSubtitle =>
      'Sync purchases made with your App Store or Google Play account.';

  @override
  String get purchaseProductUnavailable =>
      'This item is not available in the store right now.';

  @override
  String get purchaseStoreDeclined =>
      'The store could not start the purchase. Please try again.';

  @override
  String get purchaseNotSupportedPlatform =>
      'In-app purchases are not supported on this platform.';

  @override
  String get purchaseAlreadyOwned => 'You already own this course.';

  @override
  String get purchaseCourseUnavailable =>
      'This course is not available for purchase.';

  @override
  String get purchaseFailed =>
      'Purchase could not be completed. Please try again.';

  @override
  String get subscriptionVerifyFailed =>
      'We could not confirm your subscription. Please try again or use Restore purchases.';

  @override
  String get subscriptionOtherAccount =>
      'This subscription is linked to another iLearnIt account.';

  @override
  String get errLoadFailed => 'Could not load data. Please try again.';

  @override
  String get courseNotFound => 'Course not found.';

  @override
  String get videoUnavailable => 'Video unavailable. Please try again.';

  @override
  String get notesSaveFailed => 'Could not save your note.';

  @override
  String get qaPostQuestionFailed => 'Could not post your question.';

  @override
  String get qaPostReplyFailed => 'Could not post your reply.';

  @override
  String durationHM(String h, String m) {
    return '${h}h ${m}min';
  }

  @override
  String durationM(String m) {
    return '$m min';
  }

  @override
  String durationS(String s) {
    return '${s}s';
  }

  @override
  String get courseTaughtBy => 'Taught by ';

  @override
  String get courseAbout => 'About this course';

  @override
  String get courseCurriculumSoon => 'Curriculum coming soon.';

  @override
  String get courseCurriculum => 'Curriculum';

  @override
  String courseCurriculumSummary(
    String sections,
    String lectures,
    String duration,
  ) {
    return '$sections sections • $lectures lectures • $duration';
  }

  @override
  String courseLessons(String count) {
    return '$count lessons';
  }

  @override
  String courseEnrolled(String count) {
    return '$count enrolled';
  }

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get coursesShowingFeatured => 'Showing featured courses';

  @override
  String get coursesShowAll => 'Show all courses';

  @override
  String get instructorsEmpty => 'No instructors yet.';

  @override
  String instructorStudents(String count) {
    return '$count students';
  }

  @override
  String get commonLoadFailed =>
      'Something went wrong. Pull down to try again.';

  @override
  String courseByInstructor(String name) {
    return 'by $name';
  }

  @override
  String get lectureNotFound => 'Lecture not found.';

  @override
  String get lectureMinimize => 'Minimize';

  @override
  String get lectureVideoMissing => 'Video unavailable.';

  @override
  String get lectureAudioMissing => 'Audio unavailable.';

  @override
  String get lecturePurchaseToWatch =>
      'Purchase this course to watch this lecture.';

  @override
  String get lectureEncoding => 'Video still encoding — try again in a minute.';

  @override
  String get lectureResources => 'Resources';

  @override
  String get lecturePurchaseToOpen =>
      'Purchase this course to open this lecture.';

  @override
  String get lectureLoadFailed =>
      'Could not load this lecture. Please try again.';

  @override
  String get audioLoadFailed => 'Could not load audio.';

  @override
  String get playerBack10 => 'Back 10 seconds';

  @override
  String get playerForward30 => 'Forward 30 seconds';

  @override
  String get playerBack15 => 'Back 15 seconds';

  @override
  String get playerForward15 => 'Forward 15 seconds';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get commonClose => 'Close';

  @override
  String get videoLoadFailed => 'Could not load video.';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get lectureTypeVideo => 'Video';

  @override
  String get lectureTypeAudio => 'Audio';

  @override
  String get lectureTypePdf => 'PDF';

  @override
  String get lectureTypeDoc => 'Document';

  @override
  String get reasonSpam => 'Spam or scam';

  @override
  String get reasonHarassment => 'Harassment or bullying';

  @override
  String get reasonHate => 'Hate speech or symbols';

  @override
  String get reasonSexual => 'Nudity or sexual content';

  @override
  String get reasonViolence => 'Violence or dangerous content';

  @override
  String get reasonSelfHarm => 'Self-harm or suicide';

  @override
  String get reasonMisinformation => 'False information';

  @override
  String get reasonIp => 'Copyright / IP infringement';

  @override
  String get reasonOther => 'Something else';

  @override
  String get ugcReview => 'Review';

  @override
  String get ugcQuestion => 'Question';

  @override
  String get ugcAnswer => 'Answer';

  @override
  String get ugcNote => 'Note';

  @override
  String get lectureAdditionalResources => 'Additional resources';

  @override
  String get commonOpen => 'Open';

  @override
  String get downloadPurchaseToDownload => 'Purchase this course to download.';

  @override
  String get downloadFailed => 'Download failed.';

  @override
  String get commonCancelDownload => 'Cancel download';

  @override
  String get lecturePreviewBadge => 'Preview';

  @override
  String get lectureLockedLabel => 'Locked';

  @override
  String sectionNumber(String n) {
    return 'Section $n';
  }

  @override
  String sectionSummary(String count, String duration) {
    return '$count lectures • $duration';
  }

  @override
  String get reviewsTitle => 'Ratings & Reviews';

  @override
  String get reviewsLoadFailed => 'Could not load reviews.';

  @override
  String get reviewsEmpty => 'No reviews yet — be the first.';

  @override
  String get reviewsCountOne => '1 review';

  @override
  String reviewsCountMany(String count) {
    return '$count reviews';
  }

  @override
  String get reviewSignInToWrite => 'Sign in to write a review';

  @override
  String get reviewEdit => 'Edit your review';

  @override
  String get reviewWrite => 'Write a review';

  @override
  String get reviewSignInSnack => 'Sign in to leave a review.';

  @override
  String get reviewAccessGate =>
      'Unlock this course (or subscribe) to leave a review.';

  @override
  String get reviewBodyLabel => 'Your review (optional)';

  @override
  String get reviewBodyHint => 'What did you think of the course?';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get reviewDeleteTitle => 'Delete your review?';

  @override
  String get reviewDeleteBody =>
      'This will remove your rating and review from this course.';

  @override
  String get commonDelete => 'Delete';

  @override
  String get reviewDeleteMine => 'Delete my review';

  @override
  String get instructorCoursesLoadFailed => 'Could not load courses.';

  @override
  String get commonCouldNotOpenLink => 'Could not open link.';

  @override
  String get playerForward10 => 'Forward 10 seconds';

  @override
  String get eulaAcceptFailed =>
      'Could not save your acceptance. Please try again.';

  @override
  String get eulaUpdatedTitle => 'Updated agreement';

  @override
  String eulaUpdatedBody(String date) {
    return 'We\'ve updated our Terms and Community Guidelines ($date). Please review and accept to continue using iLearnIt.';
  }

  @override
  String get eulaReadTerms => 'Read terms';

  @override
  String get eulaReadGuidelines => 'Read guidelines';

  @override
  String get eulaAccept => 'I accept';

  @override
  String get blockFailed => 'Could not block this user. Please try again.';

  @override
  String get blockThisUser => 'this user';

  @override
  String blockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String blockBody(String name) {
    return 'You won\'t see any reviews, questions, answers, or notes from $name. They won\'t be notified.';
  }

  @override
  String get blockAction => 'Block';

  @override
  String get reportThanks => 'Thanks — our team will review this shortly.';

  @override
  String get reportFailed => 'Could not submit the report. Please try again.';

  @override
  String reportTitle(String type) {
    return 'Report $type';
  }

  @override
  String get reportIntro =>
      'Help us keep this community safe. Reports are reviewed within 24 hours.';

  @override
  String get reportReason => 'Reason';

  @override
  String get reportNotes => 'Additional notes (optional)';

  @override
  String get reportSubmit => 'Submit report';

  @override
  String get commonMore => 'More';

  @override
  String get ugcReport => 'Report';

  @override
  String ugcBlockName(String name) {
    return 'Block $name';
  }

  @override
  String ugcUnblockName(String name) {
    return 'Unblock $name';
  }

  @override
  String get ugcUserFallback => 'user';

  @override
  String get modTitle => 'Moderation';

  @override
  String get modNoAccess => 'You do not have access.';

  @override
  String modOpenCount(String count) {
    return '$count open';
  }

  @override
  String get modNoOpenReports => 'No open reports';

  @override
  String get modNothingToTriage => 'Nothing to triage';

  @override
  String get modEmptyHint => 'Reports tied to your courses will appear here.';

  @override
  String get modActionFailed => 'Action failed. Please try again.';

  @override
  String get modHide => 'Hide';

  @override
  String get modDismiss => 'Dismiss';

  @override
  String get notesSignInSnack => 'Sign in to save notes.';

  @override
  String get qaSignInToReply => 'Sign in to reply';

  @override
  String get qaSignInToJoin => 'Sign in to join the conversation.';

  @override
  String get qaSignInToAsk => 'Sign in to ask a question.';

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterInstrument => 'Instrument';

  @override
  String get filterLevel => 'Level';

  @override
  String get filterMinRating => 'Minimum rating';

  @override
  String get filterAny => 'Any';

  @override
  String get filterMaxPrice => 'Max price';

  @override
  String get filterApply => 'Apply';

  @override
  String get learningPathCourseLoadFailed => 'Could not load this course.';

  @override
  String get legalCommunityGuidelinesTitle => 'Community Guidelines';

  @override
  String get songbookLoadFailed => 'Could not load this songbook.';

  @override
  String songbookSectionFailed(String section) {
    return '$section — failed to load.';
  }

  @override
  String get notifChannelName => 'iLearnIt notifications';

  @override
  String get notifChannelDesc =>
      'Course updates, application status, and announcements.';

  @override
  String get a11yShowPassword => 'Show password';

  @override
  String get a11yHidePassword => 'Hide password';

  @override
  String a11yRateStars(String n) {
    return 'Rate $n out of 5 stars';
  }

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody =>
      'This version of iLearnIt is no longer supported. Please update to keep learning.';

  @override
  String get updateNow => 'Update';

  @override
  String get updateAvailableBody => 'A new version of iLearnIt is available.';

  @override
  String get updateLater => 'Not now';

  @override
  String get songbookPreparing => 'Preparing your songbook…';

  @override
  String get songbookNoViewer => 'No app on this device can open PDF files.';

  @override
  String get songbookLocked =>
      'Get this songbook (or the Personal Plan) to open it.';

  @override
  String get songbookOpenFailed =>
      'Could not open the songbook. Please try again.';

  @override
  String songbookSamplePage(String page, String total) {
    return 'Sample · $page/$total';
  }

  @override
  String get songbookOpen => 'Open songbook';

  @override
  String get songbookSignInToGet => 'Sign in to get this songbook.';

  @override
  String songbookGetForPrice(String price) {
    return 'Get Songbook · $price';
  }

  @override
  String get songbookOtherAccount =>
      'This purchase is linked to another iLearnIt account.';
}
