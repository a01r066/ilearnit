/// REST endpoints (used when calling our own backend via Dio).
/// Firestore collections are kept separately in `FirestoreCollections`.
class ApiEndpoints {
  const ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Courses
  static const String courses = '/courses';
  static String courseDetail(String id) => '/courses/$id';

  // Instructors
  static const String instructors = '/instructors';
  static String instructorDetail(String id) => '/instructors/$id';
}

class FirestoreCollections {
  const FirestoreCollections._();

  static const String users = 'users';
  static const String courses = 'courses';
  static const String lessons = 'lessons';
  static const String instructors = 'instructors';
  static const String enrollments = 'enrollments';
  static const String reviews = 'reviews';
}
