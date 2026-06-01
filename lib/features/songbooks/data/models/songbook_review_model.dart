import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/songbook_review.dart';

class SongbookReviewModel {
  const SongbookReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.body,
    this.createdAt,
  });

  final String id;
  final String userName;
  final double rating;
  final String body;
  final DateTime? createdAt;

  factory SongbookReviewModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const <String, dynamic>{};
    return SongbookReviewModel(
      id: doc.id,
      userName: d['userName'] as String? ?? 'Anonymous',
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      body: d['body'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  SongbookReview toEntity() => SongbookReview(
        id: id,
        userName: userName,
        rating: rating,
        body: body,
        createdAt: createdAt,
      );
}
