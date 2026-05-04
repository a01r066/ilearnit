import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Wraps `video_player` + `chewie` so the lecture player just gives a URL.
///
/// Disposes both controllers on widget removal — leaks here would keep the
/// audio decoder alive between routes.
class VideoLecturePlayer extends StatefulWidget {
  const VideoLecturePlayer({super.key, required this.url});
  final String url;

  @override
  State<VideoLecturePlayer> createState() => _VideoLecturePlayerState();
}

class _VideoLecturePlayerState extends State<VideoLecturePlayer> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  Object? _error;

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

  @override
  void dispose() {
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
