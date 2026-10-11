import 'dart:io' show Platform;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart' as iap;

/// Why the server refused. [retryable] failures must leave the store
/// transaction OPEN so the platform re-delivers it (next launch / stream pump).
class PurchaseVerificationException implements Exception {
  const PurchaseVerificationException(this.code, this.message);
  final String code;
  final String message;

  bool get retryable => const {
        'unavailable', 'deadline-exceeded', 'internal', 'unauthenticated', 'unknown',
      }.contains(code);

  @override
  String toString() => 'PurchaseVerificationException($code): $message';
}

class VerifiedGrant {
  const VerifiedGrant({required this.itemId, required this.alreadyGranted, required this.consumed});
  final String itemId;
  final bool alreadyGranted;

  /// Android: server consumed the token (which also acknowledges it) →
  /// the client must NOT call completePurchase.
  final bool consumed;
}

/// Client for functions/src/iap.ts. The app never writes entitlements.
class PurchaseVerificationDataSource {
  PurchaseVerificationDataSource({FirebaseFunctions? functions})
      : _fn = functions ?? FirebaseFunctions.instance;
  final FirebaseFunctions _fn;

  static String? get platform {
    if (kIsWeb) return null;
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return null;
  }

  /// Server records the intent and returns the product it expects.
  Future<String> createIntent(String itemId) async =>
      (await _call('createPurchaseIntent', {'itemId': itemId}))['productId'] as String;

  Future<VerifiedGrant> verifyTier(iap.PurchaseDetails p, {String? itemIdHint}) async {
    final r = await _call('verifyPurchase', {..._payload(p), 'itemId': itemIdHint});
    return VerifiedGrant(
      itemId: r['itemId'] as String,
      alreadyGranted: r['alreadyGranted'] == true,
      consumed: r['consumed'] == true,
    );
  }

  Future<String> verifyNonConsumable(iap.PurchaseDetails p) async =>
      (await _call('verifyNonConsumable', _payload(p)))['itemId'] as String;

  Future<bool> verifySubscription(iap.PurchaseDetails p) async =>
      (await _call('verifySubscription', _payload(p)))['active'] == true;

  Map<String, dynamic> _payload(iap.PurchaseDetails p) {
    final platform = PurchaseVerificationDataSource.platform;
    if (platform == null) {
      throw const PurchaseVerificationException('failed-precondition', 'Unsupported platform');
    }
    return {
      'platform': platform,
      'productId': p.productID,
      // iOS: server looks up the transaction by id (App Store Server API);
      // the receipt is only a fallback to extract an id. Android: Play token.
      'transactionId': p.purchaseID,
      'receipt': p.verificationData.serverVerificationData,
    };
  }

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    try {
      final res = await _fn.httpsCallable(name).call<Object?>(data);
      return Map<String, dynamic>.from(res.data! as Map);
    } on FirebaseFunctionsException catch (e) {
      throw PurchaseVerificationException(e.code, e.message ?? e.code);
    }
  }
}
