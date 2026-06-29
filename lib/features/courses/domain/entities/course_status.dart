import 'package:flutter/material.dart';

/// Course review / publication workflow.
///
/// State machine, abridged from the product spec:
///
/// ```
///   draft ── (instructor: submit) ──────► submitted
///                                              │
///                                              ▼
///                                        underReview
///                                          │       │
///                       (admin: approve)   │       │  (admin: request changes)
///                                          ▼       ▼
///                                     approved   changesRequested
///                                          │       │
///                       (admin: publish)   │       │  (instructor: resubmit)
///                                          ▼       │
///                                      published ◄─┘ (back into the submitted lane)
///                                       │     │
///                      (admin:          │     │  (admin: archive)
///                       unpublish)      ▼     ▼
///                                  unpublished archived
/// ```
///
/// `unpublished` and `archived` are terminal-ish — admin can move a
/// course back to `draft` from either of them (to start the cycle over),
/// but the consumer mobile app never surfaces non-`published` courses.
///
/// **Stable `.id`** — Firestore docs persist the id string, not the
/// enum index. Renaming an enum case is a zero-migration change as
/// long as the id stays the same.
enum CourseStatus {
  draft('draft', 'Draft'),
  submitted('submitted', 'Submitted'),
  underReview('under_review', 'Under review'),
  approved('approved', 'Approved'),
  changesRequested('changes_requested', 'Changes requested'),
  published('published', 'Published'),
  unpublished('unpublished', 'Unpublished'),
  archived('archived', 'Archived');

  const CourseStatus(this.id, this.label);

  final String id;
  final String label;

  static CourseStatus fromId(String? raw) {
    if (raw == null || raw.isEmpty) return CourseStatus.draft;
    for (final s in CourseStatus.values) {
      if (s.id == raw) return s;
    }
    return CourseStatus.draft;
  }

  /// Convenience — true while the course is on the instructor side of
  /// the workflow (still being edited or pending admin attention).
  bool get isInstructorEditable =>
      this == CourseStatus.draft ||
      this == CourseStatus.changesRequested;

  /// Convenience — true when the course is visible to consumers.
  bool get isLive => this == CourseStatus.published;

  /// Material color for status chips / pills.
  Color get color {
    switch (this) {
      case CourseStatus.draft:
        return Colors.blueGrey;
      case CourseStatus.submitted:
      case CourseStatus.underReview:
        return Colors.blue;
      case CourseStatus.approved:
        return Colors.teal;
      case CourseStatus.changesRequested:
        return Colors.orange;
      case CourseStatus.published:
        return Colors.green;
      case CourseStatus.unpublished:
        return Colors.deepPurple;
      case CourseStatus.archived:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case CourseStatus.draft:
        return Icons.edit_note;
      case CourseStatus.submitted:
        return Icons.send_outlined;
      case CourseStatus.underReview:
        return Icons.visibility_outlined;
      case CourseStatus.approved:
        return Icons.task_alt;
      case CourseStatus.changesRequested:
        return Icons.report_problem_outlined;
      case CourseStatus.published:
        return Icons.public;
      case CourseStatus.unpublished:
        return Icons.public_off;
      case CourseStatus.archived:
        return Icons.archive_outlined;
    }
  }

  /// Next states the viewer is allowed to transition to, given their
  /// role. Pure function — no Firestore access, no side effects — so
  /// it doubles as the per-row "what buttons do I render" oracle.
  ///
  /// Roles:
  ///   • `'instructor'` — sees only their own course.
  ///   • `'admin'`      — sees every course; can drive the workflow.
  ///   • anything else  — read-only (no actions).
  ///
  /// The returned list is ordered by "preferred next action," so the
  /// UI can render the first entry as the primary button and the rest
  /// as a dropdown / secondary actions.
  List<CourseStatus> allowedNextStates(String role) {
    if (role != 'admin' && role != 'instructor') return const [];

    switch (this) {
      case CourseStatus.draft:
        // Instructor finishes editing and submits for review.
        return role == 'instructor'
            ? const [CourseStatus.submitted]
            : const [CourseStatus.archived];

      case CourseStatus.submitted:
        // Admin pulls the course into review.
        return role == 'admin'
            ? const [CourseStatus.underReview, CourseStatus.archived]
            : const [];

      case CourseStatus.underReview:
        // Admin decides: approve or send back for changes.
        return role == 'admin'
            ? const [
                CourseStatus.approved,
                CourseStatus.changesRequested,
                CourseStatus.archived,
              ]
            : const [];

      case CourseStatus.approved:
        // Admin makes the course live.
        return role == 'admin'
            ? const [CourseStatus.published, CourseStatus.archived]
            : const [];

      case CourseStatus.changesRequested:
        // Back to the instructor — they edit and resubmit.
        return role == 'instructor'
            ? const [CourseStatus.submitted]
            : role == 'admin'
                ? const [CourseStatus.archived]
                : const [];

      case CourseStatus.published:
        // Admin can take it back offline.
        return role == 'admin'
            ? const [CourseStatus.unpublished, CourseStatus.archived]
            : const [];

      case CourseStatus.unpublished:
        // Admin can re-publish or archive.
        return role == 'admin'
            ? const [CourseStatus.published, CourseStatus.archived]
            : const [];

      case CourseStatus.archived:
        // Admin can resurrect into draft to restart the cycle.
        return role == 'admin' ? const [CourseStatus.draft] : const [];
    }
  }

  /// Action verb used as the button label for a transition INTO this
  /// status from the previous one. Helps the admin UI render buttons
  /// like "Submit for review" / "Approve" / "Request changes" instead
  /// of the bare label.
  String get actionLabel {
    switch (this) {
      case CourseStatus.draft:
        return 'Send back to draft';
      case CourseStatus.submitted:
        return 'Submit for review';
      case CourseStatus.underReview:
        return 'Start review';
      case CourseStatus.approved:
        return 'Approve';
      case CourseStatus.changesRequested:
        return 'Request changes';
      case CourseStatus.published:
        return 'Publish';
      case CourseStatus.unpublished:
        return 'Unpublish';
      case CourseStatus.archived:
        return 'Archive';
    }
  }
}
