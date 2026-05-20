/// Three flat tiers that map to App Store / Play Store products.
///
/// Each course in the catalogue picks a tier (rather than carrying its own
/// product id) so we only have to register 3 SKUs in the store consoles
/// regardless of how big the catalogue grows.
///
/// Stores → console setup:
///   • App Store Connect → In-App Purchases → Non-Consumable
///   • Google Play Console → Monetize → Products → In-app products → Managed
enum PriceTier {
  basic('basic', r'$9.99', 9.99),
  standard('standard', r'$19.99', 19.99),
  premium('premium', r'$39.99', 39.99);

  const PriceTier(this.id, this.fallbackPrice, this.rawFallbackPrice);

  /// Persisted value (e.g. in Firestore `priceTier` field).
  final String id;

  /// Used until the platform delivers real `ProductDetails` (offline /
  /// first-paint state). Replace at runtime with localized store price.
  final String fallbackPrice;
  final double rawFallbackPrice;

  /// Product ID registered in the App Store / Play Console.
  String get productId => 'info.ilearnit.tier_$id';

  static PriceTier fromId(String id) => PriceTier.values.firstWhere(
        (e) => e.id == id,
        orElse: () => PriceTier.basic,
      );

  /// All product IDs — used to bulk-fetch ProductDetails at app start.
  static Set<String> get allProductIds =>
      {for (final t in PriceTier.values) t.productId};

  /// Reverse lookup — product id back to tier (for matching the
  /// PurchaseDetails stream emissions to a tier).
  static PriceTier? fromProductId(String productId) {
    for (final t in PriceTier.values) {
      if (t.productId == productId) return t;
    }
    return null;
  }
}
