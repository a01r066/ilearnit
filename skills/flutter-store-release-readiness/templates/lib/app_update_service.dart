import 'dart:io' show Platform;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../flavors.dart'; // F.isDev, F.androidPackageName

enum AppUpdateLevel { none, recommended, required }

@immutable
class AppUpdateStatus {
  const AppUpdateStatus(this.level, {this.storeUrl});
  const AppUpdateStatus.none() : this(AppUpdateLevel.none);

  final AppUpdateLevel level;

  /// Where the "Update" button goes. Null → no button (iOS without a
  /// configured `store_url_ios`).
  final String? storeUrl;
}

/// Force-update / soft-update gate driven by Firebase Remote Config.
///
/// Keys (Remote Config console, per project):
///   min_build_ios / min_build_android                — int; builds below
///       are BLOCKED until they update (e.g. after a breaking backend
///       change such as the signed-URL / server-IAP rollout)
///   recommended_build_ios / recommended_build_android — int; builds below
///       see a dismissible banner
///   store_url_ios / store_url_android                 — string; store page
///
/// Compared against the platform build number (`version: x.y.z+BUILD` in
/// pubspec.yaml). Fails open: if Remote Config can't be fetched the app
/// runs normally (last activated values or defaults).
class AppUpdateService {
  AppUpdateService({FirebaseRemoteConfig? remoteConfig})
      : _rc = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _rc;

  static const _defaults = <String, dynamic>{
    'min_build_ios': 0,
    'min_build_android': 0,
    'recommended_build_ios': 0,
    'recommended_build_android': 0,
    'store_url_ios': '',
    'store_url_android': '',
  };

  Future<AppUpdateStatus> check() async {
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) {
      return const AppUpdateStatus.none();
    }
    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval:
            F.isDev ? Duration.zero : const Duration(hours: 1),
      ));
      await _rc.setDefaults(_defaults);
      await _rc.fetchAndActivate();
    } catch (e) {
      // Offline / quota — fall back to last activated values.
      if (kDebugMode) debugPrint('[app-update] fetch failed: $e');
    }

    final info = await PackageInfo.fromPlatform();
    final build = int.tryParse(info.buildNumber) ?? 0;
    final os = Platform.isIOS ? 'ios' : 'android';
    final minBuild = _rc.getInt('min_build_$os');
    final recommended = _rc.getInt('recommended_build_$os');

    var url = _rc.getString('store_url_$os').trim();
    if (url.isEmpty && Platform.isAndroid) {
      url = 'https://play.google.com/store/apps/details?id=${F.androidPackageName}';
    }
    final storeUrl = url.isEmpty ? null : url;

    if (build < minBuild) {
      return AppUpdateStatus(AppUpdateLevel.required, storeUrl: storeUrl);
    }
    if (build < recommended) {
      return AppUpdateStatus(AppUpdateLevel.recommended, storeUrl: storeUrl);
    }
    return const AppUpdateStatus.none();
  }
}

final appUpdateServiceProvider =
    Provider<AppUpdateService>((_) => AppUpdateService());

/// Checked once per app launch.
final appUpdateStatusProvider = FutureProvider<AppUpdateStatus>(
  (ref) => ref.watch(appUpdateServiceProvider).check(),
);
