import 'package:flutter/foundation.dart';

/// Domain entity for one songbook in the Songbooks tab.
///
/// Songbooks are a separate content type from courses — they're sheet-music
/// books (often from publishers like Hal Leonard) that the user can sample
/// in-app and unlock via subscription or one-off purchase.
@immutable
class SongbookEntity {
  const SongbookEntity({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.bannerUrl,
    required this.description,
    required this.includes,
    required this.instrument,
    required this.topics,
    required this.publisher,
    required this.rating,
    required this.ratingCount,
    required this.productId,
    required this.isBestseller,
    required this.samplePages,
    this.publishedAt,
  });

  final String id;
  final String title;

  /// Portrait cover image (~3:4) shown in carousels + grid.
  final String coverUrl;

  /// Wide banner image shown at the top of the detail page (~16:9).
  /// Falls back to [coverUrl] if empty.
  final String bannerUrl;

  final String description;

  /// List of song titles included in the book.
  final List<String> includes;

  /// e.g. "Piano", "Guitar", "Mixed"
  final String instrument;

  /// Free-form tags (e.g. "weekly Specials", "Beginner", "Pop").
  final List<String> topics;

  final String publisher;
  final double rating;
  final int ratingCount;

  /// Maps to an IAP product (per-songbook purchase) — same `PriceTier`
  /// pattern as courses.
  final String productId;

  final bool isBestseller;

  /// URLs to sample PDF pages the user can preview without purchase.
  final List<String> samplePages;

  final DateTime? publishedAt;
}
