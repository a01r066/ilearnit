import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/download_entity.dart';

/// Persists the downloads manifest as a JSON blob inside
/// `flutter_secure_storage`. The manifest is a `Map<lectureId,
/// DownloadEntity>` serialised on every write.
///
/// Why secure storage and not SharedPreferences? Spec called for it —
/// keychain on iOS, EncryptedSharedPreferences on Android. A few hundred
/// entries comfortably fits the ~64 KB practical limit, but if you expect
/// power users with thousands of downloads, swap the backing store for a
/// real database.
class DownloadsManifestStore {
  DownloadsManifestStore(this._storage);

  final FlutterSecureStorage _storage;

  /// Single key — the whole manifest is a JSON object.
  static const String _key = 'downloads_manifest_v1';

  /// In-memory mirror of the disk state. Populated on first read; all
  /// subsequent reads / writes go through this map so we don't hit the
  /// secure-storage round-trip on every UI tick.
  Map<String, DownloadEntity>? _cache;

  Future<Map<String, DownloadEntity>> readAll() async {
    if (_cache != null) return Map.unmodifiable(_cache!);
    final raw = await _storage.read(key: _key);
    _cache = raw == null ? <String, DownloadEntity>{} : _decode(raw);
    return Map.unmodifiable(_cache!);
  }

  Future<DownloadEntity?> read(String lectureId) async {
    final all = await readAll();
    return all[lectureId];
  }

  Future<void> upsert(DownloadEntity entity) async {
    final all = await readAll();
    _cache = {...all, entity.lectureId: entity};
    await _flush();
  }

  Future<void> delete(String lectureId) async {
    final all = await readAll();
    if (!all.containsKey(lectureId)) return;
    _cache = {...all}..remove(lectureId);
    await _flush();
  }

  Future<void> clearAll() async {
    _cache = <String, DownloadEntity>{};
    await _storage.delete(key: _key);
  }

  Future<void> _flush() async {
    final cache = _cache ?? <String, DownloadEntity>{};
    final encoded = jsonEncode({
      for (final e in cache.entries) e.key: _toJson(e.value),
    });
    await _storage.write(key: _key, value: encoded);
  }

  // ---------- JSON codec ---------------------------------------------------
  //
  // freezed gives us copyWith + equality but not toJson — we want the
  // manifest format to stay readable and version-stable, so we hand-roll
  // the codec rather than wiring up `@JsonSerializable`.

  Map<String, DownloadEntity> _decode(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return <String, DownloadEntity>{};
      final out = <String, DownloadEntity>{};
      for (final entry in json.entries) {
        final v = entry.value;
        if (v is! Map) continue;
        final entity = _fromJson(Map<String, dynamic>.from(v));
        if (entity != null) out[entry.key.toString()] = entity;
      }
      return out;
    } catch (_) {
      // Corrupted blob — wipe and start fresh. Better than crashing on
      // boot for the sake of a list users can re-download.
      return <String, DownloadEntity>{};
    }
  }

  Map<String, dynamic> _toJson(DownloadEntity e) => {
        'lectureId': e.lectureId,
        'courseId': e.courseId,
        'courseTitle': e.courseTitle,
        'lectureTitle': e.lectureTitle,
        'mediaUrl': e.mediaUrl,
        'localPath': e.localPath,
        'bytesDownloaded': e.bytesDownloaded,
        'totalBytes': e.totalBytes,
        'status': e.status.name,
        'downloadedAt': e.downloadedAt?.toIso8601String(),
        'lastError': e.lastError,
      };

  DownloadEntity? _fromJson(Map<String, dynamic> json) {
    try {
      return DownloadEntity(
        lectureId: json['lectureId'] as String,
        courseId: json['courseId'] as String? ?? '',
        courseTitle: json['courseTitle'] as String? ?? '',
        lectureTitle: json['lectureTitle'] as String? ?? '',
        mediaUrl: json['mediaUrl'] as String? ?? '',
        localPath: json['localPath'] as String? ?? '',
        bytesDownloaded: json['bytesDownloaded'] as int? ?? 0,
        totalBytes: json['totalBytes'] as int? ?? 0,
        status: DownloadStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => DownloadStatus.queued,
        ),
        downloadedAt: (json['downloadedAt'] as String?) == null
            ? null
            : DateTime.tryParse(json['downloadedAt'] as String),
        lastError: json['lastError'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
