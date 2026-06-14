/// Authorization role attached to a Firestore `users/{uid}` doc.
///
/// - [student] — default for any newly-registered user. Has read-only
///   access on the consumer mobile app.
/// - [instructor] — promoted via the instructor-application flow. Can
///   author and manage their own courses in the admin portal.
/// - [moderator] — promoted by an admin. Can triage UGC reports in
///   the in-app `/moderator` surface but has no course-authoring
///   powers. Distinct from [admin] so trusted community members can
///   help with moderation without being handed the whole portal.
/// - [admin] — full access in the admin portal: manages every course,
///   approves applications, manages instructors, also implicitly has
///   moderator powers.
enum UserRole {
  student('student'),
  instructor('instructor'),
  moderator('moderator'),
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

  /// True for both [moderator] and [admin] — admins are implicitly
  /// moderators. Drives the in-app `/moderator` route gate.
  bool get isModerator =>
      this == UserRole.moderator || this == UserRole.admin;

  /// Whether this role can sign into the admin portal.
  bool get canAccessAdminPortal => isAdmin || isInstructor;
}
