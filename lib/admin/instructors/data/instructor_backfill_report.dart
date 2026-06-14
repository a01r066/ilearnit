/// Outcome of one row in an [InstructorBackfillReport].
enum InstructorBackfillOutcome {
  /// `userId` was already populated — no work needed.
  alreadyLinked,

  /// Matched via email (the preferred key).
  matchedByEmail,

  /// Matched via name (case-insensitive `displayName` comparison).
  matchedByName,

  /// At least one match was found, but more than one — skipped to
  /// avoid binding to the wrong user.
  ambiguous,

  /// Zero candidates in `users` matched.
  noMatch,

  /// Firestore threw while looking up or writing.
  errored,
}

class InstructorBackfillRow {
  const InstructorBackfillRow({
    required this.instructorId,
    required this.instructorName,
    required this.outcome,
    this.linkedUserId,
    this.notes = '',
  });

  final String instructorId;
  final String instructorName;
  final InstructorBackfillOutcome outcome;
  final String? linkedUserId;
  final String notes;
}

/// Result of [AdminInstructorProfilesDataSource.migrateLegacyProfiles] or
/// [AdminInstructorProfilesDataSource.syncProfilesForAllInstructors].
class InstructorBackfillReport {
  const InstructorBackfillReport({
    required this.scanned,
    required this.rows,
  });

  /// Total instructor profiles inspected.
  final int scanned;

  /// Per-profile outcome rows. Order matches the input scan order.
  final List<InstructorBackfillRow> rows;

  int countWhere(InstructorBackfillOutcome outcome) =>
      rows.where((r) => r.outcome == outcome).length;

  int get matched =>
      countWhere(InstructorBackfillOutcome.matchedByEmail) +
      countWhere(InstructorBackfillOutcome.matchedByName);

  int get alreadyLinked =>
      countWhere(InstructorBackfillOutcome.alreadyLinked);

  int get ambiguous => countWhere(InstructorBackfillOutcome.ambiguous);

  int get noMatch => countWhere(InstructorBackfillOutcome.noMatch);

  int get errored => countWhere(InstructorBackfillOutcome.errored);
}
