import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/wishlist_item.dart';

part 'wishlist_item_model.freezed.dart';
part 'wishlist_item_model.g.dart';

/// Firestore DTO for `users/{uid}/wishlist/{courseId}`.
@freezed
abstract class WishlistItemModel with _$WishlistItemModel {
  const WishlistItemModel._();

  const factory WishlistItemModel({
    required String id,
    @Default('') String courseId,
    @Default('') String title,
    String? thumbnailUrl,
    @Default('') String instructorName,
    @Default('standard') String priceTier,
    @TimestampConverter() DateTime? savedAt,
  }) = _WishlistItemModel;

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) =>
      _$WishlistItemModelFromJson(json);

  factory WishlistItemModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return WishlistItemModel.fromJson({...data, 'id': doc.id});
  }

  WishlistItem toEntity() => WishlistItem(
        id: id,
        courseId: courseId.isEmpty ? id : courseId,
        title: title,
        thumbnailUrl: thumbnailUrl,
        instructorName: instructorName,
        priceTier: priceTier,
        savedAt: savedAt,
      );
}
