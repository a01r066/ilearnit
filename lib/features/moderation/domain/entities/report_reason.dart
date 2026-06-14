/// Stable enum stored as `reason` on every `reports/{id}` doc.
///
/// The labels here are user-facing strings shown in the report sheet.
/// Reordering / renaming the [name] values is fine; the [id] is what
/// persists in Firestore and must NEVER change without a migration.
///
/// Mirrors the categories Apple App Store + Google Play require an app
/// to surface for UGC. See the App Review Guideline 1.2 checklist.
enum ReportReason {
  spam('spam', 'Spam or scam'),
  harassment('harassment', 'Harassment or bullying'),
  hateSpeech('hate_speech', 'Hate speech or symbols'),
  sexualContent('sexual_content', 'Nudity or sexual content'),
  violence('violence', 'Violence or dangerous content'),
  selfHarm('self_harm', 'Self-harm or suicide'),
  misinformation('misinformation', 'False information'),
  intellectualProperty('ip', 'Copyright / IP infringement'),
  other('other', 'Something else');

  const ReportReason(this.id, this.label);

  final String id;
  final String label;

  static ReportReason fromId(String? raw) {
    if (raw == null || raw.isEmpty) return ReportReason.other;
    for (final r in ReportReason.values) {
      if (r.id == raw) return r;
    }
    return ReportReason.other;
  }
}
