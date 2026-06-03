import 'package:freezed_annotation/freezed_annotation.dart';

part 'songbook_review.freezed.dart';

@freezed
abstract class SongbookReview with _$SongbookReview {
  const factory SongbookReview({
    required String id,
    required String userName,
    required double rating,
    required String body,
    DateTime? createdAt,
  }) = _SongbookReview;
}
