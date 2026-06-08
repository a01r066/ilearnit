import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/lecture_note_model.dart';
import '../providers/notes_keys.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_tile.dart';
import '../widgets/write_note_sheet.dart';

/// Full-screen list of every note the signed-in user has ever taken,
/// grouped by course. Notes inside a course retain their lecture
/// grouping in subtitles via [NoteTile.showLectureLabel].
///
/// Tap a tile's timestamp to jump into the lecture player at that
/// position — we route to the existing lecture player and pass the
/// timestamp as a query parameter so the player can fast-forward on
/// load.
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final notesAsync = ref.watch(allUserNotesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.notesPageTitle)),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$e',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return _EmptyState(t: t);
          }
          // Group by course preserving the order they came back in
          // (already sorted by updatedAt desc).
          final grouped = <String, List<LectureNoteModel>>{};
          for (final n in notes) {
            grouped.putIfAbsent(n.courseId, () => []).add(n);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              for (final entry in grouped.entries) ...[
                _CourseHeader(
                  title: entry.value.first.courseTitle,
                  count: entry.value.length,
                ),
                for (final note in entry.value)
                  NoteTile(
                    note: note,
                    showLectureLabel: true,
                    onJump: (sec) =>
                        _goToLecture(context, note, atSec: sec),
                    onEdit: () => WriteNoteSheet.show(
                      context,
                      formKey: NoteFormKey(
                        courseId: note.courseId,
                        courseTitle: note.courseTitle,
                        courseThumbnailUrl: note.courseThumbnailUrl,
                        sectionId: note.sectionId,
                        lectureId: note.lectureId,
                        lectureTitle: note.lectureTitle,
                      ),
                      editingNoteId: note.id,
                      editingBody: note.body,
                      editingTimestampSec: note.timestampSec,
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ],
          );
        },
      ),
    );
  }

  void _goToLecture(
    BuildContext context,
    LectureNoteModel note, {
    int? atSec,
  }) {
    context.goNamed(
      RouteNames.lecturePlayer,
      pathParameters: {
        'id': note.courseId,
        'lectureId': note.lectureId,
      },
      queryParameters: {
        if (atSec != null) 'at': atSec.toString(),
      },
    );
  }
}

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.isEmpty ? '—' : title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$count',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.t});
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sticky_note_2_outlined,
              size: 64,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              t.notesEmptyPageTitle,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.notesEmptyPageBody,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
