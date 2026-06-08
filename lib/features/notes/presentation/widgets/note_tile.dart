import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/lecture_note_model.dart';
import '../providers/notes_providers.dart';

/// Single note row. Shows the body, the timestamp pin (if any), and
/// an overflow menu with edit / delete.
///
/// Set [onJump] to render a "jump to timestamp" action — the parent
/// (lecture player) hooks this into the player seek, the standalone
/// notes page leaves it null.
class NoteTile extends ConsumerWidget {
  const NoteTile({
    super.key,
    required this.note,
    this.onJump,
    this.onEdit,
    this.showLectureLabel = false,
  });

  final LectureNoteModel note;
  final ValueChanged<int>? onJump;

  /// Optional override — when set, taps on "Edit" call this instead of
  /// the default sheet, letting the lecture player re-use its own
  /// pre-built `NoteFormKey`.
  final VoidCallback? onEdit;

  /// When true, render the lecture title above the body — used by the
  /// standalone "My notes" page where the user is browsing across
  /// lectures.
  final bool showLectureLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.timestampSec != null)
                InkWell(
                  onTap: onJump == null
                      ? null
                      : () => onJump!(note.timestampSec!),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          onJump != null
                              ? Icons.play_arrow
                              : Icons.bookmark,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _fmtTs(note.timestampSec!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (note.timestampSec != null) const SizedBox(width: 8),
              if (note.updatedAt != null)
                Text(
                  DateFormat.yMMMd().add_jm().format(note.updatedAt!),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              const Spacer(),
              PopupMenuButton<_NoteAction>(
                onSelected: (action) async {
                  switch (action) {
                    case _NoteAction.edit:
                      onEdit?.call();
                      break;
                    case _NoteAction.delete:
                      final user = ref.read(currentUserProvider);
                      if (user == null) return;
                      final ok = await _confirmDelete(context, t);
                      if (!ok) return;
                      await ref
                          .read(lectureNotesDataSourceProvider)
                          .delete(userId: user.id, noteId: note.id);
                      if (context.mounted) {
                        context.showSnack(t.notesDeleted);
                      }
                      break;
                  }
                },
                itemBuilder: (_) => [
                  if (onEdit != null)
                    PopupMenuItem(
                      value: _NoteAction.edit,
                      child: Text(t.notesEdit),
                    ),
                  PopupMenuItem(
                    value: _NoteAction.delete,
                    child: Text(t.notesDelete),
                  ),
                ],
              ),
            ],
          ),
          if (showLectureLabel && note.lectureTitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note.lectureTitle,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            note.body,
            style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    AppLocalizations t,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.notesDeleteConfirmTitle),
        content: Text(t.notesDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.notesCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.notesDelete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _fmtTs(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

enum _NoteAction { edit, delete }
