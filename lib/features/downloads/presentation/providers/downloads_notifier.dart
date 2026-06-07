import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../data/datasources/downloads_service.dart';
import '../../domain/entities/download_entity.dart';
import 'downloads_state.dart';

/// Bridges [DownloadsService]'s broadcast stream to a Riverpod state.
///
/// Eager-init: created once via [downloadsNotifierProvider] from
/// `bootstrap.dart` so the manifest is loaded before any UI tries to
/// read it.
class DownloadsNotifier extends StateNotifier<DownloadsState> {
  DownloadsNotifier(this._service) : super(const DownloadsState()) {
    _bootstrap();
  }

  final DownloadsService _service;
  StreamSubscription<DownloadProgressEvent>? _sub;

  Future<void> _bootstrap() async {
    final snap = await _service.snapshot();
    state = state.copyWith(byLectureId: snap, isInitialized: true);
    _sub = _service.events.listen(_onEvent);
  }

  void _onEvent(DownloadProgressEvent event) {
    state = state.copyWith(
      byLectureId: {
        ...state.byLectureId,
        event.entity.lectureId: event.entity,
      },
    );
  }

  // ---------- Public API used by the UI ------------------------------------

  Future<DownloadEntity> startDownload({
    required String lectureId,
    required String courseId,
    required String courseTitle,
    required String lectureTitle,
    required String mediaUrl,
  }) =>
      _service.enqueue(
        lectureId: lectureId,
        courseId: courseId,
        courseTitle: courseTitle,
        lectureTitle: lectureTitle,
        mediaUrl: mediaUrl,
      );

  Future<void> pause(String lectureId) => _service.cancel(lectureId);

  /// "Resume" is just a fresh enqueue — Dio doesn't natively support
  /// range-resume here, so we restart from byte 0. Surface this in the
  /// docs so users on flaky networks don't expect Bittorrent semantics.
  Future<void> resume(DownloadEntity entity) => _service.enqueue(
        lectureId: entity.lectureId,
        courseId: entity.courseId,
        courseTitle: entity.courseTitle,
        lectureTitle: entity.lectureTitle,
        mediaUrl: entity.mediaUrl,
      );

  Future<void> delete(String lectureId) async {
    await _service.delete(lectureId);
    // The stream won't fire on a delete; sync state manually.
    final next = {...state.byLectureId}..remove(lectureId);
    state = state.copyWith(byLectureId: next);
  }

  Future<void> wipe() async {
    await _service.wipe();
    state = state.copyWith(byLectureId: const {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
