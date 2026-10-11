import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/offline_storage.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/courses/presentation/providers/courses_providers.dart';
import '../features/downloads/presentation/providers/downloads_providers.dart';
import '../features/mini_player/presentation/providers/mini_player_providers.dart';

/// Clears per-user local state when a signed-in session ends — via
/// logout, account deletion, or a revoked session.
///
///   • stops + clears the mini player (paid audio/video kept playing and
///     the bar stayed visible for the next person on the device)
///   • wipes offline downloads (the downloads page is guest-accessible,
///     so they would otherwise stay playable without an account)
///   • drops cached signed Cloudflare URLs
///
/// Only fires on an authenticated → unauthenticated transition, so a
/// guest's own preview downloads are never touched. Read once from
/// bootstrap.dart to activate.
final sessionCleanupProvider = Provider<void>((ref) {
  String? lastUid;

  ref.listen<AuthState>(authNotifierProvider, (_, next) async {
    final user = next.userOrNull;
    if (user != null) {
      lastUid = user.id;
      return;
    }
    // `loading` also reports no user; wait for the settled state.
    if (next is! Unauthenticated || lastUid == null) return;
    lastUid = null;

    try {
      await ref.read(miniPlayerServiceProvider).close();
      ref.read(cloudflareStreamServiceProvider).clear();
      ref.read(lectureMediaServiceProvider).clear();
      await ref.read(downloadsNotifierProvider.notifier).wipe();
      // Lecture resources (PDFs, scores) opened from the lecture page.
      await OfflineStorage.wipe('resources', legacyName: 'ilearnit');
      // Paid songbook PDFs.
      await OfflineStorage.wipe('songbooks');
    } catch (e) {
      if (kDebugMode) debugPrint('[session-cleanup] $e');
    }
  }, fireImmediately: true);
});
