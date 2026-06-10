import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilearnit/features/courses/presentation/providers/course_detail_state.dart';
import 'package:ilearnit/features/courses/presentation/providers/curriculum_state.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../downloads/presentation/providers/downloads_providers.dart';
import '../../../downloads/presentation/widgets/lecture_download_button.dart';
import '../../../progress/data/datasources/lecture_progress_datasource.dart';
import '../../../progress/data/models/lecture_progress_model.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../notes/presentation/widgets/lecture_notes_section.dart';
import '../../../qa/presentation/widgets/lecture_qa_section.dart';
import '../../domain/entities/course_section_entity.dart';
import '../../domain/entities/lecture_entity.dart';
import '../../domain/entities/lecture_type.dart';
import '../providers/courses_providers.dart';
import '../widgets/audio_lecture_player.dart';
import '../widgets/document_lecture_view.dart';
import '../widgets/video_lecture_player.dart';

/// Single page that handles all four lecture types (video / audio / pdf / doc).
///
/// Loads the curriculum to find the lecture by id (entry point only knows
/// `courseId` + `lectureId` from the route), then dispatches to the right
/// player widget.
///
/// Progress tracking — for video + audio lectures only:
///   • Registers a `CourseMetaSnapshot` with the progress provider so the
///     notifier can write denormalized course title / cover / lecture count
///     on every flush.
///   • Loads the user's saved play-head from
///     `users/{uid}/courseProgress/{courseId}/lectures/{lectureId}` once
///     and feeds it back to the player as `initialPositionSec`.
///   • Forwards player ticks and pause events to the notifier.
class LecturePlayerPage extends ConsumerWidget {
  const LecturePlayerPage({
    super.key,
    required this.courseId,
    required this.lectureId,
    this.initialPositionSec,
  });

  final String courseId;
  final String lectureId;

  /// Optional jump-to override. When the page is opened with
  /// `?at=N` (e.g. tapping a note's timestamp from the standalone
  /// "My notes" page), the player seeks to N seconds on load instead
  /// of resuming from the saved progress position.
  final int? initialPositionSec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(curriculumNotifierProvider(courseId));
    final notifier = ref.read(curriculumNotifierProvider(courseId).notifier);
    final courseDetail = ref.watch(courseDetailNotifierProvider(courseId));

    return state.when(
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (failure) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: failure.displayMessage,
          onRetry: notifier.load,
        ),
      ),
      loaded: (sections) {
        final lecture = _findLecture(sections, lectureId);
        if (lecture == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Lecture not found.')),
          );
        }
        final sectionId = _findSectionId(sections, lectureId);
        final totalLectures = _countLectures(sections);
        final courseTitle =
            courseDetail.maybeWhen(loaded: (c) => c.title, orElse: () => '');
        final thumbnailUrl = courseDetail.maybeWhen(
          loaded: (c) => c.thumbnailUrl,
          orElse: () => null,
        );

        // Register the latest course meta so the notifier can attach it to
        // every flush without re-reading Firestore.
        ref.read(progressMetaRegistryProvider).put(
              courseId,
              CourseMetaSnapshot(
                title: courseTitle,
                thumbnailUrl: thumbnailUrl,
                totalLectures: totalLectures,
                sectionId: sectionId,
              ),
            );

        return _LecturePlayerScaffold(
          courseId: courseId,
          sectionId: sectionId ?? '',
          lecture: lecture,
          initialPositionSec: initialPositionSec,
          courseTitle: courseTitle,
          courseThumbnailUrl: thumbnailUrl,
        );
      },
    );
  }

  static LectureEntity? _findLecture(
    List<CourseSectionEntity> sections,
    String id,
  ) {
    for (final s in sections) {
      for (final l in s.lectures) {
        if (l.id == id) return l;
      }
    }
    return null;
  }

  static String? _findSectionId(
    List<CourseSectionEntity> sections,
    String lectureId,
  ) {
    for (final s in sections) {
      for (final l in s.lectures) {
        if (l.id == lectureId) return s.id;
      }
    }
    return null;
  }

  static int _countLectures(List<CourseSectionEntity> sections) {
    var total = 0;
    for (final s in sections) {
      total += s.lectures.length;
    }
    return total;
  }
}

class _LecturePlayerScaffold extends ConsumerWidget {
  const _LecturePlayerScaffold({
    required this.courseId,
    required this.sectionId,
    required this.lecture,
    required this.courseTitle,
    required this.courseThumbnailUrl,
    this.initialPositionSec,
  });

