/// Centralised event-name table for Firebase Analytics.
///
/// Keep every new event here so the BI team can review the funnel
/// shape before it goes live. Some events have reserved meaning in
/// Firebase (e.g. `screen_view`, `purchase`, `login`, `sign_up`) —
/// those are sent through the typed helpers on [AnalyticsService]
/// rather than via [logEvent] so we get auto-population of related
/// dashboards.
///
/// Naming convention:
///   • snake_case
///   • verb + noun (`course_viewed`, `lecture_started`)
///   • prefix `app_` for app-level milestones not tied to content
class AnalyticsEvents {
  const AnalyticsEvents._();

  // ----- Onboarding ------------------------------------------------------
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingComplete = 'onboarding_complete';

  // ----- Courses ---------------------------------------------------------
  static const String courseViewed = 'course_viewed';
  static const String coursePreviewPlayed = 'course_preview_played';
  static const String courseEnrolled = 'course_enrolled';
  static const String courseCompleted = 'course_completed';

  // ----- Lectures --------------------------------------------------------
  static const String lectureStarted = 'lecture_started';
  static const String lectureCompleted = 'lecture_completed';
  static const String lectureResumed = 'lecture_resumed';

  // ----- Search ----------------------------------------------------------
  static const String searchPerformed = 'search';
  static const String searchResultOpened = 'search_result_opened';

  // ----- Wishlist / saved ------------------------------------------------
  static const String wishlistAdded = 'wishlist_added';
  static const String wishlistRemoved = 'wishlist_removed';

  // ----- Subscription ----------------------------------------------------
  static const String subscriptionViewed = 'subscription_viewed';
  static const String subscriptionStarted = 'subscription_started';
  static const String subscriptionCanceled = 'subscription_canceled';
  static const String subscriptionRestored = 'subscription_restored';

  // ----- Q&A / Notes -----------------------------------------------------
  static const String questionPosted = 'question_posted';
  static const String replyPosted = 'reply_posted';
  static const String noteSaved = 'note_saved';

  // ----- Downloads -------------------------------------------------------
  static const String downloadStarted = 'download_started';
  static const String downloadCompleted = 'download_completed';

  // ----- App-level milestones -------------------------------------------
  static const String appStart = 'app_start';
  static const String appRatingShown = 'app_rating_shown';
  static const String appRatingResponded = 'app_rating_responded';
  static const String themeChanged = 'theme_changed';
  static const String localeChanged = 'locale_changed';
}

/// Parameter keys used across multiple events. Keep them stable —
/// changing a key after the fact loses historical join coverage.
class AnalyticsParams {
  const AnalyticsParams._();

  static const String courseId = 'course_id';
  static const String courseTitle = 'course_title';
  static const String courseCategory = 'course_category';
  static const String courseLevel = 'course_level';
  static const String instructorId = 'instructor_id';
  static const String instructorName = 'instructor_name';
  static const String priceTier = 'price_tier';
  static const String productId = 'product_id';
  static const String valueUsd = 'value_usd';
  static const String currency = 'currency';

  static const String lectureId = 'lecture_id';
  static const String lectureTitle = 'lecture_title';
  static const String lectureType = 'lecture_type';
  static const String durationSec = 'duration_sec';
  static const String positionSec = 'position_sec';

  static const String query = 'search_term';
  static const String resultCount = 'result_count';

  static const String planId = 'plan_id';
  static const String billingPeriodMonths = 'billing_period_months';

  static const String questionId = 'question_id';
  static const String replyId = 'reply_id';
  static const String noteId = 'note_id';

  static const String method = 'method';
  static const String source = 'source';
  static const String themeMode = 'theme_mode';
  static const String localeCode = 'locale_code';
  static const String rating = 'rating';
}

/// Custom user properties — appear as filterable dimensions in
/// Analytics + as keys on Crashlytics. Keep this list short because
/// each becomes a column in the BigQuery export.
class AnalyticsUserProperties {
  const AnalyticsUserProperties._();

  static const String role = 'role'; // student / instructor / admin
  static const String skillLevel = 'skill_level';
  static const String primaryInstrument = 'primary_instrument';
  static const String subscriptionPlan = 'subscription_plan';
  static const String onboardingComplete = 'onboarding_complete';
}
