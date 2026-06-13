import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

/// Differentiates audio-only lectures from video lectures so the
/// singleton player picks the right engine. Audio lectures still use
/// `just_audio` (cheap, no decoder warm-up). Video lectures use
/// `video_player` so the mini-bar can render live video frames.
enum MiniPlayerKind { audio, video }

/// Identifies the lecture currently loaded into the global player.
///
/// [courseTitle] + [lectureNumber] are denormalized so the mini-player
/// bar can render the screenshot-style 2-line caption ("50 · Let it
/// Be — Tutorial — Part 1" over "Fingerstyle Guitar For Beginners")
/// without an extra Firestore read on every state tick.
class MiniPlayerTrack {
  const MiniPlayerTrack({
    required this.courseId,
    required this.sectionId,
    required this.lectureId,
    required this.title,
    required this.url,
    this.kind = MiniPlayerKind.audio,
    this.thumbnailUrl,
    this.courseTitle,
    this.lectureNumber,
  });

  final String courseId;
  final String sectionId;
  final String lectureId;
  final String title;
  final String url;
  final MiniPlayerKind kind;
  final String? thumbnailUrl;
  final String? courseTitle;
  final int? lectureNumber;
}

/// Snapshot of the global player, emitted to every UI surface (the
/// in-page `AudioLecturePlayer` / `VideoLecturePlayer` AND the
/// persistent `MiniPlayerBar` above the bottom nav).
class MiniPlayerState {
  const MiniPlayerState({
    this.track,
    this.position = Duration.zero,
    this.duration,
    this.isPlaying = false,
    this.error,
  });

  final MiniPlayerTrack? track;
  final Duration position;
  final Duration? duration;
  final bool isPlaying;
  final Object? error;

  bool get hasTrack => track != null;
  bool get isVideo => track?.kind == MiniPlayerKind.video;
  double get fraction {
    final d = duration?.inMilliseconds ?? 0;
    if (d <= 0) return 0;
    return (position.inMilliseconds / d).clamp(0.0, 1.0).toDouble();
  }

  MiniPlayerState copyWith({
    Object? track = _unset,
    Duration? position,
    Object? duration = _unset,
    bool? isPlaying,
    Object? error = _unset,
  }) {
    return MiniPlayerState(
      track: identical(track, _unset) ? this.track : track as MiniPlayerTrack?,
      position: position ?? this.position,
      duration:
          identical(duration, _unset) ? this.duration : duration as Duration?,
      isPlaying: isPlaying ?? this.isPlaying,
      error: identical(error, _unset) ? this.error : error,
    );
  }

  static const Object _unset = Object();
}

/// Singleton media player. Lives for the entire app lifetime so a
/// track started on the lecture page keeps playing when the user
/// navigates back to Home / Courses / Profile.
///
/// **Architecture.** Two engines, lazily allocated:
///
///   • `AudioPlayer` (just_audio) — used when the current track's
///     [MiniPlayerTrack.kind] is [MiniPlayerKind.audio]. Cheaper warm
///     up than the video pipeline; ideal for podcast-style lectures.
///   • `VideoPlayerController` (video_player) — used when the kind is
///     [MiniPlayerKind.video]. Shared across the full-screen Chewie
///     player AND the `MiniPlayerBar` so the bar can render real video
///     frames via a `VideoPlayer` widget. Both surfaces stay in
///     lockstep because there's only ever one controller.
///
/// Switching between audio and video tracks tears down the old engine
/// and spins up the new one. State subscribers see a brief
/// `isPlaying: false` blip while the new media loads.
///
/// **iOS background audio.** Add to `ios/Runner/Info.plist`:
///
/// ```xml
/// <key>UIBackgroundModes</key>
/// <array><string>audio</string></array>
/// ```
///
/// That lets audio continue while the screen is locked AND while the
/// app is backgrounded. Video on iOS will pause when the app goes to
/// the background (system-enforced — no public API to keep video
/// rendering off-screen). For true Spotify-style lock-screen controls
/// (notification with play/pause + headphone media keys), upgrade to
/// the `audio_service` package — that's a v2 step requiring an
/// AndroidManifest service entry and an `AudioHandler` subclass.
class MiniPlayerService {
  MiniPlayerService() {
    // Audio engine is always allocated up-front so synchronous reads
    // from `AudioLecturePlayer` work on its first build pass. Video
    // engine is lazy because the controller takes ~hundreds of ms to
    // initialize and most cold-launch flows never hit a video track.
    _wireAudioStreams();
  }

  // ── Audio engine ────────────────────────────────────────────────
  final AudioPlayer _audio = AudioPlayer();
  StreamSubscription<Duration>? _audioPositionSub;
  StreamSubscription<PlayerState>? _audioStateSub;
  StreamSubscription<Duration?>? _audioDurationSub;

  // ── Video engine ────────────────────────────────────────────────
  VideoPlayerController? _video;
  VoidCallback? _videoListener;

  // ── Shared state ────────────────────────────────────────────────
  final _controller = StreamController<MiniPlayerState>.broadcast();
  MiniPlayerState _state = const MiniPlayerState();

  // ── Public surface ─────────────────────────────────────────────

  Stream<MiniPlayerState> get stateStream => _controller.stream;
  MiniPlayerState get currentState => _state;

  /// Direct access for `AudioLecturePlayer` so its scrub bar can read
  /// `positionStream` natively for smooth animation.
  AudioPlayer get audioPlayer => _audio;

