/// Authorization role attached to a Firestore `users/{uid}` doc.
///
/// - [student] — default for any newly-registered user. Has read-only
///   access on the consumer mobile app.
/// - [instructor] — promoted via the instructor-application flow. Can
///   author and manage their own courses in the admin portal.
/// - [admin] — full access in the admin portal: manages every course,
///   approves applications, manages instructors.
enum UserRole {
  student('student'),
  instructor('instructor'),
  admin('admin');

  const UserRole(this.id);

  /// Stable string used in Firestore so the value is stable across enum
  /// reordering / renaming.
  final String id;

  static UserRole fromId(String? raw) {
    if (raw == null || raw.isEmpty) return UserRole.student;
    for (final r in UserRole.values) {
      if (r.id == raw) return r;
    }
    return UserRole.student;
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isInstructor => this == UserRole.instructor;
  bool get isStudent => this == UserRole.student;

  /// Whether this role can sign into the admin portal.
  bool get canAccessAdminPortal => isAdmin || isInstructor;
}
