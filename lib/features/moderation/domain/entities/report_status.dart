/// Lifecycle of a report from submission to resolution.
///
///   open         — submitted, awaiting moderator review.
///   actionTaken  — moderator hid the content or banned the author.
///   dismissed    — moderator reviewed and judged the report invalid.
///
/// The aggregate counter at `reports/_aggregates/openCount` tracks the
/// number of [open] reports so the admin side-nav badge doesn't need a
/// full scan. Cloud Function `onReportCreated` + `onReportResolved`
/// keep the counter in sync.
enum ReportStatus {
  open('open'),
  actionTaken('action_taken'),
  dismissed('dismissed');

  const ReportStatus(this.id);

  final String id;

  static ReportStatus fromId(String? raw) {
    if (raw == null || raw.isEmpty) return ReportStatus.open;
    for (final s in ReportStatus.values) {
      if (s.id == raw) return s;
    }
    return ReportStatus.open;
  }

  bool get isOpen => this == ReportStatus.open;
}
