import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../../../l10n/l10n.dart';

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
/// Identifies the lecture whose video should be resolved. The server
/// reads the Cloudflare UID from the lecture doc and checks entitlement,
/// so the client never asks for a raw video UID.
@immutable
class StreamPlaybackRequest {
  const StreamPlaybackRequest({
    required this.courseId,
    required this.sectionId,
    required this.lectureId,
  });

  final String courseId;
  final String sectionId;
  final String lectureId;

  String get _key => '$courseId/$sectionId/$lectureId';

  @override
  bool operator ==(Object other) =>
      other is StreamPlaybackRequest && other._key == _key;

  @override
  int get hashCode => _key.hashCode;
}

class CloudflareStreamService {
  CloudflareStreamService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  final Map<StreamPlaybackRequest, CloudflareStreamPlayback> _cache = {};

  /// Signed URLs are minted with a 4 h TTL server-side; refresh well
  /// before that so a resumed session never holds an expired token.
  static const Duration _ttl = Duration(minutes: 50);

  Future<CloudflareStreamPlayback> resolve(StreamPlaybackRequest req) async {
    final cached = _cache[req];
    if (cached != null &&
        DateTime.now().difference(cached.resolvedAt) < _ttl) {
      return cached;
    }

    try {
      final callable = _functions.httpsCallable('resolveStreamPlayback');
      final result = await callable.call<Object?>(<String, dynamic>{
        'courseId': req.courseId,
        'sectionId': req.sectionId,
        'lectureId': req.lectureId,
      });
      final data = Map<String, dynamic>.from(result.data! as Map);
      final playback = CloudflareStreamPlayback(
        hlsUrl: data['hlsUrl'] as String?,
        dashUrl: data['dashUrl'] as String?,
        thumbnailUrl: data['thumbnailUrl'] as String?,
        durationSec: (data['durationSec'] as num?)?.toInt() ?? 0,
        readyToStream: data['readyToStream'] as bool? ?? false,
        resolvedAt: DateTime.now(),
      );
      _cache[req] = playback;
      return playback;
    } on FirebaseFunctionsException catch (e) {
      throw CloudflareStreamException(
        code: e.code,
        message: L10n.current.videoUnavailable,
      );
    } catch (e) {
      throw CloudflareStreamException(
        code: 'unknown',
        message: L10n.current.videoUnavailable,
      );
    }
  }

  void invalidate(StreamPlaybackRequest req) => _cache.remove(req);

  /// Drop every cached signed URL (e.g. on sign-out / account switch).
  void clear() => _cache.clear();
}

class CloudflareStreamException implements Exception {
  CloudflareStreamException({required this.code, required this.message});
  final String code;
  final String message;

  @override
  String toString() => '[$code] $message';
}
