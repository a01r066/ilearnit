/// In-memory registry of the current playback position for each
/// lecture that's actively playing. The Notes "Add" button reads
/// this so it can pre-fill the timestamp on the new-note sheet
/// without coupling to the progress notifier's throttled state.
///
/// Why a registry instead of a Riverpod state notifier?
///   • The position changes every second; observing it from Riverpod
///     would rebuild every consumer (Q&A list, downloads tile, …)
///     unnecessarily.
///   • The "Add note" tap is rare — we only need to *poll* the
///     position at tap time, not subscribe to it.
class PlaybackPositionRegistry {
  PlaybackPositionRegistry();

  final Map<String, int> _positions = {};

  /// Set the position for [lectureId]. Called from the video / audio
  /// player on every `onTick`.
  void put(String lectureId, int positionSec) {
    _positions[lectureId] = positionSec;
  }

  /// Read the most recently seen position for [lectureId]. Returns
  /// `null` if the player hasn't ticked yet (cold open of the player
  /// page).
  int? get(String lectureId) => _positions[lectureId];

  /// Drop the entry when the player is disposed so a stale position
  /// from a previous viewing doesn't leak into a fresh note.
  void clear(String lectureId) {
    _positions.remove(lectureId);
  }
}
