import '../../../../core/typedefs/typedefs.dart';
import '../entities/product_price_entity.dart';
import '../entities/purchase_entity.dart';

/// Contract for everything purchase-related — store calls, persistence,
/// and the live owned-courses stream.
abstract interface class PurchasesRepository {
  /// True iff the platform supports in-app billing (e.g. Play Services
  /// available on Android, StoreKit reachable on iOS).
  Future<bool> get isAvailable;

  /// Fetch localized product info for the tier products. Returns a map
  /// keyed by `productId`. Products the store doesn't know about (i.e.
  /// not registered in App Store Connect / Play Console) are silently
  /// omitted — callers fall back to [PriceTier.fallbackPrice].
  ResultFuture<Map<String, ProductPriceEntity>> fetchProducts(
    Set<String> productIds,
  );

  /// Initiates a non-consumable purchase. Success/failure is delivered
  /// asynchronously via the platform purchase stream — listen to
  /// [purchaseUpdates] and react there.
  ResultFuture<void> buyCourse({
    required String courseId,
    required String productId,
  });

  /// Tells the store to replay every past non-consumable purchase
  /// (after a fresh install or a sign-in on a new device).
  ResultFuture<void> restorePurchases();

  /// Stream of completed purchases, both live and restored. The Notifier
  /// listens once at app start and persists each emission to Firestore.
  Stream<PurchaseEntity> purchaseUpdates();

  /// Stream of `Set<courseId>` the user owns. Backed by Firestore.
  Stream<Set<String>> ownedCourseIds();

  /// One-off snapshot read of the user's purchases (used during sign-in
  /// to reconcile any purchases the platform delivered offline).
  ResultFuture<List<PurchaseEntity>> fetchUserPurchases();
}
