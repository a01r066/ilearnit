import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/failure.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/lecture_notes_datasource.dart';
import 'note_form_state.dart';

/// Drives the "Write a note" sheet. One notifier per lecture so
/// concurrent drafts don't bleed across the curriculum.
class NoteFormNotifier extends StateNotifier<NoteFormState> {
  NoteFormNotifier({
    required LectureNotesDataSource datasource,
    required this.courseId,
    required this.courseTitle,
    required this.courseThumbnailUrl,
    required this.sectionId,
    required this.lectureId,
    required this.lectureTitle,
    required UserEntity? user,
  })  : _datasource = datasource,
        _user = user,
        super(const NoteFormState());

  final LectureNotesDataSource _datasource;
  final String courseId;
  final String courseTitle;
  final String? courseThumbnailUrl;
  final String sectionId;
  final String lectureId;
  final String lectureTitle;
  final UserEntity? _user;

  void setBody(String value) =>
      state = state.copyWith(body: value, lastFailure: null);

  /// Replace the timestamp on the in-flight draft. Pass `null` to clear
  /// the pin.
  void setTimestamp(int? sec) =>
      state = state.copyWith(timestampSec: sec, lastFailure: null);

  /// Reset to a blank draft, pre-filling [timestampSec] from the
  /// player's current position. Called when the user opens the sheet.
  void startNew({int? timestampSec}) {
    state = NoteFormState(timestampSec: timestampSec);
  }

  /// Load an existing note's body + timestamp into the form so the
  /// sheet can edit-in-place.
  void startEditing({
    required String noteId,
    required String body,
    int? timestampSec,
  }) {
    state = NoteFormState(
      editingId: noteId,
      body: body,
      timestampSec: timestampSec,
    );
  }

  Future<bool> submit() async {
    final user = _user;
    if (user == null) return false;
    if (!state.canSubmit) return false;

    state = state.copyWith(
      isSubmitting: true,
      lastFailure: null,
      justSubmitted: false,
    );

    try {
      if (state.isEditing) {
        await _datasource.update(
          userId: user.id,
          noteId: state.editingId!,
          body: state.body,
          timestampSec: state.timestampSec,
          clearTimestamp: state.timestampSec == null,
        );
      } else {
        await _datasource.create(
          userId: user.id,
          courseId: courseId,
          courseTitle: courseTitle,
          courseThumbnailUrl: courseThumbnailUrl,
          sectionId: sectionId,
          lectureId: lectureId,
          lectureTitle: lectureTitle,
          body: state.body,
          timestampSec: state.timestampSec,
        );
      }
      // Reset to a blank draft so subsequent opens of the sheet don't
      // show the last note's text.
      state = const NoteFormState(justSubmitted: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: Failure.unexpected(
          message: 'Could not save your note.',
          error: e,
        ),
      );
      return false;
    }
  }
}
