import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilearnit/features/courses/presentation/providers/course_detail_state.dart';
import 'package:ilearnit/features/courses/presentation/providers/curriculum_state.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../progress/data/datasources/lecture_progress_datasource.dart';
import '../../../progress/data/models/lecture_progress_model.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
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
  });

  final String courseId;
  final String lectureId;

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
          lecture: lecture,
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
    required this.lecture,
  });

  final String courseId;
  final LectureEntity lecture;

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
        return _VideoBody(courseId: courseId, lecture: lecture);
      case LectureType.audio:
        return _AudioBody(courseId: courseId, lecture: lecture);
      case LectureType.pdf:
      case LectureType.doc:
        return DocumentLectureView(lecture: lecture);
    }
  }
}

class _VideoBody extends ConsumerWidget {
  const _VideoBody({required this.courseId, required this.lecture});
  final String courseId;
  final LectureEntity lecture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lecture.mediaUrl == null || lecture.mediaUrl!.isEmpty) {
      return const Center(child: Text('Video unavailable.'));
    }
    final key =
        LectureProgressKey(courseId: courseId, lectureId: lecture.id);
    final notifier = ref.read(lectureProgressNotifierProvider(key).notifier);
    final saved = ref
        .watch(lectureProgressByCourseProvider(courseId))
        .maybeWhen(data: (rows) => _findRow(rows, lecture.id), orElse: () => null);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoLecturePlayer(
            url: lecture.mediaUrl!,
            initialPositionSec: saved?.positionSec ?? 0,
            onTick: (pos, dur) =>
                notifier.onTick(positionSec: pos, durationSec: dur),
            onPause: () => notifier.flush(),
          ),
        ),
        Expanded(child: _LectureBody(lecture: lecture)),
      ],
    );
  }
}

class _AudioBody extends ConsumerWidget {
  const _AudioBody({required this.courseId, required this.lecture});
  final String courseId;
  final LectureEntity lecture;

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

    return Column(
      children: [
        AudioLecturePlayer(
          url: lecture.mediaUrl!,
          title: lecture.title,
          initialPositionSec: saved?.positionSec ?? 0,
          onTick: (pos, dur) =>
              notifier.onTick(positionSec: pos, durationSec: dur),
          onPause: () => notifier.flush(),
        ),
        Expanded(child: _LectureBody(lecture: lecture)),
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

/// Description + downloadable resources, shared across video/audio bodies.
class _LectureBody extends StatelessWidget {
  const _LectureBody({required this.lecture});
  final LectureEntity lecture;

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}
