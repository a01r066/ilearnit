import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_events.dart';

/// Typed wrapper around [FirebaseAnalytics]. Callers go through these
/// helpers rather than `logEvent` directly so we get:
///   • Compile-time check on event + parameter names.
///   • One place to add a debug-mode logging interceptor.
///   • One place to update the BI taxonomy.
///
/// The class also re-exports the underlying [FirebaseAnalytics]
/// instance so the GoRouter observer can subscribe to it.
class AnalyticsService {
  AnalyticsService(this.analytics);

  final FirebaseAnalytics analytics;

  // ----- Collection toggle ----------------------------------------------

  Future<void> setEnabled(bool enabled) async {
    await analytics.setAnalyticsCollectionEnabled(enabled);
  }

  // ----- User identity --------------------------------------------------

  Future<void> setUserId(String? uid) async {
    await analytics.setUserId(id: uid);
  }

  Future<void> setUserProperty(String name, String? value) async {
    await analytics.setUserProperty(name: name, value: value);
  }

  Future<void> setRole(String? role) =>
      setUserProperty(AnalyticsUserProperties.role, role);

  Future<void> setSkillLevel(String? skillLevel) =>
      setUserProperty(AnalyticsUserProperties.skillLevel, skillLevel);

  Future<void> setPrimaryInstrument(String? instrument) =>
      setUserProperty(AnalyticsUserProperties.primaryInstrument, instrument);

  Future<void> setSubscriptionPlan(String? planId) =>
      setUserProperty(AnalyticsUserProperties.subscriptionPlan, planId);

  Future<void> setOnboardingComplete(bool done) =>
      setUserProperty(
        AnalyticsUserProperties.onboardingComplete,
        done.toString(),
      );

  // ----- Reserved (auto-populated dashboards) ---------------------------

  Future<void> logSignUp({required String method}) =>
      analytics.logSignUp(signUpMethod: method);

  Future<void> logLogin({required String method}) =>
      analytics.logLogin(loginMethod: method);

  /// Course purchase — feeds Firebase's "Purchase" dashboard.
  Future<void> logCoursePurchase({
    required String courseId,
    required String courseTitle,
    required String priceTier,
    required String productId,
    required double valueUsd,
    String currency = 'USD',
  }) async {
    await analytics.logPurchase(
      currency: currency,
      value: valueUsd,
      transactionId: '$courseId-${DateTime.now().millisecondsSinceEpoch}',
      items: [
        AnalyticsEventItem(
          itemId: courseId,
          itemName: courseTitle,
          itemCategory: 'course',
          itemVariant: priceTier,
          price: valueUsd,
          quantity: 1,
        ),
      ],
      parameters: {
        AnalyticsParams.productId: productId,
        AnalyticsParams.priceTier: priceTier,
      },
    );
  }

  Future<void> logSearch({
    required String query,
    int? resultCount,
  }) =>
      analytics.logSearch(
        searchTerm: query,
        parameters: {
          if (resultCount != null) AnalyticsParams.resultCount: resultCount,
        },
      );

  Future<void> logShare({
    required String contentType,
    required String itemId,
    String? method,
  }) =>
      analytics.logShare(
        contentType: contentType,
        itemId: itemId,
        method: method ?? 'unknown',
      );

  // ----- Custom events --------------------------------------------------

  Future<void> _event(String name, [Map<String, Object>? params]) =>
      analytics.logEvent(name: name, parameters: params);

  Future<void> logCourseViewed({
    required String courseId,
    String? title,
    String? category,
    String? instructorId,
  }) =>
      _event(AnalyticsEvents.courseViewed, {
        AnalyticsParams.courseId: courseId,
        if (title != null) AnalyticsParams.courseTitle: title,
        if (category != null) AnalyticsParams.courseCategory: category,
        if (instructorId != null) AnalyticsParams.instructorId: instructorId,
      });

  Future<void> logCourseEnrolled({
    required String courseId,
    String? source,
  }) =>
      _event(AnalyticsEvents.courseEnrolled, {
        AnalyticsParams.courseId: courseId,
        if (source != null) AnalyticsParams.source: source,
      });