  final String courseId;
  final String sectionId;
  final LectureEntity lecture;
  final String courseTitle;
  final String? courseThumbnailUrl;
  final int? initialPositionSec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lecture.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    switch (lecture.type) {
      case LectureType.video:
        return _VideoBody(
          courseId: courseId,
          sectionId: sectionId,
          lecture: lecture,
          courseTitle: courseTitle,
          courseThumbnailUrl: courseThumbnailUrl,
          initialPositionOverrideSec: initialPositionSec,
        );
      case LectureType.audio:
        return _AudioBody(
          courseId: courseId,
          sectionId: sectionId,
          lecture: lecture,
          courseTitle: courseTitle,
          courseThumbnailUrl: courseThumbnailUrl,
          initialPositionOverrideSec: initialPositionSec,
        );
      case LectureType.pdf:
      case LectureType.doc:
        return DocumentLectureView(lecture: lecture);
    }
  }
}

class _VideoBody extends ConsumerWidget {
  const _VideoBody({
    required this.courseId,
    required this.sectionId,
    required this.lecture,
    required this.courseTitle,
    required this.courseThumbnailUrl,
    this.initialPositionOverrideSec,
  });
  final String courseId;
  final String sectionId;
  final LectureEntity lecture;
  final String courseTitle;
  final String? courseThumbnailUrl;
  final int? initialPositionOverrideSec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMedia = (lecture.mediaUrl?.isNotEmpty ?? false) ||
        (lecture.cloudflareVideoId?.isNotEmpty ?? false);
    if (!hasMedia) {
      return const Center(child: Text('Video unavailable.'));
    }
    final key =
        LectureProgressKey(courseId: courseId, lectureId: lecture.id);
    final notifier = ref.read(lectureProgressNotifierProvider(key).notifier);
    final saved = ref
        .watch(lectureProgressByCourseProvider(courseId))
        .maybeWhen(data: (rows) => _findRow(rows, lecture.id), orElse: () => null);

    // Resolution order:
    //   1. Local download (offline support) — Firebase Storage source.
    //   2. Cloudflare Stream HLS via Cloud Function (preferred for prod).
    //   3. Direct mediaUrl from Firebase Storage (legacy fallback).
    final localPath =
        ref.watch(localMediaPathForLectureProvider(lecture.id));

    final positions = ref.read(playbackPositionRegistryProvider);
    final cfId = lecture.cloudflareVideoId;

