/// Lifecycle of an instructor application.
enum ApplicationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const ApplicationStatus(this.id);
  final String id;

  static ApplicationStatus fromId(String? raw) {
    if (raw == null) return ApplicationStatus.pending;
    for (final s in ApplicationStatus.values) {
      if (s.id == raw) return s;
    }
    return ApplicationStatus.pending;
  }

  bool get isPending => this == ApplicationStatus.pending;
  bool get isApproved => this == ApplicationStatus.approved;
  bool get isRejected => this == ApplicationStatus.rejected;
}
