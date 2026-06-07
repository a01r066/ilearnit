import 'package:freezed_annotation/freezed_annotation.dart';

part 'wishlist_item.freezed.dart';

/// One saved course on a user's "Saved" list.
///
/// Persisted at `users/{uid}/wishlist/{courseId}` — the doc id equals the
/// course id, so toggle / dedup is a single key lookup.
///
/// We denormalize a handful of fields (`title`, `thumbnailUrl`,
/// `instructorName`, `priceTier`) so the Saved page can render without
/// an N+1 join back to `courses/{id}`. The price-drop Cloud Function
/// keeps the denormalized `priceTier` in sync when the source course
/// changes.
@freezed
abstract class WishlistItem with _$WishlistItem {
  const WishlistItem._();

  const factory WishlistItem({
    /// Always equals [courseId] — kept on the entity for symmetry with
    /// other domain types in the project.
    required String id,
    required String courseId,

    @Default('') String title,
    String? thumbnailUrl,
    @Default('') String instructorName,
    @Default('standard') String priceTier,

    /// Server timestamp written on create. Drives the list sort
    /// (newest saved first).
    DateTime? savedAt,
  }) = _WishlistItem;
}
