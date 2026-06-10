import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Cached resolution of one Cloudflare Stream video.
@immutable
class CloudflareStreamPlayback {
  const CloudflareStreamPlayback({
    required this.hlsUrl,
    required this.dashUrl,
    required this.thumbnailUrl,
    required this.durationSec,
    required this.readyToStream,
    required this.resolvedAt,
  });

  final String? hlsUrl;
  final String? dashUrl;
  final String? thumbnailUrl;
  final int durationSec;
  final bool readyToStream;
  final DateTime resolvedAt;

  /// Picks the URL the platform player should use. HLS works on all
  /// targets we care about (iOS native, Android via ExoPlayer); DASH
  /// is a fallback if HLS is unavailable.
  String? get bestUrl => hlsUrl ?? dashUrl;
}

/// Talks to the `resolveStreamPlayback` Cloud Function.
///
/// Why a Cloud Function and not a direct API call?
///   • The Cloudflare API token has account-wide write access. It
///     must never ship in the client binary.
///   • Routing through a callable Cloud Function lets us
///     authenticate the caller (the function rejects unsigned
///     requests) so we don't leak the catalogue's video UIDs to the
///     open internet.
class CloudflareStreamService {
  CloudflareStreamService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// In-memory cache. Cloudflare HLS URLs are stable until the video
  /// is re-uploaded or signed-URL policy flips, so we keep them for
  /// the lifetime of the app process. Background app launches re-fetch
  /// because the service is a singleton tied to the Riverpod container.
  final Map<String, CloudflareStreamPlayback> _cache = {};

  /// Cache TTL — after this we re-resolve even if the cache has an
  /// entry. Set to 50 minutes because Cloudflare's default signed-URL
  /// TTL is 60 minutes; staying under it gives us a safety margin.
  static const Duration _ttl = Duration(minutes: 50);

  /// Resolve a UID. Throws a [CloudflareStreamException] on failure so
  /// the player can show a friendly error widget.
  Future<CloudflareStreamPlayback> resolve(String videoId) async {
    final cached = _cache[videoId];
    if (cached != null &&
        DateTime.now().difference(cached.resolvedAt) < _ttl) {
      return cached;
    }

    try {
      final callable =
          _functions.httpsCallable('resolveStreamPlayback');
      final result = await callable.call<Map<String, dynamic>>(
        {'videoId': videoId},
      );
      final data = result.data;
      final playback = CloudflareStreamPlayback(
        hlsUrl: data['hlsUrl'] as String?,
        dashUrl: data['dashUrl'] as String?,
        thumbnailUrl: data['thumbnailUrl'] as String?,
        durationSec: (data['durationSec'] as num?)?.toInt() ?? 0,
        readyToStream: data['readyToStream'] as bool? ?? false,
        resolvedAt: DateTime.now(),
      );
      _cache[videoId] = playback;
      return playback;
    } on FirebaseFunctionsException catch (e) {
      throw CloudflareStreamException(
        code: e.code,
        message: e.message ?? 'Unknown Cloudflare error',
      );
    } catch (e) {
      throw CloudflareStreamException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  /// Manual invalidation — call after replacing a video's media.
  void invalidate(String videoId) => _cache.remove(videoId);
}

class CloudflareStreamException implements Exception {
  CloudflareStreamException({required this.code, required this.message});
  final String code;
  final String message;

  @override
  String toString() => '[$code] $message';
}
