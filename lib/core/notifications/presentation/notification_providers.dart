import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/domain/entities/user_role.dart';
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
    // sign-in, unbind on sign-out.
    _ref.listen(currentUserProvider, (_, user) async {
      if (user == null) {
        if (_boundUid != null) {
          await fcm.unbindUser(_boundUid!);
          _boundUid = null;
        }
        return;
      }
      if (_boundUid != user.id) {
        if (_boundUid != null) await fcm.unbindUser(_boundUid!);
        await fcm.bindUser(user.id);
        _boundUid = user.id;
      }
      await fcm.reconcileTopicsForUser(
        isAdmin: user.role == UserRole.admin,
        primaryInstrument: user.primaryInstrument,
      );
    }, fireImmediately: true);
  }

  Future<void> dispose() async {
    await _ref.read(fcmServiceProvider).dispose();
    await _ref.read(localNotificationsServiceProvider).dispose();
  }
}
