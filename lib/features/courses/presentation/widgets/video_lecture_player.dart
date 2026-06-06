import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Signature for the per-second tick the player emits while playing.
/// Driven by a periodic listener on the [VideoPlayerController].
typedef LecturePlaybackTick = void Function(
  int positionSec,
  int durationSec,
);

/// Wraps `video_player` + `chewie` so the lecture player just gives a URL.
///
/// Disposes both controllers on widget removal — leaks here would keep the
/// audio decoder alive between routes.
///
/// To enable progress persistence, supply:
///   • [initialPositionSec] — seeks before the user hits play, so the
///     lecture resumes where they left off.
///   • [onTick]              — fired every second while playback advances.
///   • [onPause]             — fired when the user hits pause, lets the
///     progress notifier flush immediately.
class VideoLecturePlayer extends StatefulWidget {
  const VideoLecturePlayer({
    super.key,
    required this.url,
    this.initialPositionSec = 0,
    this.onTick,
    this.onPause,
  });

  final String url;
  final int initialPositionSec;
  final LecturePlaybackTick? onTick;
  final VoidCallback? onPause;

  @override
  State<VideoLecturePlayer> createState() => _VideoLecturePlayerState();
}

class _VideoLecturePlayerState extends State<VideoLecturePlayer> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  Object? _error;

  // Track the last emitted second so we only fire `onTick` on whole-second
  // boundaries. Without this the player would call the callback on every
  // VideoPlayerValue change (≈30 fps for some codecs).
  int _lastEmittedSec = -1;

  // Track whether the last frame was playing so we can fire `onPause`
  // only on the playing → paused edge.
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final video = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await video.initialize();
      if (!mounted) {
        await video.dispose();
        return;
      }
      if (widget.initialPositionSec > 0) {
        await video.seekTo(Duration(seconds: widget.initialPositionSec));
      }
      video.addListener(_onVideoEvent);

      final chewie = ChewieController(
        videoPlayerController: video,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
        ),
      );
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

    // Only emit ticks while playback is advancing.
    if (!isPlaying) return;
    final positionSec = value.position.inSeconds;
    if (positionSec == _lastEmittedSec) return;
    _lastEmittedSec = positionSec;
    final durationSec = value.duration.inSeconds;
    widget.onTick?.call(positionSec, durationSec);
  }

  @override
  void dispose() {
    _video?.removeListener(_onVideoEvent);
    _chewie?.dispose();
    _video?.dispose();
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
