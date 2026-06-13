import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../mini_player/data/services/mini_player_service.dart';
import '../../../mini_player/presentation/providers/mini_player_providers.dart';
import 'video_lecture_player.dart' show LecturePlaybackTick;

/// Custom audio player UI built on top of `just_audio`.
///
/// Shows a play/pause toggle, scrub bar, and elapsed/total times.
/// Designed to live above the lecture body inside [LecturePlayerPage].
///
/// Supply [initialPositionSec] + [onTick] + [onPause] to enable
/// progress persistence — same contract as `VideoLecturePlayer`.
///
/// **Player ownership.** This widget does NOT own its own
/// `AudioPlayer` anymore. It reads from the singleton
/// [MiniPlayerService] so navigating away from the lecture page
/// doesn't kill audio — the mini-player above the bottom nav stays
/// alive on the same player instance, and a tap on the mini-player
/// pushes back here at the same position.
class AudioLecturePlayer extends ConsumerStatefulWidget {
  const AudioLecturePlayer({
    super.key,
    required this.track,
    this.initialPositionSec = 0,
    this.onTick,
    this.onPause,
  });

  /// Identifies the lecture being played. Threaded through to the
  /// mini-player bar so its "tap to expand" knows how to deep-link
  /// back into this page.
  final MiniPlayerTrack track;
  final int initialPositionSec;
  final LecturePlaybackTick? onTick;
  final VoidCallback? onPause;

  @override
  ConsumerState<AudioLecturePlayer> createState() =>
      _AudioLecturePlayerState();
}

class _AudioLecturePlayerState extends ConsumerState<AudioLecturePlayer> {
  Object? _error;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  int _lastEmittedSec = -1;
  bool _wasPlaying = false;

  late final MiniPlayerService _service =
      ref.read(miniPlayerServiceProvider);
  AudioPlayer get _player => _service.player;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _service.startTrack(
        widget.track,
        initialPositionSec: widget.initialPositionSec,
      );

      // Tick on whole-second boundaries only.
      _positionSub = _player.positionStream.listen((pos) {
        if (!_player.playing) return;
        final positionSec = pos.inSeconds;
        if (positionSec == _lastEmittedSec) return;
        _lastEmittedSec = positionSec;
        final durationSec = _player.duration?.inSeconds ?? 0;
        widget.onTick?.call(positionSec, durationSec);
      });

      // Fire onPause on the playing → paused edge.
      _stateSub = _player.playerStateStream.listen((state) {
        final isPlaying = state.playing;
        if (_wasPlaying && !isPlaying) widget.onPause?.call();
        _wasPlaying = isPlaying;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    // Only cancel OUR subscriptions — the player itself is owned by
    // [MiniPlayerService] and continues running so the mini-player
    // bar can take over.
    unawaited(_positionSub?.cancel());
    unawaited(_stateSub?.cancel());
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
