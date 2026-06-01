import 'package:flutter/foundation.dart';

@immutable
class SongbookReview {
  const SongbookReview({
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
}
