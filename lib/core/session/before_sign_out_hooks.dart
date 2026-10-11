import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Work that must run while the user is STILL signed in, right before
/// `FirebaseAuth.signOut()` — e.g. removing this device's FCM token from
/// `users/{uid}`, which firestore.rules only allow for the signed-in owner.
///
/// Features register a callback once (see NotificationBootstrap); the
/// AuthNotifier runs them all in `logout()`. Each hook is best-effort and
/// time-boxed so a slow network can never block signing out.
class BeforeSignOutHooks {
  final List<Future<void> Function()> _hooks = [];

  void register(Future<void> Function() hook) => _hooks.add(hook);

  void unregister(Future<void> Function() hook) => _hooks.remove(hook);

  Future<void> run({Duration timeout = const Duration(seconds: 4)}) async {
    await Future.wait(
      [
        for (final hook in List.of(_hooks))
          hook().timeout(timeout).catchError((Object e) {
            if (kDebugMode) debugPrint('[sign-out hook] $e');
          }),
      ],
    );
  }
}

final beforeSignOutHooksProvider =
    Provider<BeforeSignOutHooks>((_) => BeforeSignOutHooks());
