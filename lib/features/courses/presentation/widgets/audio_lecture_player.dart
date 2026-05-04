import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_colors.dart';

/// Custom audio player UI built on top of `just_audio`.
///
/// Shows a play/pause toggle, scrub bar, and elapsed/total times. Designed
/// to live above the lecture body inside [LecturePlayerPage].
class AudioLecturePlayer extends StatefulWidget {
  const AudioLecturePlayer({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  State<AudioLecturePlayer> createState() => _AudioLecturePlayerState();
}

class _AudioLecturePlayerState extends State<AudioLecturePlayer> {
  final _player = AudioPlayer();
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _player.setUrl(widget.url);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Text('Could not load audio.'),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.info.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Animated waveform-ish accent
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.10),
            ),
            child: const Icon(
              Icons.headphones_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          // Position + scrubber
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, posSnap) {
              final position = posSnap.data ?? Duration.zero;
              final total = _player.duration ?? Duration.zero;
              final max = total.inMilliseconds.toDouble();
              final value = position.inMilliseconds
                  .clamp(0, max <= 0 ? 0 : max.toInt())
                  .toDouble();

              return Column(
                children: [
                  Slider(
                    value: value,
                    max: max <= 0 ? 1 : max,
                    onChanged: (v) =>
                        _player.seek(Duration(milliseconds: v.toInt())),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(position),
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(_fmt(total),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          // Transport controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded, size: 32),
                onPressed: () => _player.seek(
                  _player.position - const Duration(seconds: 10),
                ),
              ),
              const SizedBox(width: 8),
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snap) {
                  final isPlaying = snap.data?.playing ?? false;
                  final processing =
                      snap.data?.processingState ?? ProcessingState.idle;
                  if (processing == ProcessingState.loading ||
                      processing == ProcessingState.buffering) {
                    return const SizedBox(
                      width: 64,
                      height: 64,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return FloatingActionButton(
                    heroTag: 'lecture-audio-play',
                    elevation: 0,
                    onPressed: () =>
                        isPlaying ? _player.pause() : _player.play(),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 32,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.forward_30_rounded, size: 32),
                onPressed: () => _player.seek(
                  _player.position + const Duration(seconds: 30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
