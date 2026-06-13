import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/services/mini_player_service.dart';

/// The singleton service. `keepAlive: true` is implicit on a plain
/// `Provider` — it's never auto-disposed unless the container itself
/// shuts down.
final miniPlayerServiceProvider = Provider<MiniPlayerService>((ref) {
  final service = MiniPlayerService();
  ref.onDispose(service.dispose);
  return service;
});

/// Stream of player state changes. Drives both the in-page lecture
/// player UI and the persistent mini-player bar above the bottom nav.
final miniPlayerStateProvider = StreamProvider<MiniPlayerState>((ref) {
  final svc = ref.watch(miniPlayerServiceProvider);
  // Seed with the current snapshot so a late subscriber doesn't have
  // to wait for the next event to know "is there a track loaded?".
  return svc.stateStream.asBroadcastStream(
    onListen: (sub) {/* no-op */},
  );
});

/// Counter-based flag: how many lecture player pages are currently in
/// the navigation stack. A counter (not a bool) so that nested pushes
/// — e.g. the question-thread page opened from a lecture — keep the
/// bar hidden until the *outermost* lecture pops.
///
/// The bar reads this and self-hides when > 0. The
/// `LecturePlayerPage` bumps it in `initState` and decrements it in
/// `dispose`. Using a provider (vs. route-string sniffing) sidesteps
/// the `GoRouterState.of(shell-context)` shallow-match issue — the
/// lecture page nested inside a shell branch sits above the shell's
/// scaffold, and the shell's context still reports the shell's route.
final miniPlayerHiddenDepthProvider = StateProvider<int>((_) => 0);
