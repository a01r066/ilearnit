import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/songbook_entity.dart';

/// Firestore DTO for the `songbooks` collection.
class SongbookModel {
  const SongbookModel({
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
  final String coverUrl;
  final String bannerUrl;
  final String description;
  final List<String> includes;
  final String instrument;
  final List<String> topics;
  final String publisher;
  final double rating;
  final int ratingCount;
  final String productId;
  final bool isBestseller;
  final List<String> samplePages;
  final DateTime? publishedAt;

  factory SongbookModel.fromJson(Map<String, dynamic> json) => SongbookModel(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        coverUrl: json['coverUrl'] as String? ?? '',
        bannerUrl: json['bannerUrl'] as String? ?? '',
        description: json['description'] as String? ?? '',
        includes:
            (json['includes'] as List?)?.whereType<String>().toList() ?? const [],
        instrument: json['instrument'] as String? ?? '',
        topics: (json['topics'] as List?)?.whereType<String>().toList() ??
            const [],
        publisher: json['publisher'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
        productId: json['productId'] as String? ?? '',
        isBestseller: json['isBestseller'] as bool? ?? false,
        samplePages:
            (json['samplePages'] as List?)?.whereType<String>().toList() ??
                const [],
        publishedAt: _toDate(json['publishedAt']),
      );

  factory SongbookModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return SongbookModel.fromJson({...data, 'id': doc.id});
  }

  SongbookEntity toEntity() => SongbookEntity(
        id: id,
        title: title,
        coverUrl: coverUrl,
        bannerUrl: bannerUrl.isEmpty ? coverUrl : bannerUrl,
        description: description,
        includes: includes,
        instrument: instrument,
        topics: topics,
        publisher: publisher,
        rating: rating,
        ratingCount: ratingCount,
        productId: productId,
        isBestseller: isBestseller,
        samplePages: samplePages,
        publishedAt: publishedAt,
      );

  static DateTime? _toDate(Object? raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return null;
  }
}
