/// Compound family keys for the notes providers. Hand-rolled — small
/// fields, fast equality.

/// Identifies a lecture's note stream. We key off `(courseId,
/// lectureId)` rather than `(uid, …)` because the user id comes from
/// the auth provider inside the family body — keeping it out of the
/// key avoids unnecessary family resets when the user object rebuilds.
class LectureNotesKey {
  const LectureNotesKey({
    required this.courseId,
    required this.lectureId,
  });

  final String courseId;
  final String lectureId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LectureNotesKey &&
          other.courseId == courseId &&
          other.lectureId == lectureId);

  @override
  int get hashCode => Object.hash(courseId, lectureId);
}

/// Identifies the per-lecture write form. Adds the section id (needed
/// for the note payload) and the lecture title (denormalized into the
/// note doc so the standalone notes page can render without resolving
/// the curriculum).
class NoteFormKey {
  const NoteFormKey({
    required this.courseId,
    required this.courseTitle,
    this.courseThumbnailUrl,
    required this.sectionId,
    required this.lectureId,
    required this.lectureTitle,
  });

  final String courseId;
  final String courseTitle;
  final String? courseThumbnailUrl;
  final String sectionId;
  final String lectureId;
  final String lectureTitle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteFormKey &&
          other.courseId == courseId &&
          other.sectionId == sectionId &&
          other.lectureId == lectureId);

  // Equality intentionally narrow — title / thumbnail changes shouldn't
  // recreate the notifier mid-typing.
  @override
  int get hashCode => Object.hash(courseId, sectionId, lectureId);
}
