import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

/// Three-phase progress event for a Cloudflare Stream upload:
///   • [requestingUrl]  — calling the `createCloudflareUpload` Cloud
///     Function to mint a one-time upload URL.
///   • [uploading]      — POSTing file bytes to the returned URL.
///                        [fraction] is 0..1.
///   • [completed]      — Cloudflare accepted the upload; [videoUid]
///                        is the 32-hex UID to save on the lecture doc.
///   • [failed]         — [error] carries the human-readable cause.
enum CloudflareUploadPhase {
  requestingUrl,
  uploading,
  completed,
  failed,
}

class CloudflareUploadProgress {
  const CloudflareUploadProgress({
    required this.phase,
    this.fraction = 0,
    this.videoUid,
    this.error,
  });

  final CloudflareUploadPhase phase;
  final double fraction;
  final String? videoUid;
  final String? error;

  bool get isTerminal =>
      phase == CloudflareUploadPhase.completed ||
      phase == CloudflareUploadPhase.failed;
}

/// Picks a video file from local disk and uploads it directly to
/// Cloudflare Stream via the Direct Creator Upload flow:
///
///   1. Call `createCloudflareUpload` Cloud Function → returns
///      {uploadURL, uid}. The API token never leaves the server.
///   2. POST the file bytes to `uploadURL` as multipart/form-data.
///   3. On success, the `uid` from step 1 is the lecture's
///      `cloudflareVideoId` — drop it into the editor.
///
/// All progress events are emitted as a broadcast `Stream` so multiple
/// UI surfaces (progress bar + status text) can listen to the same
/// upload without competing for the underlying Dio stream.
class CloudflareUploadService {
  CloudflareUploadService({FirebaseFunctions? functions, Dio? dio})
      : _functions = functions ?? FirebaseFunctions.instance,
        _dio = dio ?? Dio();

  final FirebaseFunctions _functions;
  final Dio _dio;

  /// One-shot pick + upload. Returns the broadcast progress stream so
  /// the caller can drive a `LinearProgressIndicator` + result text
  /// from a single source.
  Stream<CloudflareUploadProgress> pickAndUpload({
    int maxDurationSeconds = 21600,
  }) {
    final controller = StreamController<CloudflareUploadProgress>.broadcast();
    _run(controller, maxDurationSeconds: maxDurationSeconds);
    return controller.stream;
  }

  Future<void> _run(
    StreamController<CloudflareUploadProgress> controller, {
    required int maxDurationSeconds,
  }) async {
    try {
      // ── Step 0: pick file ─────────────────────────────────────
      // withData: true so we get the bytes in-memory regardless of
      // platform — works on web (no file path) and mobile/desktop alike.
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        // User dismissed the picker. Close the stream silently — no
        // failure event because there's nothing to recover from.
        await controller.close();
        return;
      }
      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        controller.add(const CloudflareUploadProgress(
          phase: CloudflareUploadPhase.failed,
          error: 'Could not read file bytes.',
        ));
        await controller.close();
        return;
      }

      // ── Step 1: mint a one-time upload URL ────────────────────
      controller.add(const CloudflareUploadProgress(
        phase: CloudflareUploadPhase.requestingUrl,
      ));
      final res = await _functions
          .httpsCallable('createCloudflareUpload')
          .call<Map<String, dynamic>>({
        'maxDurationSeconds': maxDurationSeconds,
      });
      final uploadURL = res.data['uploadURL'] as String?;
      final uid = res.data['uid'] as String?;
      if (uploadURL == null || uid == null) {
        controller.add(const CloudflareUploadProgress(
          phase: CloudflareUploadPhase.failed,
          error: 'Server returned an invalid upload URL.',
        ));
        await controller.close();
        return;
      }

      // ── Step 2: POST the file bytes ───────────────────────────
      // Cloudflare Direct Creator Upload accepts a single
      // multipart/form-data field called `file`. Dio handles the
      // boundary + content-length headers; we attach the bytes via
      // MultipartFile.fromBytes.
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        ),
      });

      controller.add(const CloudflareUploadProgress(
        phase: CloudflareUploadPhase.uploading,
        fraction: 0,
      ));

      await _dio.post<void>(
        uploadURL,
        data: form,
        onSendProgress: (sent, total) {
          if (controller.isClosed) return;
          final f = total > 0 ? (sent / total).clamp(0.0, 1.0) : 0.0;
          controller.add(CloudflareUploadProgress(
            phase: CloudflareUploadPhase.uploading,
            fraction: f.toDouble(),
          ));
        },
        // Disable the default 60s timeout — even a 200MB upload on a
        // mid-tier connection takes longer than that. Cloudflare's
        // upload URL is valid for 30 min so the real ceiling is on
        // their side.
        options: Options(
          sendTimeout: const Duration(minutes: 30),
          receiveTimeout: const Duration(minutes: 30),
          // Cloudflare returns 200 on success regardless of body.
          validateStatus: (code) => code != null && code >= 200 && code < 300,
        ),
      );

      // ── Step 3: done ──────────────────────────────────────────
      controller.add(CloudflareUploadProgress(
        phase: CloudflareUploadPhase.completed,
        fraction: 1,
        videoUid: uid,
      ));
    } catch (e) {
      controller.add(CloudflareUploadProgress(
        phase: CloudflareUploadPhase.failed,
        error: e.toString(),
      ));
    } finally {
      await controller.close();
    }
  }

  // Exposed for unit tests / overriding in providers.
  static CloudflareUploadService create() => CloudflareUploadService();
}

// Avoids an unused-import lint when this file is consumed only via
// type references; the byte array type comes from dart:typed_data
// transitively but TS-style importers may need it explicit.
typedef _Bytes = Uint8List;
