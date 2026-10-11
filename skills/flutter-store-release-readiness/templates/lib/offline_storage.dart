import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// App-private directories for re-downloadable content (offline media,
/// attachments).
///
/// Lives under Application Support instead of Documents:
///   • iOS — Documents is user-visible and backed up to iCloud; Apple's
///     data-storage guideline forbids putting re-downloadable media
///     there. We also flag the directory `isExcludedFromBackup` via the
///     `app/backup` channel (AppDelegate.swift).
///   • Android — excluded from Auto Backup in
///     res/xml/data_extraction_rules.xml + backup_rules.xml.
class OfflineStorage {
  OfflineStorage._();

  static const _channel = MethodChannel('app/backup');

  /// `<ApplicationSupport>/<name>`, created on demand and excluded from
  /// device backups.
  static Future<Directory> dir(String name) async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}$name');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      await _excludeFromBackup(dir.path);
    }
    return dir;
  }

  /// Pre-fix location (`<Documents>/<name>`), kept only so wipes can
  /// remove files written by older builds.
  static Future<Directory> legacyDir(String name) async {
    final root = await getApplicationDocumentsDirectory();
    return Directory('${root.path}${Platform.pathSeparator}$name');
  }

  /// Delete `<ApplicationSupport>/<name>` and the legacy
  /// `<Documents>/<legacyName ?? name>` directory.
  static Future<void> wipe(String name, {String? legacyName}) async {
    final root = await getApplicationSupportDirectory();
    for (final dir in [
      Directory('${root.path}${Platform.pathSeparator}$name'),
      await legacyDir(legacyName ?? name),
    ]) {
      try {
        if (await dir.exists()) await dir.delete(recursive: true);
      } catch (_) {}
    }
  }

  static Future<void> _excludeFromBackup(String path) async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<bool>('excludeFromBackup', path);
    } catch (e) {
      if (kDebugMode) debugPrint('[offline-storage] exclude failed: $e');
    }
  }
}
