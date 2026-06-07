/// Centralized route name constants. Keep paths and names colocated.
class RouteNames {
  const RouteNames._();

  // Auth (outside shell)
  static const String splash = 'splash';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String onboarding = 'onboarding';

  // Shell tabs
  static const String home = 'home';
  static const String courses = 'courses';
  static const String instructors = 'instructors';
  static const String songbooks = 'songbooks';
  static const String profile = 'profile';

  // Songbook detail (within songbooks tab)
  static const String songbookDetail = 'songbook-detail';

  // Detail (within shell)
  static const String courseDetail = 'course-detail';
  static const String instructorDetail = 'instructor-detail';

  // Lecture player (nested under course detail)
  static const String lecturePlayer = 'lecture-player';

  // Settings (within profile)
  static const String setting = 'settings';

  // Subscription (within profile)
  static const String subscription = 'subscription';
  static const String subscriptionCheckout = 'subscription-checkout';

  // Search (top-level, opens above shell)
  static const String search = 'search';

  // Legal (top-level, opens above shell — reachable from auth + profile)
  static const String legal = 'legal';

  // Delete account (within profile)
  static const String deleteAccount = 'delete-account';

  // Notifications inbox + preferences
  static const String notificationsInbox = 'notifications-inbox';
  static const String notificationPreferences = 'notification-prefs';

  // Offline downloads (within profile)
  static const String downloads = 'downloads';

  // Wishlist / saved courses (within profile)
  static const String wishlist = 'wishlist';

  // Learning paths
  static const String learningPathDetail = 'learning-path-detail';
}

class RoutePaths {
  const RoutePaths._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';

  static const String home = '/home';
  static const String courses = '/courses';
  static const String instructors = '/instructors';
  static const String songbooks = '/songbooks';
  static const String profile = '/profile';

  // Sub-routes (nested under songbooks)
  static const String songbookDetail = ':id';

  // Sub-routes
  static const String courseDetail = ':id';
  static const String instructorDetail = ':id';
  // Nested under courseDetail → /courses/:id/lectures/:lectureId
  static const String lecturePlayer = 'lectures/:lectureId';
  static const String settings = '/settings';

  // Subscription (nested under profile)
  static const String subscription = 'subscription';
  static const String subscriptionCheckout = 'checkout';

  // Search (top-level, modal-style above the shell)
  static const String search = '/search';

  // Legal (top-level, modal-style above the shell) — `/legal/privacy`,
  // `/legal/terms`.
  static const String legal = '/legal/:slug';

  // Delete account (nested under profile)
  static const String deleteAccount = 'delete-account';

  // Notifications — inbox is top-level (modal-style above the shell),
  // preferences is nested under profile/settings.
  static const String notificationsInbox = '/notifications';
  static const String notificationPreferences = 'notifications';

  // Offline downloads (nested under profile)
  static const String downloads = 'downloads';

  // Wishlist (nested under profile)
  static const String wishlist = 'wishlist';

  // Learning path detail (top-level, modal-style above the shell so the
  // Home rail and the course detail page both push the same screen).
  static const String learningPathDetail = '/learning-paths/:id';
}
