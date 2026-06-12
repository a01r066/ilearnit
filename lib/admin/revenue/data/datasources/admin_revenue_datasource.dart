import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/payout_model.dart';
import '../models/transaction_model.dart';

/// Admin-only read/write for transactions + payouts. Firestore rules
/// allow the reads directly; mutations (refund / mark paid / create
/// broadcast) funnel through Cloud Functions so the audit trail is
/// captured server-side.
///
/// **Refund + payout policy** in v1 is bookkeeping-only:
///   • Refunds flip `transactions.{status: 'refunded'}` and cancel
///     the matching enrollment. No money is moved.
///   • Payouts flip `payouts.{status: 'paid'}` after the admin
///     processes the actual transfer out-of-band.
class AdminRevenueDataSource {
  AdminRevenueDataSource({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _firestore = firestore,
        _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _txns =>
      _firestore.collection('transactions');

  CollectionReference<Map<String, dynamic>> get _payouts =>
      _firestore.collection('payouts');

  // ── Transactions ────────────────────────────────────────────────

  Stream<List<TransactionModel>> watchAllTransactions({
    String? statusFilter,
    int limit = 200,
  }) {
    Query<Map<String, dynamic>> q = _txns.limit(limit);
    if (statusFilter != null) {
      q = q.where('status', isEqualTo: statusFilter);
    }
    return q.snapshots().map((s) {
      final list = s.docs.map(TransactionModel.fromDoc).toList();
      list.sort(
        (a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)),
      );
      return list;
    });
  }

  /// Calls the `processRefund` Cloud Function. The function validates
  /// admin role, marks the transaction refunded, cancels the
  /// enrollment, and notifies the student via inbox + push.
  Future<void> refundTransaction({
    required String transactionId,
    String? reason,
  }) async {
    await _functions
        .httpsCallable('processRefund')
        .call<void>({'transactionId': transactionId, 'reason': reason});
  }

  // ── Payouts ──────────────────────────────────────────────────────

  Stream<List<PayoutModel>> watchAllPayouts({int limit = 200}) =>
      _payouts.limit(limit).snapshots().map((s) {
        final list = s.docs.map(PayoutModel.fromDoc).toList();
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return list;
      });

  Future<void> markPayoutPaid({
    required String payoutId,
    String? method,
  }) async {
    await _functions
        .httpsCallable('markPayoutPaid')
        .call<void>({'payoutId': payoutId, 'method': method});
  }

  /// Manual payout-doc creation. Admin types the period + recipient.
  /// In production this should come from a scheduled aggregator.
  Future<String> createPayout({
    required String instructorUid,
    required String instructorName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double grossUsd,
    required double platformFee,
    required List<String> txnIds,
  }) async {
    final doc = _payouts.doc();
    await doc.set({
      'instructorUid': instructorUid,
      'instructorName': instructorName,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'grossUsd': grossUsd,
      'platformFee': platformFee,
      'netUsd': grossUsd - platformFee,
      'status': 'pending',
      'txnIds': txnIds,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }
}
