import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_entity.freezed.dart';

/// Lifecycle state for a single lecture download.
///
/// `queued` → `downloading` → `completed` (happy path).
/// `paused` is reachable from `downloading`; `failed` from any non-terminal.
enum DownloadStatus { queued, downloading, paused, completed, failed }

/// One downloaded lecture. Persisted to flutter_secure_storage as JSON
/// (keyed by `lectureId`), so the manifest survives reinstalls of the
/// app data sandbox on Android and the Documents directory rotation on
/// iOS only if the user re-signs-in with the same keychain access group.
///
/// The actual media bytes live at [localPath] under
/// `getApplicationDocumentsDirectory()/downloads/` — app-private,
/// unencrypted, removed on uninstall.
@freezed
abstract class DownloadEntity with _$DownloadEntity {
  const DownloadEntity._();

  const factory DownloadEntity({
    required String lectureId,
    required String courseId,
    required String courseTitle,
    required String lectureTitle,

    /// Source URL the download was kicked off from. Used to detect when an
    /// instructor re-uploads a lecture (we'd then invalidate the cache).
    required String mediaUrl,

    /// Absolute file path under the app's Documents directory.
    required String localPath,

    /// Bytes written so far (== total on completion).
    @Default(0) int bytesDownloaded,

    /// Total bytes as advertised by the server's `Content-Length`. Stays
    /// `0` if the server didn't send the header — progress will read as
    /// indeterminate in that case.
    @Default(0) int totalBytes,

    @Default(DownloadStatus.queued) DownloadStatus status,

    DateTime? downloadedAt,

    /// Last error message, surfaced to the UI on `failed` status.
    String? lastError,
  }) = _DownloadEntity;

  /// 0..1 — clamped, NaN-safe.
  double get progress {
    if (totalBytes <= 0) return 0;
    final p = bytesDownloaded / totalBytes;
    if (p.isNaN || p.isNegative) return 0;
    return p.clamp(0.0, 1.0);
  }

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isInFlight =>
      status == DownloadStatus.queued ||
      status == DownloadStatus.downloading;

  /// Pretty file size — '12.4 MB', '880 KB', etc.
  String get formattedSize => _formatBytes(totalBytes);

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unit]}';
  }
}
