import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/download_entity.dart';
import 'downloads_manifest_store.dart';

/// Snapshot emitted on the progress stream after every meaningful update —
/// download tick, completion, or failure.
class DownloadProgressEvent {
  const DownloadProgressEvent(this.entity);
  final DownloadEntity entity;
}

/// Downloads lecture media to the app's Documents directory and keeps the
/// manifest in lockstep.
///
/// Design notes:
///   • One in-flight download at a time per lectureId. A second `enqueue`
///     for the same lecture is a no-op while it's already downloading.
///   • CancelTokens are owned by this service so [cancel] can interrupt
///     a long-running fetch without leaking file handles.
///   • Progress is broadcast through a single [Stream] so all UI surfaces
///     (button + downloads page) read from the same source of truth.
class DownloadsService {
  DownloadsService({required DownloadsManifestStore manifest, Dio? dio})
      : _manifest = manifest,
        _dio = dio ?? Dio();

  final DownloadsManifestStore _manifest;
  final Dio _dio;

  final _controller = StreamController<DownloadProgressEvent>.broadcast();
  final Map<String, CancelToken> _inFlight = {};

  /// Hot stream — late subscribers don't get historical events, the UI is
  /// expected to read [snapshot] on init.
  Stream<DownloadProgressEvent> get events => _controller.stream;

  /// Synchronous read of every known download. Returns map keyed by
  /// `lectureId` for cheap lookups by the player swap logic.
  Future<Map<String, DownloadEntity>> snapshot() => _manifest.readAll();

  Future<DownloadEntity?> get(String lectureId) =>
      _manifest.read(lectureId);

  /// Enqueue a new download or resume a partially-downloaded one. Returns
  /// the initial / restored entity so the caller can pre-populate the UI.
  Future<DownloadEntity> enqueue({
    required String lectureId,
    required String courseId,
    required String courseTitle,
    required String lectureTitle,
    required String mediaUrl,
  }) async {
    final existing = await _manifest.read(lectureId);
    if (existing != null) {
      if (existing.isCompleted) return existing;
      if (existing.isInFlight) return existing;
    }

    final dir = await _downloadsDir();
    final filename = _filenameFor(lectureId, mediaUrl);
    final localPath = '${dir.path}${Platform.pathSeparator}$filename';

    final initial = (existing ?? DownloadEntity(
      lectureId: lectureId,
      courseId: courseId,
      courseTitle: courseTitle,
      lectureTitle: lectureTitle,
      mediaUrl: mediaUrl,
      localPath: localPath,
    ))
        .copyWith(
      status: DownloadStatus.downloading,
      lastError: null,
    );

    await _manifest.upsert(initial);
    _controller.add(DownloadProgressEvent(initial));

    // Fire-and-forget — caller subscribes to [events] for progress.
    unawaited(_run(initial));
    return initial;
  }

  Future<void> _run(DownloadEntity initial) async {
    final token = CancelToken();
    _inFlight[initial.lectureId] = token;

    try {
      // Dio's `download` writes to disk in chunks and reports progress.
      await _dio.download(
        initial.mediaUrl,
        initial.localPath,
        cancelToken: token,
        // Keep the body buffer small so video files don't OOM low-end
        // devices.
        deleteOnError: false,
        onReceiveProgress: (received, total) async {
          // Throttle disk writes — the manifest store is small but
          // EncryptedSharedPreferences on Android is not free.
          if (received % (256 * 1024) >= (8 * 1024) && total > 0) return;
          final next = initial.copyWith(
            bytesDownloaded: received,
            totalBytes: total > 0 ? total : initial.totalBytes,
            status: DownloadStatus.downloading,
          );
          await _manifest.upsert(next);
          _controller.add(DownloadProgressEvent(next));
        },
      );

      // Final size — Content-Length may have been zero; ask the file
      // system for the truth.
      final size = await File(initial.localPath).length();
      final done = initial.copyWith(
        bytesDownloaded: size,
        totalBytes: size,
        status: DownloadStatus.completed,
        downloadedAt: DateTime.now(),
        lastError: null,
      );
      await _manifest.upsert(done);
      _controller.add(DownloadProgressEvent(done));
    } catch (e) {
      // Distinguish "user cancelled" from real failure so the UI doesn't
      // surface an error toast for a deliberate pause.
      final cancelled = e is DioException &&
          CancelToken.isCancel(e);
      final next = initial.copyWith(
        status: cancelled
            ? DownloadStatus.paused
            : DownloadStatus.failed,
        lastError: cancelled ? null : e.toString(),
      );
      await _manifest.upsert(next);
      _controller.add(DownloadProgressEvent(next));
    } finally {
      _inFlight.remove(initial.lectureId);
    }
  }

  /// Cancel an in-flight download. Idempotent.
  Future<void> cancel(String lectureId) async {
    _inFlight[lectureId]?.cancel('user-cancelled');
  }

  /// Hard-delete: cancel any in-flight transfer, drop the local file,
  /// remove the manifest entry.
  Future<void> delete(String lectureId) async {
    await cancel(lectureId);
    final existing = await _manifest.read(lectureId);
    if (existing != null) {
      try {
        final file = File(existing.localPath);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best-effort — proceed with manifest cleanup even if the file
        // is stuck (e.g. external storage card removed).
      }
    }
    await _manifest.delete(lectureId);
  }

  /// Drop every download (cancel + delete). Used by sign-out and the
  /// "Clear all" overflow.
  Future<void> wipe() async {
    for (final id in [..._inFlight.keys]) {
      _inFlight[id]?.cancel('wipe');
    }
    final dir = await _downloadsDir();
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
    await _manifest.clearAll();
  }

  Future<void> dispose() async {
    for (final token in _inFlight.values) {
      token.cancel('dispose');
    }
    _inFlight.clear();
    await _controller.close();
  }

  // ---------- Local paths --------------------------------------------------

  Future<Directory> _downloadsDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${root.path}${Platform.pathSeparator}downloads',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Filename is `{lectureId}{ext}` so a re-download of the same lecture
  /// reuses the same file, and the extension lets the OS pick the right
  /// MIME on share-out.
  String _filenameFor(String lectureId, String url) {
    String ext = '';
    try {
      final uri = Uri.parse(url);
      final last = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
      final dot = last.lastIndexOf('.');
      if (dot != -1 && dot < last.length - 1) {
        ext = last.substring(dot); // includes the dot
      }
    } catch (_) {}
    return '$lectureId$ext';
  }
}
