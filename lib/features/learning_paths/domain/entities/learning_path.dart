import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../courses/domain/entities/instrument_category.dart';

part 'learning_path.freezed.dart';

/// Curated multi-course sequence (e.g. "Classical Guitar from Scratch —
/// 12 Weeks"). Editorial product, written by admin via the admin portal.
///
/// Persisted at `learning_paths/{pathId}`.
///
/// `courseIds` order is significant — the detail page renders them as a
/// numbered list, and the next-up CTA picks the first course the user
/// hasn't finished.
@freezed
abstract class LearningPath with _$LearningPath {
  const LearningPath._();

  const factory LearningPath({
    required String id,
    @Default('') String title,
    @Default('') String summary,
    String? coverUrl,

    /// Optional instrument filter — null means the path mixes
    /// instruments (e.g. "Music theory for all").
    InstrumentCategory? instrument,

    /// Ordered list. The first id is "lesson 1".
    @Default(<String>[]) List<String> courseIds,

    /// Editor-supplied total — denormalized so the card can render
    /// "32 hours" without summing per-course durations on the client.
    @Default(0) double totalHours,

    /// Optional publish gate. Admins can park a draft path without
    /// pulling the doc.
    @Default(true) bool isPublished,

    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _LearningPath;

  int get courseCount => courseIds.length;
}
