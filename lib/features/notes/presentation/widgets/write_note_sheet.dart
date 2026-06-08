import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/note_form_state.dart';
import '../providers/notes_keys.dart';
import '../providers/notes_providers.dart';

/// Bottom-sheet for adding (or editing) a note.
///
/// Use [WriteNoteSheet.show] — it handles modal presentation, notifier
/// priming, and returns `true` if a note was saved so the caller can
/// react (e.g. a snackbar).
class WriteNoteSheet extends ConsumerStatefulWidget {
  const WriteNoteSheet._({
    required this.formKey,
    required this.initialTimestampSec,
    this.editingNoteId,
    this.editingBody,
    this.editingTimestampSec,
  });

  final NoteFormKey formKey;
  final int? initialTimestampSec;

  // Edit-in-place fields. Populated when the sheet is opened from an
  // existing note's overflow menu.
  final String? editingNoteId;
  final String? editingBody;
  final int? editingTimestampSec;

  /// Open the sheet. Returns `true` if a note was created or saved.
  static Future<bool> show(
    BuildContext context, {
    required NoteFormKey formKey,
    int? initialTimestampSec,
    String? editingNoteId,
    String? editingBody,
    int? editingTimestampSec,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => WriteNoteSheet._(
        formKey: formKey,
        initialTimestampSec: initialTimestampSec,
        editingNoteId: editingNoteId,
        editingBody: editingBody,
        editingTimestampSec: editingTimestampSec,
      ),
    );
    return result ?? false;
  }

  @override
  ConsumerState<WriteNoteSheet> createState() => _WriteNoteSheetState();
}

class _WriteNoteSheetState extends ConsumerState<WriteNoteSheet> {
  late final TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _bodyCtrl = TextEditingController(text: widget.editingBody ?? '');
    // Prime the notifier on next frame so the widget tree is mounted
    // and ref.read() is safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier =
          ref.read(noteFormNotifierProvider(widget.formKey).notifier);
      if (widget.editingNoteId != null) {
        notifier.startEditing(
          noteId: widget.editingNoteId!,
          body: widget.editingBody ?? '',
          timestampSec: widget.editingTimestampSec,
        );
      } else {
        notifier.startNew(timestampSec: widget.initialTimestampSec);
      }
    });
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(noteFormNotifierProvider(widget.formKey));
    final notifier =
        ref.read(noteFormNotifierProvider(widget.formKey).notifier);

    // Surface a failure as a snackbar without popping the sheet.
    ref.listen<NoteFormState>(noteFormNotifierProvider(widget.formKey),
        (_, next) {
      if (next.lastFailure != null) {
        context.showSnack(next.lastFailure!.displayMessage);
      }
      if (next.justSubmitted) {
        Navigator.of(context).pop(true);
      }
    });

    final ts = state.timestampSec;
    final timestampLabel = ts == null
        ? t.notesNoTimestamp
        : _fmt(ts);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            state.isEditing ? t.notesEditTitle : t.notesAddTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                ts == null ? Icons.bookmark_border : Icons.bookmark,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(timestampLabel),
              const Spacer(),
              if (ts != null)
                TextButton(
                  onPressed: () => notifier.setTimestamp(null),
                  child: Text(t.notesClearTimestamp),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyCtrl,
            onChanged: notifier.setBody,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            maxLength: 4000,
            decoration: InputDecoration(
              hintText: t.notesBodyHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: state.canSubmit ? notifier.submit : null,
            child: state.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(state.isEditing
                    ? t.notesSaveChanges
                    : t.notesSaveNew),
          ),
        ],
      ),
    );
  }

  String _fmt(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
