import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/domain/entities/user_role.dart';
import '../../session/before_sign_out_hooks.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../data/fcm_service.dart';
import '../data/local_notifications_service.dart';
import '../domain/notification_payload.dart';

// ---------- Singletons ----------------------------------------------------

final localNotificationsServiceProvider =
    Provider<LocalNotificationsService>((ref) => LocalNotificationsService());

final firebaseMessagingProvider =
    Provider<FirebaseMessaging>((_) => FirebaseMessaging.instance);

final fcmServiceProvider = Provider<FcmService>(
  (ref) => FcmService(
    messaging: ref.watch(firebaseMessagingProvider),
    firestore: ref.watch(firestoreProvider),
    local: ref.watch(localNotificationsServiceProvider),
  ),
);

/// Stream of payloads from any notification tap (cold-start, background,
/// foreground). The app shell listens here and routes via go_router.
/// Current OS / browser notification permission (no prompt).
/// Invalidate after asking to refresh.
final notificationPermissionProvider =
    FutureProvider<AuthorizationStatus>((ref) async {
  final settings =
      await ref.watch(firebaseMessagingProvider).getNotificationSettings();
  return settings.authorizationStatus;
});

final notificationTapsProvider = StreamProvider<NotificationPayload>(
  (ref) => ref.watch(fcmServiceProvider).taps,
);

// ---------- Bootstrap notifier --------------------------------------------

/// Initialize local + remote notifications on first read, then bind/unbind
/// the user's FCM token + reconcile topics whenever the auth user changes.
///
/// "Reading" this provider once during app bootstrap is enough — it self-
/// drives from then on by listening to auth state.
final notificationBootstrapProvider = Provider<NotificationBootstrap>((ref) {
  final boot = NotificationBootstrap(ref);
  final hooks = ref.watch(beforeSignOutHooksProvider);
  hooks.register(boot._beforeSignOut);
  ref.onDispose(() => hooks.unregister(boot._beforeSignOut));
  boot._start();
  ref.onDispose(boot.dispose);
  return boot;
});

/// Owns the lifecycle wiring between [FcmService] and the auth state.
/// Created by [notificationBootstrapProvider] — don't construct directly.
class NotificationBootstrap {
  NotificationBootstrap(this._ref);
  final Ref _ref;

  String? _boundUid;

  Future<void> _start() async {
    final local = _ref.read(localNotificationsServiceProvider);
    final fcm = _ref.read(fcmServiceProvider);

    await local.init();
    await fcm.init();

    // React to auth/profile changes: bind token + reconcile topics on
    // sign-in; invalidate the token after sign-out. (Removing it from the
    // profile happens in [_beforeSignOut], while still authenticated.)
    _ref.listen(currentUserProvider, (_, user) async {
      try {
        if (user == null) {
          if (_boundUid != null) {
            _boundUid = null;
            // Already signed out — no Firestore write possible; kill the
            // token instead so stale entries can't deliver.
            await fcm.resetToken();
          }
          return;
        }
        if (_boundUid != user.id) {
          if (_boundUid != null) await fcm.resetToken();
          await fcm.bindUser(user.id);
          _boundUid = user.id;
        }
        await fcm.reconcileTopicsForUser(
          isAdmin: user.role == UserRole.admin,
          primaryInstrument: user.primaryInstrument,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('[notifications] auth sync failed: $e');
      }
    }, fireImmediately: true);
  }

  /// Asks for permission (must run from a user gesture on web) and, if
  /// granted, binds this device's token to the signed-in user — the
  /// automatic bind at sign-in can't get a web token before permission.
  Future<AuthorizationStatus> requestPermissionAndBind() async {
    final fcm = _ref.read(fcmServiceProvider);
    final status = await fcm.requestPermission();
    final user = _ref.read(currentUserProvider);
    if (user != null &&
        (status == AuthorizationStatus.authorized ||
            status == AuthorizationStatus.provisional)) {
      try {
        await fcm.bindUser(user.id);
        _boundUid = user.id;
        await fcm.reconcileTopicsForUser(
          isAdmin: user.role == UserRole.admin,
          primaryInstrument: user.primaryInstrument,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('[notifications] bind after grant failed: $e');
      }
    }
    _ref.invalidate(notificationPermissionProvider);
    return status;
  }

  Future<void> _beforeSignOut() async {
    final uid = _boundUid;
    if (uid == null) return;
    await _ref.read(fcmServiceProvider).unbindUser(uid);
  }

  Future<void> dispose() async {
    await _ref.read(fcmServiceProvider).dispose();
    await _ref.read(localNotificationsServiceProvider).dispose();
  }
}
