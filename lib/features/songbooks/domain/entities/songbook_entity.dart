import 'package:freezed_annotation/freezed_annotation.dart';

part 'songbook_entity.freezed.dart';

/// Domain entity for one songbook in the Songbooks tab.
///
/// Songbooks are a separate content type from courses — they're sheet-music
/// books (often from publishers like Hal Leonard) that the user can sample
/// in-app and unlock via subscription or one-off purchase.
@freezed
abstract class SongbookEntity with _$SongbookEntity {
  const factory SongbookEntity({
    required String id,
    required String title,

    /// Portrait cover image (~3:4) shown in carousels + grid.
    required String coverUrl,

    /// Wide banner image shown at the top of the detail page (~16:9).
    /// Falls back to [coverUrl] when empty (resolved at the model layer).
    required String bannerUrl,
    required String description,

    /// List of song titles included in the book.
    required List<String> includes,

    /// e.g. "Piano", "Guitar", "Mixed"
    required String instrument,

    /// Free-form tags (e.g. "weekly Specials", "Beginner", "Pop").
    required List<String> topics,
    required String publisher,
    required double rating,
    required int ratingCount,

    /// Maps to an IAP product (per-songbook purchase) — same `PriceTier`
    /// pattern as courses.
    required String productId,
    required bool isBestseller,

    /// URLs to sample PDF pages the user can preview without purchase.
    required List<String> samplePages,
    DateTime? publishedAt,
  }) = _SongbookEntity;
}
