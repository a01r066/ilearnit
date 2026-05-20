import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart' as iap;

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/product_price_entity.dart';
import '../../domain/entities/purchase_status.dart';

/// Thin wrapper over the `in_app_purchase` plugin so the repository never
/// references the platform types directly. All conversions to domain
/// entities live here.
abstract interface class IapRemoteDataSource {
  Future<bool> get isAvailable;

  /// Loads localized product info from the store.
  Future<Map<String, ProductPriceEntity>> fetchProducts(
    Set<String> productIds,
  );

  /// Begins the purchase flow for a non-consumable. Result is delivered
  /// asynchronously through [purchaseStream].
  Future<void> buyNonConsumable({
    required String productId,
    String? applicationUserName,
  });

  Future<void> restorePurchases();

  /// Raw stream of [iap.PurchaseDetails] emitted by the platform.
  /// Repositories adapt these into domain `PurchaseEntity` values.
  Stream<List<iap.PurchaseDetails>> get purchaseStream;

  /// Marks a purchase as consumed/acknowledged so the store stops
  /// re-emitting it. MUST be called after persisting the receipt.
  Future<void> completePurchase(iap.PurchaseDetails purchase);
}

class IapRemoteDataSourceImpl implements IapRemoteDataSource {
  IapRemoteDataSourceImpl({iap.InAppPurchase? platform})
      : _platform = platform ?? iap.InAppPurchase.instance;

  final iap.InAppPurchase _platform;

  @override
  Future<bool> get isAvailable => _platform.isAvailable();

  @override
  Future<Map<String, ProductPriceEntity>> fetchProducts(
    Set<String> productIds,
  ) async {
    final response = await _platform.queryProductDetails(productIds);

    if (response.error != null) {
      throw ServerException(
        message: response.error!.message,
        statusCode: 0,
      );
    }

    final out = <String, ProductPriceEntity>{};
    for (final p in response.productDetails) {
      out[p.id] = ProductPriceEntity(
        productId: p.id,
        title: p.title,
        description: p.description,
        price: p.price,
        currencyCode: p.currencyCode,
        rawPrice: p.rawPrice,
      );
    }
    return out;
  }

  @override
  Future<void> buyNonConsumable({
    required String productId,
    String? applicationUserName,
  }) async {
    final response = await _platform.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      throw ServerException(
        message: 'Product "$productId" is not available in the store.',
      );
    }
    final params = iap.PurchaseParam(
      productDetails: response.productDetails.first,
      applicationUserName: applicationUserName,
    );
    final accepted = await _platform.buyNonConsumable(purchaseParam: params);
    if (!accepted) {
      throw ServerException(
        message: 'The store declined to start the purchase flow.',
      );
    }
  }

  @override
  Future<void> restorePurchases() => _platform.restorePurchases();

  @override
  Stream<List<iap.PurchaseDetails>> get purchaseStream =>
      _platform.purchaseStream;

  @override
  Future<void> completePurchase(iap.PurchaseDetails purchase) =>
      _platform.completePurchase(purchase);
}

/// Convert a platform purchase status into our domain enum.
PurchaseStatus mapPlatformPurchaseStatus(iap.PurchaseStatus status) {
  switch (status) {
    case iap.PurchaseStatus.purchased:
      return PurchaseStatus.purchased;
    case iap.PurchaseStatus.restored:
      return PurchaseStatus.restored;
    case iap.PurchaseStatus.pending:
      return PurchaseStatus.pending;
    case iap.PurchaseStatus.error:
    case iap.PurchaseStatus.canceled:
      return PurchaseStatus.failed;
  }
}
