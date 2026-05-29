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
  static const String notifications = 'admin-notifications';

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
  static const String notificationsPath = '/admin/notifications';
}
