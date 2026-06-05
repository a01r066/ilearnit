import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// What part of the upload pipeline you're observing — useful for the UI
/// to show "Preparing…", "Uploading 23%", "Done" states.
enum UploadPhase { preparing, running, paused, completed, failed, canceled }

/// Snapshot emitted while a media file is uploading. The presentation layer
/// binds to a `Stream<UploadProgress>` and renders a LinearProgressIndicator.
class UploadProgress {
  const UploadProgress({
    required this.phase,
    required this.fraction,
    required this.bytesTransferred,
    required this.totalBytes,
    this.downloadUrl,
    this.error,
  });

  /// 0.0 to 1.0.
  final double fraction;
  final int bytesTransferred;
  final int totalBytes;
  final UploadPhase phase;

  /// Populated when [phase] == [UploadPhase.completed].
  final String? downloadUrl;

  /// Populated when [phase] == [UploadPhase.failed].
  final Object? error;

  bool get isTerminal =>
      phase == UploadPhase.completed ||
      phase == UploadPhase.failed ||
      phase == UploadPhase.canceled;

  int get percent => (fraction * 100).clamp(0, 100).round();
}

/// Wraps Firebase Storage uploads for the admin portal.
///
/// Storage layout (folders pre-created by the rules — no need to create
/// them on the client):
///
///     courses/{courseId}/thumbnail.<ext>
///     courses/{courseId}/sections/{sectionId}/lectures/{lectureId}/media.<ext>
///     courses/{courseId}/sections/{sectionId}/lectures/{lectureId}/resources/{filename}
class AdminStorageService {
  AdminStorageService({required FirebaseStorage storage}) : _storage = storage;

  final FirebaseStorage _storage;

  /// Upload a course thumbnail. Returns the eventual download URL on
  /// completion via the [UploadProgress] stream.
  Stream<UploadProgress> uploadCourseThumbnail({
    required String courseId,
    required String filename,
    required Uint8List bytes,
    required String contentType,
  }) {
    final ref = _storage.ref('courses/$courseId/thumbnail/$filename');
    return _runUpload(ref, bytes, contentType);
  }

  /// Upload a songbook portrait cover (~3:4) shown in carousels + grid.
  Stream<UploadProgress> uploadSongbookCover({
    required String songbookId,
    required String filename,
    required Uint8List bytes,
    required String contentType,
  }) {
    final ref = _storage.ref('songbooks/$songbookId/cover/$filename');
    return _runUpload(ref, bytes, contentType);
  }

  /// Upload a songbook wide banner (~16:9) shown on the detail page.
  Stream<UploadProgress> uploadSongbookBanner({
    required String songbookId,
    required String filename,
    required Uint8List bytes,
    required String contentType,
  }) {
    final ref = _storage.ref('songbooks/$songbookId/banner/$filename');
    return _runUpload(ref, bytes, contentType);
  }

  /// Upload the main media file (video / audio / pdf) for a lecture.
  Stream<UploadProgress> uploadLectureMedia({
    required String courseId,
    required String sectionId,
    required String lectureId,
    required String filename,
    required Uint8List bytes,
    required String contentType,
  }) {
    final ref = _storage.ref(
      'courses/$courseId/sections/$sectionId/lectures/$lectureId/media/$filename',
    );
    return _runUpload(ref, bytes, contentType);
  }

  /// Upload a supplementary resource (sheet music PDF, exercise file).
  Stream<UploadProgress> uploadLectureResource({
    required String courseId,
    required String sectionId,
    required String lectureId,
    required String filename,
    required Uint8List bytes,
    required String contentType,
  }) {
    final ref = _storage.ref(
      'courses/$courseId/sections/$sectionId/lectures/$lectureId/resources/$filename',
    );
    return _runUpload(ref, bytes, contentType);
  }

  // ---------- internals ---------------------------------------------------

  Stream<UploadProgress> _runUpload(
    Reference ref,
    Uint8List bytes,
    String contentType,
  ) {
    final controller = StreamController<UploadProgress>();
    final total = bytes.lengthInBytes;

    controller.add(UploadProgress(
      phase: UploadPhase.preparing,
      fraction: 0,
      bytesTransferred: 0,
      totalBytes: total,
    ));

    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );

    final sub = task.snapshotEvents.listen((snap) {
      final fraction = snap.totalBytes == 0
          ? 0.0
          : snap.bytesTransferred / snap.totalBytes;
      controller.add(UploadProgress(
        phase: _mapPhase(snap.state),
        fraction: fraction,
        bytesTransferred: snap.bytesTransferred,
        totalBytes: snap.totalBytes,
      ));
    });

    task.then((snap) async {
      try {
        final url = await ref.getDownloadURL();
        controller.add(UploadProgress(
          phase: UploadPhase.completed,
          fraction: 1,
          bytesTransferred: total,
          totalBytes: total,
          downloadUrl: url,
        ));
      } catch (e) {
        controller.add(UploadProgress(
          phase: UploadPhase.failed,
          fraction: 0,
          bytesTransferred: 0,
          totalBytes: total,
          error: e,
        ));
      } finally {
        await sub.cancel();
        await controller.close();
      }
    }).catchError((Object e) async {
      controller.add(UploadProgress(
        phase: UploadPhase.failed,
        fraction: 0,
        bytesTransferred: 0,
        totalBytes: total,
        error: e,
      ));
      await sub.cancel();
      await controller.close();
    });

    return controller.stream;
  }

  UploadPhase _mapPhase(TaskState s) {
    switch (s) {
      case TaskState.running:
        return UploadPhase.running;
      case TaskState.paused:
        return UploadPhase.paused;
      case TaskState.success:
        return UploadPhase.completed;
      case TaskState.canceled:
        return UploadPhase.canceled;
      case TaskState.error:
        return UploadPhase.failed;
    }
  }
}
