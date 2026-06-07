import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/datasources/downloads_manifest_store.dart';
import '../../data/datasources/downloads_service.dart';
import '../../domain/entities/download_entity.dart';
import 'downloads_notifier.dart';
import 'downloads_state.dart';

// ---------- Singletons ----------------------------------------------------

final _flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  ),
);

final downloadsManifestStoreProvider = Provider<DownloadsManifestStore>(
  (ref) => DownloadsManifestStore(ref.watch(_flutterSecureStorageProvider)),
);

final downloadsServiceProvider = Provider<DownloadsService>(
  (ref) {
    final service = DownloadsService(
      manifest: ref.watch(downloadsManifestStoreProvider),
    );
    ref.onDispose(service.dispose);
    return service;
  },
);

/// Long-lived state. Read from `bootstrap.dart` so the manifest is in
/// memory before any page tries to consume it.
final downloadsNotifierProvider =
    StateNotifierProvider<DownloadsNotifier, DownloadsState>(
  (ref) => DownloadsNotifier(ref.watch(downloadsServiceProvider)),
);

// ---------- Selectors -----------------------------------------------------

/// Live download state for a single lecture. Returns `null` if the user
/// never started one.
final downloadForLectureProvider =
    Provider.family<DownloadEntity?, String>((ref, lectureId) {
  return ref.watch(downloadsNotifierProvider).get(lectureId);
});

/// Local file path if the lecture is fully downloaded, else `null`. The
/// lecture player swaps the network URL for this when present.
final localMediaPathForLectureProvider =
    Provider.family<String?, String>((ref, lectureId) {
  final d = ref.watch(downloadForLectureProvider(lectureId));
  if (d == null || !d.isCompleted) return null;
  return d.localPath;
});
