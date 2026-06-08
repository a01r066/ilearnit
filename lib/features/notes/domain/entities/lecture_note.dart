import 'package:freezed_annotation/freezed_annotation.dart';

part 'lecture_note.freezed.dart';

/// A private, per-user note attached to a single lecture. Optionally
/// pinned to a playback position so the user can jump back to that
/// moment from the notes list.
///
/// Persisted at `users/{uid}/notes/{noteId}` — owner-only by Firestore
/// rules. Course / lecture metadata (title, thumbnail) is denormalized
/// at write time so the standalone "My notes" page can render without
/// having to roundtrip to the course doc for every note.
@freezed
abstract class LectureNote with _$LectureNote {
  const LectureNote._();

  const factory LectureNote({
    required String id,
    required String userId,
    required String courseId,
    @Default('') String courseTitle,
    String? courseThumbnailUrl,
    required String sectionId,
    required String lectureId,
    @Default('') String lectureTitle,
    @Default('') String body,
    /// Playback position inside the lecture (seconds). Null for notes
    /// taken on a static lecture (PDF/doc) or when the user typed the
    /// note from the "My notes" page without a player open.
    int? timestampSec,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _LectureNote;

  /// Pretty `mm:ss` (or `h:mm:ss` past an hour) representation of
  /// [timestampSec] for tile labels and the jump button.
  String get formattedTimestamp {
    final s = timestampSec;
    if (s == null) return '';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
