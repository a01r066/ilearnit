import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/download_entity.dart';
import '../providers/downloads_notifier.dart';
import '../providers/downloads_providers.dart';

/// "My downloads" — list of completed offline lectures, with file size,
/// tap-to-resume into the lecture player, swipe to delete, and a
/// "Clear all" overflow.
class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(downloadsNotifierProvider);
    final notifier = ref.read(downloadsNotifierProvider.notifier);
    final items = state.completed;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.downloadsTitle),
        actions: [
          if (items.isNotEmpty)
            PopupMenuButton<_MenuAction>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (action) async {
                if (action == _MenuAction.clearAll) {
                  final ok = await _confirmClear(context, t);
                  if (ok) await notifier.wipe();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _MenuAction.clearAll,
                  child: Text(t.downloadsClearAll),
                ),
              ],
            ),
        ],
      ),
      body: !state.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? _EmptyState(label: t.downloadsEmpty)
              : Column(
                  children: [
                    _UsageHeader(bytesUsed: state.totalBytesUsed, t: t),
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) => _DownloadTile(
                          download: items[i],
                          onTap: () => _open(context, items[i]),
                          onDelete: () =>
                              notifier.delete(items[i].lectureId),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _open(BuildContext context, DownloadEntity d) {
    context.pushNamed(
      RouteNames.lecturePlayer,
      pathParameters: {'id': d.courseId, 'lectureId': d.lectureId},
    );
  }

  Future<bool> _confirmClear(BuildContext context, AppLocalizations t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.downloadsClearAllConfirmTitle),
        content: Text(t.downloadsClearAllConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.downloadsClearAll),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

enum _MenuAction { clearAll }

// ---------- Subwidgets ----------------------------------------------------

class _UsageHeader extends StatelessWidget {
  const _UsageHeader({required this.bytesUsed, required this.t});
  final int bytesUsed;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final size = DownloadEntity(
      lectureId: '',
      courseId: '',
      courseTitle: '',
      lectureTitle: '',
      mediaUrl: '',
      localPath: '',
      totalBytes: bytesUsed,
    ).formattedSize;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Row(
        children: [
          const Icon(Icons.sd_storage_outlined,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            t.downloadsUsed(size),
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({
    required this.download,
    required this.onTap,
    required this.onDelete,
  });

  final DownloadEntity download;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
    return Dismissible(
      key: ValueKey(download.lectureId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.12),
          ),
          child: const Icon(
            Icons.download_done_rounded,
            color: AppColors.success,
          ),
        ),
        title: Text(
          download.lectureTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            download.courseTitle.isEmpty
                ? '${download.formattedSize}'
                : '${download.courseTitle} · ${download.formattedSize}'
                    '${download.downloadedAt != null ? ' · ${dateFmt.format(download.downloadedAt!)}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        trailing: const Icon(Icons.play_circle_outline_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 64,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
