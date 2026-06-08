import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/lecture_notes_datasource.dart';
import '../../data/models/lecture_note_model.dart';
import 'note_form_notifier.dart';
import 'note_form_state.dart';
import 'notes_keys.dart';
import 'playback_position_registry.dart';

// ---------- Datasource ----------------------------------------------------

final lectureNotesDataSourceProvider = Provider<LectureNotesDataSource>(
  (ref) => LectureNotesDataSource(ref.watch(firestoreProvider)),
);

// ---------- Playback position bus ----------------------------------------

/// Singleton registry the video / audio player writes into on every
/// tick. The notes UI polls it when the user opens the "Add note"
/// sheet to pre-fill `timestampSec`.
final playbackPositionRegistryProvider =
    Provider<PlaybackPositionRegistry>((ref) => PlaybackPositionRegistry());

// ---------- Streams -------------------------------------------------------

/// Notes for a single lecture. Resolves the uid inside the family body
/// so anonymous viewers get an empty stream (no crash, no permission
/// denied).
final lectureNotesProvider = StreamProvider.autoDispose
    .family<List<LectureNoteModel>, LectureNotesKey>((ref, key) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(lectureNotesDataSourceProvider).watchByLecture(
        userId: user.id,
        courseId: key.courseId,
        lectureId: key.lectureId,
      );
});

/// Cross-course list — drives the standalone "My notes" page.
final allUserNotesProvider =
    StreamProvider.autoDispose<List<LectureNoteModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref
      .watch(lectureNotesDataSourceProvider)
      .watchAll(userId: user.id);
});

// ---------- Form ----------------------------------------------------------

final noteFormNotifierProvider = StateNotifierProvider.autoDispose
    .family<NoteFormNotifier, NoteFormState, NoteFormKey>(
  (ref, key) => NoteFormNotifier(
    datasource: ref.watch(lectureNotesDataSourceProvider),
    courseId: key.courseId,
    courseTitle: key.courseTitle,
    courseThumbnailUrl: key.courseThumbnailUrl,
    sectionId: key.sectionId,
    lectureId: key.lectureId,
    lectureTitle: key.lectureTitle,
    user: ref.watch(currentUserProvider),
  ),
);
