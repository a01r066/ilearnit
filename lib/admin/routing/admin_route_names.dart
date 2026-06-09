/// Centralised route name constants for the admin web portal.
///
/// The literals are also used as path segments by `admin_router.dart`.
class AdminRoutes {
  const AdminRoutes._();

  static const String login = 'admin-login';
  static const String apply = 'admin-apply';
  static const String pending = 'admin-pending';
  static const String unauthorized = 'admin-unauthorized';

  static const String dashboard = 'admin-dashboard';

  // Instructor surfaces
  static const String myCourses = 'admin-my-courses';
  static const String courseEditor = 'admin-course-editor';

  // Admin-only surfaces
  static const String allCourses = 'admin-all-courses';
  static const String applications = 'admin-applications';
  static const String instructors = 'admin-instructors';
  static const String instructorProfiles = 'admin-instructor-profiles';
  static const String instructorProfileEditor = 'admin-instructor-profile-editor';
  static const String notifications = 'admin-notifications';
  static const String songbooks = 'admin-songbooks';
  static const String songbookEditor = 'admin-songbook-editor';
  static const String subscriptions = 'admin-subscriptions';
  static const String learningPaths = 'admin-learning-paths';
  static const String learningPathEditor = 'admin-learning-path-editor';
  static const String analytics = 'admin-analytics';
  static const String landingPage = 'admin-landing-page';

  // Path templates
  static const String loginPath = '/login';
  static const String applyPath = '/apply';
  static const String pendingPath = '/pending';
  static const String unauthorizedPath = '/unauthorized';
  static const String dashboardPath = '/';
  static const String myCoursesPath = '/my-courses';
  static const String courseEditorPath = '/my-courses/:id';
  static const String allCoursesPath = '/admin/courses';
  static const String applicationsPath = '/admin/applications';
  static const String instructorsPath = '/admin/instructors';
  static const String instructorProfilesPath = '/admin/instructor-profiles';
  static const String instructorProfileEditorPath = '/admin/instructor-profiles/:id';
  static const String notificationsPath = '/admin/notifications';
  static const String songbooksPath = '/admin/songbooks';
  static const String songbookEditorPath = '/admin/songbooks/:id';
  static const String subscriptionsPath = '/admin/subscriptions';
  static const String learningPathsPath = '/admin/learning-paths';
  static const String learningPathEditorPath = '/admin/learning-paths/:id';
  static const String analyticsPath = '/admin/analytics';
  static const String landingPagePath = '/admin/landing-page';
}
