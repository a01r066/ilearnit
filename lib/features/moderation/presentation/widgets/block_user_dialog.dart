import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/moderation_providers.dart';

/// AlertDialog that confirms a block, then writes to
/// `users/{viewerUid}/blocks/{authorUid}`. The blocked author's
/// content disappears from every UGC list this user opens (the lists
/// filter on [blockedUserIdsProvider]).
///
/// Shown via [confirmAndBlockUser].
class BlockUserDialog extends ConsumerStatefulWidget {
  const BlockUserDialog({
    super.key,
    required this.authorUid,
    required this.authorName,
  });

  final String authorUid;
  final String authorName;

  @override
  ConsumerState<BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends ConsumerState<BlockUserDialog> {
  bool _busy = false;

  Future<void> _block() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(blocksDataSourceProvider).block(
            ownerUid: user.id,
            blockedUid: widget.authorUid,
            blockedName: widget.authorName,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not block: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.authorName.isEmpty ? 'this user' : widget.authorName;
    return AlertDialog(
      title: Text('Block $name?'),
      content: Text(
        "You won't see any reviews, questions, answers, or notes from "
        "$name. They won't be notified.",
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          onPressed: _busy ? null : _block,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Block'),
        ),
      ],
    );
  }
}

/// Returns `true` if the block was confirmed and written.
Future<bool> confirmAndBlockUser(
  BuildContext context, {
  required String authorUid,
  required String authorName,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => BlockUserDialog(
      authorUid: authorUid,
      authorName: authorName,
    ),
  );
  return ok ?? false;
}
