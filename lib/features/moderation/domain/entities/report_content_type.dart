/// What kind of UGC item a report refers to. Determines:
///   • the Firestore path the moderator opens to hide the content,
///   • the snapshot fields the report carries (denormalized so the
///     moderator queue doesn't need to dereference originals that may
///     have been edited or deleted before review).
///
/// Add new surfaces by extending this enum and teaching the
/// `ContentLocator` (see report.dart) to navigate to them.
enum ReportContentType {
  review('review'),
  question('question'),
  answer('answer'),
  note('note');

  const ReportContentType(this.id);

  final String id;

  static ReportContentType fromId(String? raw) {
    if (raw == null || raw.isEmpty) return ReportContentType.review;
    for (final t in ReportContentType.values) {
      if (t.id == raw) return t;
    }
    return ReportContentType.review;
  }

  String get label {
    switch (this) {
      case ReportContentType.review:
        return 'Review';
      case ReportContentType.question:
        return 'Question';
      case ReportContentType.answer:
        return 'Answer';
      case ReportContentType.note:
        return 'Note';
    }
  }
}
