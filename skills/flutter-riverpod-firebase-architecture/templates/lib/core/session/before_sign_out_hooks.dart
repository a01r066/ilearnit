import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Work that must run while the user is STILL signed in, right before
/// `FirebaseAuth.signOut()` — e.g. removing this device's FCM token from
/// `users/{uid}` (rules only allow the owner). Best-effort, time-boxed.
class BeforeSignOutHooks {
  final List<Future<void> Function()> _hooks = [];

  void register(Future<void> Function() hook) => _hooks.add(hook);
  void unregister(Future<void> Function() hook) => _hooks.remove(hook);

  Future<void> run({Duration timeout = const Duration(seconds: 4)}) async {
    await Future.wait([
      for (final hook in List.of(_hooks))
        hook().timeout(timeout).catchError((Object e) {
          if (kDebugMode) debugPrint('[sign-out hook] $e');
        }),
    ]);
  }
}

final beforeSignOutHooksProvider = Provider<BeforeSignOutHooks>((_) => BeforeSignOutHooks());

// In AuthNotifier:
//   Future<void> logout() async {
//     await _ref.read(beforeSignOutHooksProvider).run();
//     await _auth.signOut();
//   }
