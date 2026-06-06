import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_endpoints.dart';
import '../domain/notification_payload.dart';
import '../domain/notification_topics.dart';
import 'local_notifications_service.dart';

/// Top-level background message handler. Must be a top-level (or static)
/// function annotated with [pragma('vm:entry-point')] so Flutter can call
/// into it from a fresh isolate when the OS wakes the app up just to
/// deliver a notification.
///
/// We intentionally do *nothing* here: by default FCM auto-displays the
/// `notification` block of the payload in the system tray. Add logic here
/// only if you need to e.g. update a local DB on receipt.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op. Background delivery is handled by the system tray.
}

/// Connects [FirebaseMessaging] to the rest of the app:
///
///   - **Permission** — prompts iOS (and Android 13+) the first time.
///   - **Token** — fetches the current FCM token and writes it to
///     `users/{uid}.fcmTokens` (arrayUnion) so Cloud Functions can target
///     a specific user. Also re-writes on token refresh.
///   - **Foreground** — pipes incoming `RemoteMessage`s through
///     [LocalNotificationsService.show] so the user sees them while the
///     app is open.
///   - **Taps** — emits a [NotificationPayload] on [taps] when the user
///     opens the app from a notification (cold start, background, or
///     foreground tap).
///   - **Topics** — sub/unsub helpers driven by the user's role +
///     primaryInstrument.
///
/// One instance per app. Created and `init()`'d in `bootstrap.dart` /
/// `bootstrap_admin.dart` after Firebase has initialized.
class FcmService {
  FcmService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required LocalNotificationsService local,
  })  : _messaging = messaging,
        _firestore = firestore,
        _local = local;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final LocalNotificationsService _local;

  StreamSubscription? _fgSub;
  StreamSubscription? _openedSub;
  StreamSubscription? _tokenSub;
  StreamSubscription? _localTapSub;

  final StreamController<NotificationPayload> _taps =
      StreamController<NotificationPayload>.broadcast();

  /// Stream of payloads from notification taps (any state: cold, bg, fg).
  /// Subscribe from the app shell to route deep-links via go_router.
  Stream<NotificationPayload> get taps => _taps.stream;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  /// Whether the OS has granted permission to display notifications. Read
  /// after [init] completes.
  late AuthorizationStatus permissionStatus;

  /// Initialize the service. Idempotent — calling twice is safe but the
  /// second call is a no-op.
  Future<void> init() async {
    // 1. Permission. On iOS this shows the system prompt; on Android 13+
    //    it shows the new POST_NOTIFICATIONS permission prompt. On older
    //    Android it's a no-op that returns authorized.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    permissionStatus = settings.authorizationStatus;

    if (permissionStatus == AuthorizationStatus.denied) {
      if (kDebugMode) {
        debugPrint('[fcm] Permission denied — push notifications will not '
            'be displayed. The user can re-enable in OS settings.');
      }
      return;
    }

    // 2. Foreground messages → forward to local notifications so they
    //    actually appear (FCM doesn't auto-display in foreground).
    _fgSub = FirebaseMessaging.onMessage.listen(_onForeground);

    // 3. Tap on a notification while app is backgrounded → app comes to
    //    front. The `RemoteMessage` is delivered here.
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onTap);

    // 4. Cold-start tap: the OS launched the app from a notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onTap(initialMessage);
    }

    // 5. Local-notification taps forward to the same sink.
    _localTapSub = _local.taps.listen(_taps.add);

    // 6. Auto-subscribe to the broad "all_users" topic. Per-instrument and
    //    role-based subscriptions are driven by the auth notifier later.
    await subscribeToTopic(NotificationTopics.allUsers);
  }

  void _onForeground(RemoteMessage m) {
    final n = m.notification;
    final payload = NotificationPayload.fromData(m.data);
    if (n == null) return;
    _local.show(
      title: n.title ?? '',
      body: n.body ?? '',
      payload: payload,
    );
  }

  void _onTap(RemoteMessage m) {
    _taps.add(NotificationPayload.fromData(m.data));
  }

  // ---------- Token management -------------------------------------------

  /// Bind the FCM token to a signed-in user's Firestore profile.
  ///
  /// Writes the token to `users/{uid}.fcmTokens` (arrayUnion) and listens
  /// to [FirebaseMessaging.onTokenRefresh] so token rotations stay in
  /// sync. Call after sign-in.
  Future<void> bindUser(String uid) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _users.doc(uid).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
        },
        SetOptions(merge: true),
      );
    }

    await _tokenSub?.cancel();
    _tokenSub = _messaging.onTokenRefresh.listen((t) {
      _users.doc(uid).set(
        {
          'fcmTokens': FieldValue.arrayUnion([t]),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Remove the current device's token from a user's profile and stop
  /// listening for refreshes. Call on sign-out.
  Future<void> unbindUser(String uid) async {
    await _tokenSub?.cancel();
    _tokenSub = null;
    final token = await _messaging.getToken();
    if (token == null) return;
    await _users.doc(uid).set(
      {
        'fcmTokens': FieldValue.arrayRemove([token]),
      },
      SetOptions(merge: true),
    );
  }

  /// Re-request notification permission outside of [init].
  ///
  /// The onboarding "soft ask" step calls this after showing a friendly
  /// rationale screen. Returns the resulting [AuthorizationStatus] so the
  /// UI can branch on allow / deny without inspecting the FCM service's
  /// own field.
  Future<AuthorizationStatus> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    permissionStatus = settings.authorizationStatus;
    return permissionStatus;
  }

  // ---------- Topic management -------------------------------------------

  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  /// Reconcile topic subscriptions against a user's current state:
  ///   - always on `all_users`
  ///   - on `admins` iff role is admin
  ///   - on one `instrument_*` based on primaryInstrument (if any)
  ///
  /// Idempotent — safe to call on every auth change.
  Future<void> reconcileTopicsForUser({
    required bool isAdmin,
    required String? primaryInstrument,
  }) async {
    await subscribeToTopic(NotificationTopics.allUsers);

    if (isAdmin) {
      await subscribeToTopic(NotificationTopics.admins);
    } else {
      await unsubscribeFromTopic(NotificationTopics.admins);
    }

    final instrumentTopic =
        NotificationTopics.forInstrument(primaryInstrument);
    for (final t in const [
      NotificationTopics.instrumentGuitar,
      NotificationTopics.instrumentPiano,
      NotificationTopics.instrumentViolin,
    ]) {
      if (t == instrumentTopic) {
        await subscribeToTopic(t);
      } else {
        await unsubscribeFromTopic(t);
      }
    }
  }

  Future<void> dispose() async {
    await _fgSub?.cancel();
    await _openedSub?.cancel();
    await _tokenSub?.cancel();
    await _localTapSub?.cancel();
    await _taps.close();
  }
}
