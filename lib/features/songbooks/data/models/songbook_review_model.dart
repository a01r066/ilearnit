import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/songbook_review.dart';

part 'songbook_review_model.freezed.dart';
part 'songbook_review_model.g.dart';

@freezed
abstract class SongbookReviewModel with _$SongbookReviewModel {
  const SongbookReviewModel._();

  const factory SongbookReviewModel({
    required String id,
    @Default('Anonymous') String userName,
    @Default(0.0) double rating,
    @Default('') String body,
    @TimestampConverter() DateTime? createdAt,
  }) = _SongbookReviewModel;

  factory SongbookReviewModel.fromJson(Map<String, dynamic> json) =>
      _$SongbookReviewModelFromJson(json);

  factory SongbookReviewModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return SongbookReviewModel.fromJson({...data, 'id': doc.id});
  }

  SongbookReview toEntity() => SongbookReview(
        id: id,
        userName: userName,
        rating: rating,
        body: body,
        createdAt: createdAt,
      );
}
