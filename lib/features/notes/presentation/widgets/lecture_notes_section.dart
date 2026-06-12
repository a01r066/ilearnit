import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/notes_keys.dart';
import '../providers/notes_providers.dart';
import 'note_tile.dart';
import 'write_note_sheet.dart';

/// Compact "My notes for this lecture" panel embedded in the lecture
/// body. Shows up to [maxPreview] timestamped notes plus an
/// "Add a note" button that captures the live playback position.
///
/// [onJumpTo] is called when the user taps a note's timestamp pill so
/// the player can seek to that position.
class LectureNotesSection extends ConsumerWidget {
  const LectureNotesSection({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.courseThumbnailUrl,
    required this.sectionId,
    required this.lectureId,
    required this.lectureTitle,
    this.onJumpTo,
    this.maxPreview = 5,
  });

  final String courseId;
  final String courseTitle;
  final String? courseThumbnailUrl;
  final String sectionId;
  final String lectureId;
  final String lectureTitle;
  final ValueChanged<int>? onJumpTo;
  final int maxPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final notesAsync = ref.watch(lectureNotesProvider(
      LectureNotesKey(courseId: courseId, lectureId: lectureId),
    ));

    final formKey = NoteFormKey(
      courseId: courseId,
      courseTitle: courseTitle,
      courseThumbnailUrl: courseThumbnailUrl,
      sectionId: sectionId,
      lectureId: lectureId,
      lectureTitle: lectureTitle,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.notesSectionHeader,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Always render the Add note button — guests get routed
            // to /login on tap (instead of silently hiding the CTA,
            // which made the section look feature-less to unauth
            // users).
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(t.notesAddCta),
              onPressed: () async {
                if (user == null) {
                  context.showSnack('Sign in to save notes.');
                  context.goNamed(RouteNames.login);
                  return;
                }
                final ts = ref
                    .read(playbackPositionRegistryProvider)
                    .get(lectureId);
                await WriteNoteSheet.show(
                  context,
                  formKey: formKey,
                  initialTimestampSec: ts,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        notesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            '$e',
            style: TextStyle(color: context.colors.error),
          ),
          data: (notes) {
            if (notes.isEmpty) {
              return _EmptyState(
                t: t,
                signedIn: user != null,
              );
            }
            final shown = notes.take(maxPreview).toList();
            return Column(
              children: [
                for (final n in shown)
                  NoteTile(
                    note: n,
                    onJump: onJumpTo,
                    onEdit: () => WriteNoteSheet.show(
                      context,
                      formKey: formKey,
                      editingNoteId: n.id,
                      editingBody: n.body,
                      editingTimestampSec: n.timestampSec,
                    ),
                  ),
                if (notes.length > maxPreview)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      t.notesMoreInProfile(notes.length - maxPreview),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.t, required this.signedIn});
  final AppLocalizations t;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        signedIn ? t.notesEmptyAuthenticated : t.notesEmptyAnonymous,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
