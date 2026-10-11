import 'dart:io' show Platform;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import '../../../../l10n/l10n.dart';


/// Result of a server-side course purchase verification.
class CourseVerificationResult {
  const CourseVerificationResult({
    required this.courseId,
    required this.alreadyGranted,
    required this.consumed,
  });

  final String courseId;
  final bool alreadyGranted;

  /// Android only — true when the server consumed the Play purchase
  /// token, so the client must NOT acknowledge it again.
  final bool consumed;
}

/// Why the server refused a receipt. [retryable] failures (network,
/// store outage) must leave the store transaction open so it replays.
class PurchaseVerificationException implements Exception {
  const PurchaseVerificationException(this.code, this.message);

  final String code;
  final String message;

  bool get retryable =>
      code == 'unavailable' ||
      code == 'deadline-exceeded' ||
      code == 'internal' ||
      code == 'unauthenticated' ||
      code == 'unknown';

  @override
  String toString() => 'PurchaseVerificationException($code): $message';
}

/// Client for the IAP Cloud Functions in `functions/src/iap.ts`.
///
/// The client never writes entitlements itself — these callables validate
/// the Apple / Google receipt and mint ownership server-side.
class PurchaseVerificationDataSource {
  PurchaseVerificationDataSource({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// `'ios'` / `'android'`, or null where IAP isn't supported.
  static String? get platform {
    if (kIsWeb) return null;
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return null;
  }

  /// Records the course the user is about to buy and returns the store
  /// product id the server expects for it (derived from the course tier).
  Future<String> createIntent(String courseId) async {
    final res = await _call('createPurchaseIntent', {'courseId': courseId});
    return res['productId'] as String;
  }

  Future<CourseVerificationResult> verifyCourse(
    iap.PurchaseDetails p, {
    String? courseIdHint,
  }) async {
    final res = await _call('verifyPurchase', {
      ..._receiptPayload(p),
      'courseId': courseIdHint,
    });
    return CourseVerificationResult(
      courseId: res['courseId'] as String,
      alreadyGranted: res['alreadyGranted'] == true,
      consumed: res['consumed'] == true,
    );
  }

  /// Verifies a songbook purchase / restore; returns the songbook id.
  Future<String> verifySongbook(iap.PurchaseDetails p) async {
    final res = await _call('verifySongbookPurchase', _receiptPayload(p));
    return res['songbookId'] as String;
  }

  /// Returns true when the subscription is currently active.
  Future<bool> verifySubscription(iap.PurchaseDetails p) async {
    final res = await _call('verifySubscription', _receiptPayload(p));
    return res['active'] == true;
  }

  Map<String, dynamic> _receiptPayload(iap.PurchaseDetails p) {
    final platform = PurchaseVerificationDataSource.platform;
    if (platform == null) {
      throw PurchaseVerificationException(
        'failed-precondition',
        L10n.current.purchaseNotSupportedPlatform,
      );
    }
    return <String, dynamic>{
      'platform': platform,
      'productId': p.productID,
      // iOS: the server looks the transaction up with the App Store
      // Server API by id; the app receipt is only a fallback to extract
      // an id from. Android: the Play purchase token.
      'transactionId': p.purchaseID,
      'receipt': p.verificationData.serverVerificationData,
    };
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call<Object?>(data);
      return Map<String, dynamic>.from(result.data! as Map);
    } on FirebaseFunctionsException catch (e) {
      throw PurchaseVerificationException(e.code, e.message ?? e.code);
    }
  }
}
