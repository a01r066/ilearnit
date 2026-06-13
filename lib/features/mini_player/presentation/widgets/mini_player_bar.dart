import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/routing/route_names.dart';
import '../../data/services/mini_player_service.dart';
import '../providers/mini_player_providers.dart';

// `go_router` import retained for `context.pushNamed` in `_expand`.

/// Persistent mini-player rendered above the bottom nav by
/// `ShellScaffold`. Self-hides when:
///   • no track is loaded, or
///   • the user is currently on the full-screen lecture player
///     (`/courses/:id/lectures/:lectureId`) — the in-page UI is
///     enough, the mini bar would be redundant.
///
/// Layout matches the user's screenshot reference:
///
///   ┌────────────────────────────────────────────────┐
///   │ ┌──────────┐  ⏪ 15s   ▶︎/⏸  15s ⏩  🎧  ✕   │
///   │ │ thumb    │                                   │
///   │ │ 80×56    │                                   │
///   │ └──────────┘                                   │
///   │  50  Let it Be — Tutorial — Part 1             │
///   │      Fingerstyle Guitar For Beginners | …      │
///   └────────────────────────────────────────────────┘
///
/// Video lectures render a live `VideoPlayer` widget in the thumbnail
/// slot — the controller is shared with the full-screen Chewie player
/// via [MiniPlayerService.videoController], so the same frames keep
/// rendering as the user navigates between pages. Audio lectures fall
/// back to a static thumbnail image.
///
/// The headphones icon is a placeholder for the "play audio-only
/// (continue while screen is locked)" toggle — wired off for v1.
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(miniPlayerStateProvider).value;
    if (state == null || !state.hasTrack) return const SizedBox.shrink();

    // Driven by `LecturePlayerPage.initState/dispose`. We can't rely on
    // `GoRouterState.of(context).matchedLocation` here because this
    // widget lives in the shell scaffold and the lecture page is
    // nested *inside* a shell branch (no parentNavigatorKey: rootKey)
    // — the shell's context reports the shell's route, not the deep
    // lecture path, so the string check would always miss.
    final hidden = ref.watch(miniPlayerHiddenDepthProvider) > 0;
    if (hidden) return const SizedBox.shrink();

    return _Bar(state: state);
  }
}

class _Bar extends ConsumerWidget {
  const _Bar({required this.state});
  final MiniPlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final track = state.track!;
    final svc = ref.read(miniPlayerServiceProvider);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin progress strip across the top.
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: state.fraction,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
              ),
            ),

            // ── Row 1: thumbnail + transport controls ────────────
            InkWell(
              onTap: () => _expand(context, track),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
                child: Row(
                  children: [
                    _Thumb(
                      url: track.thumbnailUrl,
                      videoController:
                          state.isVideo ? ref.read(miniPlayerServiceProvider).videoController : null,
                    ),
                    const SizedBox(width: 8),
                    // Transport controls — pushed right so the thumb
                    // occupies the marquee position on the left.
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Back 15 s',
                            icon: const Icon(Icons.replay_10),
                            onPressed: () =>
                                svc.seekBy(const Duration(seconds: -15)),
                          ),
                          IconButton(
                            tooltip: state.isPlaying ? 'Pause' : 'Play',
                            iconSize: 32,
                            icon: Icon(
                              state.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                            ),
                            color: theme.colorScheme.primary,
                            onPressed: () => state.isPlaying
                                ? svc.pause()
                                : svc.play(),
                          ),
                          IconButton(
                            tooltip: 'Forward 15 s',
                            icon: const Icon(Icons.forward_10),
                            onPressed: () =>
                                svc.seekBy(const Duration(seconds: 15)),
                          ),
                          // Headphones — placeholder for the future
                          // "audio-only mode" toggle. v1: no-op with
                          // an informative tooltip so the affordance
                          // is at least documented in the UI.
                          IconButton(
                            tooltip:
                                'Audio-only mode (coming soon)',
                            icon: const Icon(Icons.headphones),
                            onPressed: null,
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            onPressed: svc.close,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Row 2: lecture caption (lecture # · title) ───────
            InkWell(
              onTap: () => _expand(context, track),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (track.lectureNumber != null) ...[
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${track.lectureNumber}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (track.courseTitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              track.courseTitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _expand(BuildContext context, MiniPlayerTrack track) {
    context.pushNamed(
      RouteNames.lecturePlayer,
      pathParameters: {
        'id': track.courseId,
        'lectureId': track.lectureId,
      },
      queryParameters: {'sectionId': track.sectionId},
    );
  }
}

/// 80×56 (4:3-ish) "video frame" thumbnail.
///
/// Renders one of three things, in priority order:
///   1. The live shared `VideoPlayerController` — picture-in-picture
///      style: actual video frames continue playing inside the bar.
///   2. The course's static thumbnail image (cached, network).
///   3. A play-circle placeholder when neither is available.
class _Thumb extends StatelessWidget {
  const _Thumb({this.url, this.videoController});
  final String? url;
  final VideoPlayerController? videoController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 80,
        height: 56,
        child: _content(theme),
      ),
    );
  }

  Widget _content(ThemeData theme) {
    final ctrl = videoController;
    if (ctrl != null && ctrl.value.isInitialized) {
      // Live video frames. AspectRatio prevents the native texture
      // from stretching when the source isn't 4:3.
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: AspectRatio(
          aspectRatio: ctrl.value.aspectRatio == 0
              ? 16 / 9
              : ctrl.value.aspectRatio,
          child: VideoPlayer(ctrl),
        ),
      );
    }
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        errorWidget: (_, __, ___) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(Icons.play_circle_outline,
              size: 22, color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.play_circle_outline,
          size: 22, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
