/// Compound family keys for the Q&A providers. Hand-rolled
/// (not freezed) — small fields, fast equality.
class LectureQAKey {
  const LectureQAKey({
    required this.courseId,
    required this.sectionId,
    required this.lectureId,
  });

  final String courseId;
  final String sectionId;
  final String lectureId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LectureQAKey &&
          other.courseId == courseId &&
          other.sectionId == sectionId &&
          other.lectureId == lectureId);

  @override
  int get hashCode => Object.hash(courseId, sectionId, lectureId);
}

class QuestionRepliesKey {
  const QuestionRepliesKey({
    required this.courseId,
    required this.sectionId,
    required this.lectureId,
    required this.questionId,
  });

  final String courseId;
  final String sectionId;
  final String lectureId;
  final String questionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionRepliesKey &&
          other.courseId == courseId &&
          other.sectionId == sectionId &&
          other.lectureId == lectureId &&
          other.questionId == questionId);

  @override
  int get hashCode =>
      Object.hash(courseId, sectionId, lectureId, questionId);
}
