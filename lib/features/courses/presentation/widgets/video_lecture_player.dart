import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../mini_player/data/services/mini_player_service.dart';
import '../../../mini_player/presentation/providers/mini_player_providers.dart';

/// Signature for the per-second tick the player emits while playing.
/// Driven by a listener on the shared [VideoPlayerController] owned by
/// [MiniPlayerService].
typedef LecturePlaybackTick = void Function(
  int positionSec,
  int durationSec,
);

/// In-page video player UI. Wraps the singleton
/// [MiniPlayerService.videoController] in a Chewie chrome (play/pause,
/// scrubber, fullscreen toggle) and forwards per-second ticks for
/// progress persistence.
///
/// **Controller ownership.** This widget does NOT own a
/// `VideoPlayerController`. The service owns it so the user can
/// navigate away from the lecture page and continue watching in the
/// mini-bar above the bottom nav. We construct a `ChewieController`
/// here (it's just UI chrome) and dispose only that on widget removal.
///
/// To enable progress persistence, supply:
///   • [initialPositionSec] — seeks before the user hits play, so the
///     lecture resumes where they left off.
///   • [onTick]              — fired every second while playback advances.
///   • [onPause]             — fired when the user hits pause, lets the
///     progress notifier flush immediately.
class VideoLecturePlayer extends ConsumerStatefulWidget {
  const VideoLecturePlayer({
    super.key,
    required this.track,
    this.initialPositionSec = 0,
    this.onTick,
    this.onPause,
  });

  /// Identifies the lecture being played (URL + course/section/lecture
  /// ids + denormalized title for the mini-bar caption). Handed to the
  /// singleton service which owns the actual [VideoPlayerController].
  final MiniPlayerTrack track;
  final int initialPositionSec;
  final LecturePlaybackTick? onTick;
  final VoidCallback? onPause;

  @override
  ConsumerState<VideoLecturePlayer> createState() =>
      _VideoLecturePlayerState();
}

class _VideoLecturePlayerState extends ConsumerState<VideoLecturePlayer> {
  ChewieController? _chewie;
  VideoPlayerController? _video;
  Object? _error;

  int _lastEmittedSec = -1;
  bool _wasPlaying = false;

  late final MiniPlayerService _service =
      ref.read(miniPlayerServiceProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Hands the URL to the singleton — service decides whether to
      // reuse an already-initialized controller (user tapped the mini
      // bar to expand) or spin up a new one.
      await _service.startTrack(
        widget.track,
        initialPositionSec: widget.initialPositionSec,
      );

      final video = _service.videoController;
      if (video == null || !mounted) return;

      final chewie = ChewieController(
        videoPlayerController: video,
        autoPlay: false, // service has already called play()
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
        ),
      );

      video.addListener(_onVideoEvent);

      setState(() {
        _video = video;
        _chewie = chewie;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _onVideoEvent() {
    final v = _video;
    if (v == null || !v.value.isInitialized) return;
    final value = v.value;
    final isPlaying = value.isPlaying;

    // Detect playing → paused edge.
    if (_wasPlaying && !isPlaying) {
      widget.onPause?.call();
    }
    _wasPlaying = isPlaying;

    if (!isPlaying) return;
    final positionSec = value.position.inSeconds;
    if (positionSec == _lastEmittedSec) return;
    _lastEmittedSec = positionSec;
    final durationSec = value.duration.inSeconds;
    widget.onTick?.call(positionSec, durationSec);
  }

  @override
  void dispose() {
    // Only tear down OUR Chewie UI chrome. The [VideoPlayerController]
    // itself is owned by [MiniPlayerService] and continues running so
    // the mini-player bar above the bottom nav can take over.
    _video?.removeListener(_onVideoEvent);
    _chewie?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Could not load video.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    final chewie = _chewie;
    if (chewie == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return Chewie(controller: chewie);
  }
}
