import 'application_status.dart';

/// A user's application to become an instructor on the platform.
///
/// The Firestore doc lives at `instructor_applications/{uid}` — keyed by the
/// applicant's auth uid so they can only have one open application at a time.
class InstructorApplication {
  const InstructorApplication({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.bio,
    required this.instruments,
    required this.status,
    this.years,
    this.portfolioUrl,
    this.rejectionReason,
    this.appliedAt,
    this.decidedAt,
    this.decidedBy,
  });

  final String id;
  final String userId;
  final String displayName;
  final String email;
  final String bio;

  /// Instrument category ids the applicant wants to teach (`guitar`, `piano`,
  /// `violin`).
  final List<String> instruments;
  final int? years;
  final String? portfolioUrl;

  final ApplicationStatus status;
  final String? rejectionReason;

  final DateTime? appliedAt;
  final DateTime? decidedAt;

  /// uid of the admin who approved / rejected.
  final String? decidedBy;
}
