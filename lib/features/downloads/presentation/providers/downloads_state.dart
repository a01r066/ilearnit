import 'package:flutter/foundation.dart';

import '../../domain/entities/download_entity.dart';

/// In-memory mirror of every known download, keyed by `lectureId`. The UI
/// reads this directly — both `DownloadsPage` and the per-lecture button
/// derive their state from a single source.
@immutable
class DownloadsState {
  const DownloadsState({
    this.byLectureId = const {},
    this.isInitialized = false,
  });

  /// Map keyed by lectureId. Includes completed + in-flight + failed.
  final Map<String, DownloadEntity> byLectureId;

  /// False until the manifest has been read from secure storage. The UI
  /// uses this to render a loading state on the first paint of
  /// `DownloadsPage` (otherwise the page would flash "no downloads"
  /// even for users with a populated manifest).
  final bool isInitialized;

  Iterable<DownloadEntity> get all => byLectureId.values;

  /// Completed downloads sorted by `downloadedAt desc` for the inbox.
  List<DownloadEntity> get completed {
    final list = byLectureId.values
        .where((d) => d.isCompleted)
        .toList();
    list.sort((a, b) {
      final ad = a.downloadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.downloadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return list;
  }

  /// Total bytes consumed by completed downloads. Surfaced on the inbox
  /// header as "12.4 MB used".
  int get totalBytesUsed {
    var sum = 0;
    for (final d in byLectureId.values) {
      if (d.isCompleted) sum += d.totalBytes;
    }
    return sum;
  }

  DownloadEntity? get(String lectureId) => byLectureId[lectureId];

  DownloadsState copyWith({
    Map<String, DownloadEntity>? byLectureId,
    bool? isInitialized,
  }) =>
      DownloadsState(
        byLectureId: byLectureId ?? this.byLectureId,
        isInitialized: isInitialized ?? this.isInitialized,
      );
}