    Widget buildPlayer(String url) => AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoLecturePlayer(
            url: url,
            initialPositionSec:
                initialPositionOverrideSec ?? saved?.positionSec ?? 0,
            onTick: (pos, dur) {
              notifier.onTick(positionSec: pos, durationSec: dur);
              positions.put(lecture.id, pos);
            },
            onPause: () => notifier.flush(),
          ),
        );

    Widget videoSlot;
    if (localPath != null) {
      // Offline / pre-downloaded — fastest path, skip resolution.
      videoSlot = buildPlayer(Uri.file(localPath).toString());
    } else if (cfId != null && cfId.isNotEmpty) {
      // Cloudflare Stream — resolve via Cloud Function, then play HLS.
      final playbackAsync =
          ref.watch(cloudflareStreamPlaybackProvider(cfId));
      videoSlot = playbackAsync.when(
        loading: () => const AspectRatio(
          aspectRatio: 16 / 9,
          child:
              ColoredBox(color: Colors.black, child: Center(child:
                  CircularProgressIndicator(color: Colors.white))),
        ),
        error: (e, _) => AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(
            color: Colors.black,
            child: Center(
              child: Text(
                'Video unavailable: $e',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        data: (p) {
          final url = p.bestUrl;
          if (url == null || !p.readyToStream) {
            return const AspectRatio(
              aspectRatio: 16 / 9,
              child: ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Text(
                    'Video still encoding — try again in a minute.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          }
          return buildPlayer(url);
        },
      );
    } else {
      // Legacy Firebase Storage URL.
      videoSlot = buildPlayer(lecture.mediaUrl!);
    }

    return Column(
      children: [
        videoSlot,
        Expanded(
          child: _LectureBody(
            lecture: lecture,
            courseId: courseId,
            sectionId: sectionId,
            courseTitle: courseTitle,
            courseThumbnailUrl: courseThumbnailUrl,
          ),
        ),
      ],
    );
  }
}

class _AudioBody extends ConsumerWidget {
  const _AudioBody({
    required this.courseId,
    required this.sectionId,
    required this.lecture,
    required this.courseTitle,
    required this.courseThumbnailUrl,
    this.initialPositionOverrideSec,
  });
  final String courseId;
  final String sectionId;
  final LectureEntity lecture;
  final String courseTitle;
  final String? courseThumbnailUrl;
  final int? initialPositionOverrideSec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lecture.mediaUrl == null || lecture.mediaUrl!.isEmpty) {
      return const Center(child: Text('Audio unavailable.'));
    }
    final key =
        LectureProgressKey(courseId: courseId, lectureId: lecture.id);
    final notifier = ref.read(lectureProgressNotifierProvider(key).notifier);
    final saved = ref
        .watch(lectureProgressByCourseProvider(courseId))
        .maybeWhen(data: (rows) => _findRow(rows, lecture.id), orElse: () => null);

    final localPath =
        ref.watch(localMediaPathForLectureProvider(lecture.id));
    final url = localPath != null
        ? Uri.file(localPath).toString()
        : lecture.mediaUrl!;

    final positions = ref.read(playbackPositionRegistryProvider);

    return Column(
      children: [
        AudioLecturePlayer(
          url: url,
          title: lecture.title,
          initialPositionSec:
              initialPositionOverrideSec ?? saved?.positionSec ?? 0,
          onTick: (pos, dur) {
            notifier.onTick(positionSec: pos, durationSec: dur);
            positions.put(lecture.id, pos);
          },
          onPause: () => notifier.flush(),
        ),
        Expanded(
          child: _LectureBody(
            lecture: lecture,
            courseId: courseId,
            sectionId: sectionId,
            courseTitle: courseTitle,
            courseThumbnailUrl: courseThumbnailUrl,
          ),
        ),
      ],
    );
  }
}

/// Helper used by both video + audio bodies to look up the persisted
/// position for the current lecture.
LectureProgressModel? _findRow(
  List<LectureProgressModel> rows,
  String lectureId,
) {
  for (final r in rows) {
    if (r.id == lectureId) return r;
  }
  return null;
}

/// Description + download button + downloadable resources, shared across
/// video/audio bodies.
class _LectureBody extends ConsumerWidget {
  const _LectureBody({
    required this.lecture,
    required this.courseId,
    required this.sectionId,
    required this.courseTitle,
    required this.courseThumbnailUrl,
  });
  final LectureEntity lecture;
  final String courseId;
  final String sectionId;
  final String courseTitle;
  final String? courseThumbnailUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `courseTitle` and `courseThumbnailUrl` are passed in from the
    // parent (already resolved against `courseDetailNotifierProvider`)
    // so the download button and notes section can use them without
    // re-watching the same provider here.

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(lecture.title, style: context.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${lecture.type.label} • ${lecture.formattedDuration}',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (lecture.mediaUrl != null && lecture.mediaUrl!.isNotEmpty)
          LectureDownloadButton(
            courseId: courseId,
            courseTitle: courseTitle,
            lectureId: lecture.id,
            lectureTitle: lecture.title,
            mediaUrl: lecture.mediaUrl!,
          ),
        if (lecture.description != null && lecture.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(lecture.description!, style: context.textTheme.bodyLarge),
        ],
        if (lecture.hasResources) ...[
          const SizedBox(height: 24),
          Text('Resources', style: context.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final r in lecture.resources)
            DocumentLectureResourceTile(resource: r),
        ],
        // ---- Notes ----------------------------------------------------
        // Embedded above the Q&A section so the user's own thoughts are
        // primary. Read-cheap when the user is signed out — the
        // provider short-circuits to an empty stream.
        if (sectionId.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Divider(height: 1),
          const SizedBox(height: 16),
          LectureNotesSection(
            courseId: courseId,
            courseTitle: courseTitle,
            courseThumbnailUrl: courseThumbnailUrl,
            sectionId: sectionId,
            lectureId: lecture.id,
            lectureTitle: lecture.title,
            // No-op for now — wiring the actual player seek requires
            // either a controller passed down from the player widget or
            // a Riverpod "seek bus" similar to the position registry.
            // Tracked as a follow-up.
            onJumpTo: null,
          ),
        ],
        // ---- Q&A ------------------------------------------------------
        // Only render when we managed to resolve the parent section id
        // from the curriculum. Missing sectionId means the lecture lookup
        // raced ahead of curriculum load — the section will appear once
        // the rebuild completes.
        if (sectionId.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Divider(height: 1),
          const SizedBox(height: 16),
          LectureQASection(
            courseId: courseId,
            sectionId: sectionId,
            lectureId: lecture.id,
          ),
        ],
      ],
    );
  }
}