  Future<void> logLectureStarted({
    required String courseId,
    required String lectureId,
    String? type,
    int? durationSec,
  }) =>
      _event(AnalyticsEvents.lectureStarted, {
        AnalyticsParams.courseId: courseId,
        AnalyticsParams.lectureId: lectureId,
        if (type != null) AnalyticsParams.lectureType: type,
        if (durationSec != null) AnalyticsParams.durationSec: durationSec,
      });

  Future<void> logLectureCompleted({
    required String courseId,
    required String lectureId,
    int? positionSec,
  }) =>
      _event(AnalyticsEvents.lectureCompleted, {
        AnalyticsParams.courseId: courseId,
        AnalyticsParams.lectureId: lectureId,
        if (positionSec != null) AnalyticsParams.positionSec: positionSec,
      });

  Future<void> logSubscriptionStarted({
    required String planId,
    required int billingPeriodMonths,
    double? valueUsd,
  }) =>
      _event(AnalyticsEvents.subscriptionStarted, {
        AnalyticsParams.planId: planId,
        AnalyticsParams.billingPeriodMonths: billingPeriodMonths,
        if (valueUsd != null) AnalyticsParams.valueUsd: valueUsd,
      });

  Future<void> logSubscriptionCanceled({required String planId}) =>
      _event(AnalyticsEvents.subscriptionCanceled, {
        AnalyticsParams.planId: planId,
      });

  Future<void> logSubscriptionRestored() =>
      _event(AnalyticsEvents.subscriptionRestored);

  Future<void> logWishlistAdded({required String courseId}) =>
      _event(AnalyticsEvents.wishlistAdded, {
        AnalyticsParams.courseId: courseId,
      });

  Future<void> logWishlistRemoved({required String courseId}) =>
      _event(AnalyticsEvents.wishlistRemoved, {
        AnalyticsParams.courseId: courseId,
      });

  Future<void> logQuestionPosted({
    required String courseId,
    required String lectureId,
    required String questionId,
  }) =>
      _event(AnalyticsEvents.questionPosted, {
        AnalyticsParams.courseId: courseId,
        AnalyticsParams.lectureId: lectureId,
        AnalyticsParams.questionId: questionId,
      });

  Future<void> logReplyPosted({
    required String courseId,
    required String questionId,
  }) =>
      _event(AnalyticsEvents.replyPosted, {
        AnalyticsParams.courseId: courseId,
        AnalyticsParams.questionId: questionId,
      });

  Future<void> logNoteSaved({required String lectureId}) =>
      _event(AnalyticsEvents.noteSaved, {
        AnalyticsParams.lectureId: lectureId,
      });

  Future<void> logDownloadStarted({required String lectureId}) =>
      _event(AnalyticsEvents.downloadStarted, {
        AnalyticsParams.lectureId: lectureId,
      });

  Future<void> logDownloadCompleted({required String lectureId}) =>
      _event(AnalyticsEvents.downloadCompleted, {
        AnalyticsParams.lectureId: lectureId,
      });

  Future<void> logAppStart() => _event(AnalyticsEvents.appStart);

  Future<void> logAppRatingShown() =>
      _event(AnalyticsEvents.appRatingShown);

  Future<void> logAppRatingResponded({required int rating}) =>
      _event(AnalyticsEvents.appRatingResponded, {
        AnalyticsParams.rating: rating,
      });

  Future<void> logThemeChanged(String mode) =>
      _event(AnalyticsEvents.themeChanged, {
        AnalyticsParams.themeMode: mode,
      });

  Future<void> logLocaleChanged(String code) =>
      _event(AnalyticsEvents.localeChanged, {
        AnalyticsParams.localeCode: code,
      });

  Future<void> logOnboardingComplete({
    String? skillLevel,
    String? primaryInstrument,
  }) =>
      _event(AnalyticsEvents.onboardingComplete, {
        if (skillLevel != null)
          AnalyticsUserProperties.skillLevel: skillLevel,
        if (primaryInstrument != null)
          AnalyticsUserProperties.primaryInstrument: primaryInstrument,
      });
}