  /// Backwards-compat alias. Same instance as [audioPlayer]; old call
  /// sites that read `service.player` still work.
  AudioPlayer get player => _audio;

  /// Direct access to the shared video controller. Used by both the
  /// full-screen `VideoLecturePlayer` (wrapped in Chewie for UI chrome)
  /// AND the `MiniPlayerBar` (raw `VideoPlayer` widget rendering live
  /// frames). Returns null when no video is loaded.
  VideoPlayerController? get videoController => _video;

  /// Load a new track and start playing. If the same track is already
  /// loaded, just `play()` instead of reloading (avoids the media
  /// drop-out on a back-and-forth navigation pattern).
  Future<void> startTrack(
    MiniPlayerTrack track, {
    int initialPositionSec = 0,
  }) async {
    final same = _state.track?.lectureId == track.lectureId &&
        _state.track?.url == track.url &&
        _state.track?.kind == track.kind;
    if (same) {
      await play();
      return;
    }

    // Switching kinds → tear down the engine we *aren't* about to use.
    // Audio engine is permanent (allocated in the ctor); we only stop
    // it. Video engine is disposed entirely so we don't leak the
    // platform texture.
    if (track.kind == MiniPlayerKind.video) {
      try {
        await _audio.stop();
      } catch (_) {}
    } else {
      await _disposeVideo();
    }

    _emit(_state.copyWith(
      track: track,
      position: Duration.zero,
      duration: null,
      isPlaying: false,
      error: null,
    ));

    try {
      if (track.kind == MiniPlayerKind.video) {
        await _startVideo(track, initialPositionSec);
      } else {
        await _startAudio(track, initialPositionSec);
      }
    } catch (e) {
      _emit(_state.copyWith(error: e));
    }
  }

  Future<void> play() async {
    try {
      if (_video != null) {
        await _video!.play();
      } else {
        await _audio.play();
      }
    } catch (e) {
      _emit(_state.copyWith(error: e));
    }
  }

  Future<void> pause() async {
    try {
      if (_video != null) {
        await _video!.pause();
      } else {
        await _audio.pause();
      }
    } catch (e) {
      _emit(_state.copyWith(error: e));
    }
  }

  Future<void> seekBy(Duration delta) async {
    final next = _state.position + delta;
    await seekTo(Duration(
      milliseconds: next.inMilliseconds.clamp(
        0,
        _state.duration?.inMilliseconds ?? next.inMilliseconds,
      ),
    ));
  }

  Future<void> seekTo(Duration position) async {
    try {
      if (_video != null) {
        await _video!.seekTo(position);
      } else {
        await _audio.seek(position);
      }
    } catch (e) {
      _emit(_state.copyWith(error: e));
    }
  }

  /// Stop + clear the loaded track. The mini-player bar will self-hide
  /// on the next state emit.
  Future<void> close() async {
    try {
      await _audio.stop();
    } catch (_) {}
    await _disposeVideo();
    _emit(const MiniPlayerState());
  }

  // ── Audio internals ────────────────────────────────────────────

  void _wireAudioStreams() {
    _audioPositionSub = _audio.positionStream.listen((pos) {
      if (_video != null) return; // video active — ignore stale audio ticks
      _emit(_state.copyWith(position: pos));
    });
    _audioDurationSub = _audio.durationStream.listen((dur) {
      if (_video != null) return;
      _emit(_state.copyWith(duration: dur));
    });
    _audioStateSub = _audio.playerStateStream.listen((s) {
      if (_video != null) return;
      _emit(_state.copyWith(isPlaying: s.playing));
    });
  }

  Future<void> _startAudio(MiniPlayerTrack track, int startSec) async {
    await _audio.setUrl(track.url);
    if (startSec > 0) await _audio.seek(Duration(seconds: startSec));
    await _audio.play();
  }

  // ── Video internals ────────────────────────────────────────────

  Future<void> _startVideo(MiniPlayerTrack track, int startSec) async {
    final uri = Uri.parse(track.url);
    final controller = uri.scheme == 'file'
        ? VideoPlayerController.file(File(uri.toFilePath()))
        : VideoPlayerController.networkUrl(uri);
    _video = controller;
    await controller.initialize();
    if (startSec > 0) {
      await controller.seekTo(Duration(seconds: startSec));
    }
    void listener() {
      final v = controller.value;
      _emit(_state.copyWith(
        position: v.position,
        duration: v.duration,
        isPlaying: v.isPlaying,
      ));
    }
    _videoListener = listener;
    controller.addListener(listener);
    // Emit the post-init snapshot once so subscribers see a duration
    // even before the first internal tick.
    listener();
    await controller.play();
  }

  // ── Teardown ───────────────────────────────────────────────────

  Future<void> _disposeVideo() async {
    final listener = _videoListener;
    if (listener != null) {
      _video?.removeListener(listener);
      _videoListener = null;
    }
    try {
      await _video?.pause();
    } catch (_) {/* ignore — tearing down */}
    await _video?.dispose();
    _video = null;
  }

  void _emit(MiniPlayerState next) {
    _state = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  Future<void> dispose() async {
    await _audioPositionSub?.cancel();
    await _audioDurationSub?.cancel();
    await _audioStateSub?.cancel();
    try {
      await _audio.stop();
    } catch (_) {}
    await _audio.dispose();
    await _disposeVideo();
    await _controller.close();
  }
}
