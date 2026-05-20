/// Lifecycle of a purchase as reported by the store + our own bookkeeping.
enum PurchaseStatus {
  /// Local "purchase requested" before the store has responded.
  pending,

  /// Live purchase succeeded; receipt accepted.
  purchased,

  /// Past purchase replayed during `restorePurchases()`.
  restored,

  /// User cancelled, network error, signature failure, etc.
  failed,
}
