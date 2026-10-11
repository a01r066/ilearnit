import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/providers/core_providers.dart';

/// Clears per-user local state when a signed-in session ends (logout,
/// account deletion, revoked token). Fires only on signed-in → signed-out,
/// so a guest's own data is never touched. Read once from bootstrap.dart.
final sessionCleanupProvider = Provider<void>((ref) {
  String? lastUid;
  ref.listen<AsyncValue<User?>>(authStateChangesProvider, (_, next) async {
    final user = next.value;
    if (next.isLoading) return;
    if (user != null) {
      lastUid = user.uid;
      return;
    }
    if (lastUid == null) return;
    lastUid = null;
    try {
      // Add one line per feature that caches user data on device:
      // await ref.read(playerServiceProvider).close();
      // ref.read(signedUrlCacheProvider).clear();
      // await OfflineStorage.wipe('downloads');
      // await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[session-cleanup] $e');
    }
  }, fireImmediately: true);
});
