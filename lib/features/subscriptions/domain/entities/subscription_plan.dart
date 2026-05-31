/// One of the two billing cadences offered on the Personal Plan.
///
/// Each value carries its store product id and a fallback price per
/// supported locale. The fallback is only shown until the platform returns
/// localized `ProductDetails` — once that lands, [resolvedPrice] swaps in
/// the store-delivered string.
///
/// Store SKUs to register:
///   • App Store Connect → In-App Purchases → **Auto-Renewable Subscription**
///   • Google Play Console → Monetize → Subscriptions
enum SubscriptionPlan {
  monthly(
    id: 'monthly',
    productId: 'info.ilearnit.personal_monthly',
    billingPeriodMonths: 1,
    // VND first (matches Tonebase-style design); USD shown for `en` locale.
    fallbackVnd: 800000,
    fallbackVndLabel: '₫800.000',
    fallbackUsd: 9.99,
    fallbackUsdLabel: r'$9.99',
  ),
  yearly(
    id: 'yearly',
    productId: 'info.ilearnit.personal_yearly',
    billingPeriodMonths: 12,
    fallbackVnd: 3000000,
    fallbackVndLabel: '₫3.000.000',
    fallbackUsd: 79.99,
    fallbackUsdLabel: r'$79.99',
  );

  const SubscriptionPlan({
    required this.id,
    required this.productId,
    required this.billingPeriodMonths,
    required this.fallbackVnd,
    required this.fallbackVndLabel,
    required this.fallbackUsd,
    required this.fallbackUsdLabel,
  });

  /// Persisted in Firestore.
  final String id;

  /// App Store / Play Store product identifier.
  final String productId;

  final int billingPeriodMonths;

  // Fallback prices used when the store hasn't returned ProductDetails yet.
  final int fallbackVnd;
  final String fallbackVndLabel;
  final double fallbackUsd;
  final String fallbackUsdLabel;

  /// All product ids the store should be queried for.
  static Set<String> get allProductIds =>
      {for (final p in SubscriptionPlan.values) p.productId};

  static SubscriptionPlan? fromId(String? id) {
    if (id == null) return null;
    for (final p in SubscriptionPlan.values) {
      if (p.id == id) return p;
    }
    return null;
  }

  static SubscriptionPlan? fromProductId(String productId) {
    for (final p in SubscriptionPlan.values) {
      if (p.productId == productId) return p;
    }
    return null;
  }

  /// Fallback label resolver — picks VND for `vi`, USD elsewhere.
  String fallbackLabelFor(String localeCode) =>
      localeCode == 'vi' ? fallbackVndLabel : fallbackUsdLabel;

  /// Effective per-month label. For [monthly] this is the same as the
  /// fallback; for [yearly] we divide by 12 to show "billed yearly" pricing.
  String fallbackPerMonthLabelFor(String localeCode) {
    if (billingPeriodMonths == 1) return fallbackLabelFor(localeCode);
    if (localeCode == 'vi') {
      final perMo = fallbackVnd ~/ 12;
      return '₫${_vnd(perMo)}';
    }
    final perMo = fallbackUsd / 12;
    return '\$${perMo.toStringAsFixed(2)}';
  }

  static String _vnd(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
