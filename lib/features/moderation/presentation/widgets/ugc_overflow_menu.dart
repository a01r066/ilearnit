import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/routing/route_names.dart';
import '../../domain/entities/report_content_type.dart';
import '../providers/moderation_providers.dart';
import 'block_user_dialog.dart';
import 'report_content_sheet.dart';

/// Three-dots overflow menu rendered next to a UGC item (review,
/// question, answer, note). Shows:
///
///   • Report — opens [ReportContentSheet].
///   • Block / Unblock — toggles the per-user block list.
///
/// Pure presentation — the parent supplies the content metadata. No
/// item is rendered for the signed-in user's *own* content (you can't
/// usefully report or block yourself). For guests the menu pushes
/// /login instead — the moderation surfaces need a uid to attribute
/// reports + blocks to.
class UgcOverflowMenu extends ConsumerWidget {
  const UgcOverflowMenu({
    super.key,
    required this.contentType,
    required this.contentId,
    required this.contentPath,
    required this.contentSnapshot,
    required this.authorId,
    this.authorName = '',
    this.courseId,
    this.lectureId,
    this.iconColor,
  });

  final ReportContentType contentType;
  final String contentId;
  final String contentPath;
  final String contentSnapshot;
  final String authorId;
  final String authorName;
  final String? courseId;
  final String? lectureId;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final blockedIds =
        ref.watch(blockedUserIdsProvider).value ?? const <String>{};

    // Don't show self-targeting actions.
    if (user != null && user.id == authorId) {
      return const SizedBox.shrink();
    }

    final isBlocked = blockedIds.contains(authorId);

    return PopupMenuButton<_UgcAction>(
      tooltip: 'More',
      icon: Icon(Icons.more_vert, color: iconColor),
      onSelected: (action) => _handle(context, ref, action),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: _UgcAction.report,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.flag_outlined),
            title: Text('Report'),
          ),
        ),
        PopupMenuItem(
          value: isBlocked ? _UgcAction.unblock : _UgcAction.block,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isBlocked ? Icons.lock_open_outlined : Icons.block,
            ),
            title: Text(
              isBlocked
                  ? 'Unblock ${_displayName()}'
                  : 'Block ${_displayName()}',
            ),
          ),
        ),
      ],
    );
  }

  String _displayName() => authorName.isEmpty ? 'user' : authorName;

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    _UgcAction action,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      // Guest browse → redirect to login. Matches the pattern already
      // used by BookmarkButton, WriteReviewSheet, Q&A "Ask".
      context.pushNamed(RouteNames.login);
      return;
    }
    switch (action) {
      case _UgcAction.report:
        await showReportContentSheet(
          context,
          contentType: contentType,
          contentId: contentId,
          contentPath: contentPath,
          contentSnapshot: contentSnapshot,
          authorId: authorId,
          authorName: authorName,
          courseId: courseId,
          lectureId: lectureId,
        );
      case _UgcAction.block:
        await confirmAndBlockUser(
          context,
          authorUid: authorId,
          authorName: authorName,
        );
      case _UgcAction.unblock:
        await ref.read(blocksDataSourceProvider).unblock(
              ownerUid: user.id,
              blockedUid: authorId,
            );
    }
  }
}

enum _UgcAction { report, block, unblock }
