import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Identifies a lecture's Storage-hosted file: its primary media
/// ([resourceIndex] == null) or one of its `resources`.
@immutable
class LectureMediaRequest {
  const LectureMediaRequest({
    required this.courseId,
    required this.sectionId,
    required this.lectureId,
    this.resourceIndex,
  });

  final String courseId;
  final String sectionId;
  final String lectureId;
  final int? resourceIndex;

  static const _scheme = 'lecture-media';

  /// Stable pseudo-URL (`lecture-media:course/section/lecture[/index]`)
  /// persisted in the downloads manifest instead of an expiring signed
  /// URL, so a resumed download can re-resolve a fresh one. (Path-only
  /// on purpose: a URI host would be lower-cased, but Firestore ids are
  /// case-sensitive.)
  String toRef() => Uri(
        scheme: _scheme,
        pathSegments: [
          courseId,
          sectionId,
          lectureId,
          if (resourceIndex != null) '$resourceIndex',
        ],
      ).toString();

  static LectureMediaRequest? fromRef(String ref) {
    final uri = Uri.tryParse(ref);
    if (uri == null || uri.scheme != _scheme) return null;
    final seg = uri.pathSegments;
    if (seg.length < 3) return null;
    return LectureMediaRequest(
      courseId: seg[0],
      sectionId: seg[1],
      lectureId: seg[2],
      resourceIndex: seg.length > 3 ? int.tryParse(seg[3]) : null,
    );
  }

  String get _key => toRef();

  @override
  bool operator ==(Object other) =>
      other is LectureMediaRequest && other._key == _key;

  @override
  int get hashCode => _key.hashCode;
}

class LectureMediaException implements Exception {
  const LectureMediaException(this.code, this.message);
  final String code;
  final String message;

  /// Caller isn't entitled (guest / not purchased).
  bool get isLocked => code == 'permission-denied' || code == 'unauthenticated';

  @override
  String toString() => '[$code] $message';
}

/// Resolves paid lecture files to short-lived signed URLs through the
/// `resolveLectureMedia` Cloud Function (entitlement checked server-side).
/// Lecture docs only carry `gs://` references, never shareable URLs.
class LectureMediaService {
  LectureMediaService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;
  final Map<LectureMediaRequest, ({String url, DateTime until})> _cache = {};

  /// Signed URLs live 4 h server-side; refresh well before that.
  static const _ttl = Duration(minutes: 50);

  /// True when [raw] must go through [resolve] rather than be fetched
  /// directly (Storage references / Firebase download URLs).
  static bool needsResolution(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    return raw.startsWith('gs://') ||
        raw.contains('firebasestorage.googleapis.com') ||
        raw.startsWith('${LectureMediaRequest._scheme}:');
  }

  Future<String> resolve(LectureMediaRequest req) async {
    final hit = _cache[req];
    if (hit != null && DateTime.now().isBefore(hit.until)) return hit.url;
    try {
      final result = await _functions
          .httpsCallable('resolveLectureMedia')
          .call<Object?>(<String, dynamic>{
        'courseId': req.courseId,
        'sectionId': req.sectionId,
        'lectureId': req.lectureId,
        'resourceIndex': req.resourceIndex,
      });
      final data = Map<String, dynamic>.from(result.data! as Map);
      final url = data['url'] as String;
      _cache[req] = (url: url, until: DateTime.now().add(_ttl));
      return url;
    } on FirebaseFunctionsException catch (e) {
      throw LectureMediaException(e.code, e.message ?? e.code);
    }
  }

  /// Resolves a manifest ref (`lecture-media://…`) or passes plain URLs
  /// through unchanged.
  Future<String> resolveRef(String ref) {
    final req = LectureMediaRequest.fromRef(ref);
    return req == null ? Future.value(ref) : resolve(req);
  }

  void clear() => _cache.clear();
}
