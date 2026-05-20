import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_price_entity.freezed.dart';

/// Wraps the platform's `ProductDetails` (App Store / Play Store) so the
/// presentation layer doesn't depend on the `in_app_purchase` package types.
@freezed
abstract class ProductPriceEntity with _$ProductPriceEntity {
  const factory ProductPriceEntity({
    required String productId,
    required String title,
    required String description,
    required String price,        // localized, e.g. "$9.99", "€8,99", "¥1,200"
    required String currencyCode, // ISO 4217
    @Default(0.0) double rawPrice,
  }) = _ProductPriceEntity;
}
