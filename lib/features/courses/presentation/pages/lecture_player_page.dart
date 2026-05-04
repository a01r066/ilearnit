import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilearnit/features/courses/presentation/providers/curriculum_state.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
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
        return _LecturePlayerScaffold(lecture: lecture);
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
}

class _LecturePlayerScaffold extends StatelessWidget {
  const _LecturePlayerScaffold({required this.lecture});
  final LectureEntity lecture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lecture.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (lecture.type) {
      case LectureType.video:
        return _VideoBody(lecture: lecture);
      case LectureType.audio:
        return _AudioBody(lecture: lecture);
      case LectureType.pdf:
      case LectureType.doc:
        return DocumentLectureView(lecture: lecture);
    }
  }
}

class _VideoBody extends StatelessWidget {
  const _VideoBody({required this.lecture});
  final LectureEntity lecture;

  @override
  Widget build(BuildContext context) {
    if (lecture.mediaUrl == null || lecture.mediaUrl!.isEmpty) {
      return const Center(child: Text('Video unavailable.'));
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoLecturePlayer(url: lecture.mediaUrl!),
        ),
        Expanded(child: _LectureBody(lecture: lecture)),
      ],
    );
  }
}

class _AudioBody extends StatelessWidget {
  const _AudioBody({required this.lecture});
  final LectureEntity lecture;

  @override
  Widget build(BuildContext context) {
    if (lecture.mediaUrl == null || lecture.mediaUrl!.isEmpty) {
      return const Center(child: Text('Audio unavailable.'));
    }
    return Column(
      children: [
        AudioLecturePlayer(url: lecture.mediaUrl!, title: lecture.title),
        Expanded(child: _LectureBody(lecture: lecture)),
      ],
    );
  }
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
