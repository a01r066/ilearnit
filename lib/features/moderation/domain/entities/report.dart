import 'package:freezed_annotation/freezed_annotation.dart';

import 'report_content_type.dart';
import 'report_reason.dart';
import 'report_status.dart';

part 'report.freezed.dart';

/// A user-submitted moderation report against a single UGC item.
///
/// Persisted at the top-level collection `reports/{reportId}`. The
/// collection is global (not nested under the reporter) so admins +
/// moderators can stream the open queue with a single query. Firestore
/// rules deny non-moderator reads.
///
/// **Denormalization.** The report doc carries a snapshot of the
/// reported content at submission time — `contentSnapshot`,
/// `authorId`, `authorName`. That way, even if the offending user
/// edits or deletes the original before review, the moderator can
/// still see what was reported. If the original still exists, the
/// `(contentType + contentPath)` pair lets the moderator open and act
/// on it.
@freezed
abstract class Report with _$Report {
  const Report._();

  const factory Report({
    required String id,
    required ReportContentType contentType,
    required String contentId,

    /// Full Firestore path of the reported content (e.g.
    /// `courses/{cid}/reviews/{rid}` or
    /// `courses/{cid}/sections/{sid}/lectures/{lid}/questions/{qid}`).
    /// Lets admin actions reach the doc without re-deriving the path
    /// from contentType + ids.
    required String contentPath,

    /// Optional course / lecture context for moderator scoping. A
    /// moderator who only owns courses in `{c1, c2}` can be filtered
    /// to reports with `courseId in [c1, c2]`.
    String? courseId,
    String? lectureId,

    /// Plain-text excerpt (≤ 280 chars) of the reported content so
    /// the moderator queue list can render a one-liner without
    /// dereferencing the original.
    @Default('') String contentSnapshot,
    @Default('') String authorId,
    @Default('') String authorName,

    /// Who flagged it.
    required String reporterId,
    @Default('') String reporterName,

    required ReportReason reason,

    /// Free-form notes from the reporter (≤ 500 chars enforced
    /// client-side).
    @Default('') String reporterNotes,

    @Default(ReportStatus.open) ReportStatus status,

    /// Moderator who closed the report.
    String? reviewedBy,
    String? reviewedByName,
    DateTime? reviewedAt,

    /// Free-form note from the moderator on what they did and why.
    @Default('') String resolutionNotes,

    DateTime? createdAt,
  }) = _Report;

  bool get isOpen => status.isOpen;
}
