import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/songbook_entity.dart';

part 'songbook_model.freezed.dart';
part 'songbook_model.g.dart';

/// Firestore DTO for the `songbooks` collection.
@freezed
abstract class SongbookModel with _$SongbookModel {
  const SongbookModel._();

  const factory SongbookModel({
    required String id,
    @Default('') String title,
    @Default('') String coverUrl,
    @Default('') String bannerUrl,
    @Default('') String description,
    @Default(<String>[]) List<String> includes,
    @Default('') String instrument,
    @Default(<String>[]) List<String> topics,
    @Default('') String publisher,
    @Default(0.0) double rating,
    @Default(0) int ratingCount,
    @Default('') String productId,
    @Default(false) bool isBestseller,
    @Default(<String>[]) List<String> samplePages,
    @TimestampConverter() DateTime? publishedAt,
  }) = _SongbookModel;

  factory SongbookModel.fromJson(Map<String, dynamic> json) =>
      _$SongbookModelFromJson(json);

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
}
