/// Centralized route name constants. Keep paths and names colocated.
class RouteNames {
  const RouteNames._();

  // Auth (outside shell)
  static const String splash = 'splash';
  static const String login = 'login';
  static const String signup = 'signup';

  // Shell tabs
  static const String home = 'home';
  static const String courses = 'courses';
  static const String instructors = 'instructors';
  static const String profile = 'profile';

  // Detail (within shell)
  static const String courseDetail = 'course-detail';
  static const String instructorDetail = 'instructor-detail';
}

class RoutePaths {
  const RoutePaths._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';

  static const String home = '/home';
  static const String courses = '/courses';
  static const String instructors = '/instructors';
  static const String profile = '/profile';

  // Sub-routes
  static const String courseDetail = ':id';
  static const String instructorDetail = ':id';
}
