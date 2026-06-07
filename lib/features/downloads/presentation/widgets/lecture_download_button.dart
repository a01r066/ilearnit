import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../purchases/presentation/providers/purchases_providers.dart';
import '../../domain/entities/download_entity.dart';
import '../providers/downloads_notifier.dart';
import '../providers/downloads_providers.dart';

/// Pill-style button rendered above the lecture body.
///
/// State machine, derived from [DownloadEntity.status]:
///   • none           → "Download" (cloud_download_outlined)
///   • downloading    → "Downloading… 42%" with cancel affordance
///   • paused/failed  → "Resume" (refresh)
///   • completed      → "Downloaded" with delete affordance
///
/// Gated on `hasUnlockedAccessProvider(courseId)` — anonymous viewers and
/// non-owners see nothing.
class LectureDownloadButton extends ConsumerWidget {
  const LectureDownloadButton({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.lectureId,
    required this.lectureTitle,
    required this.mediaUrl,
  });

  final String courseId;
  final String courseTitle;
  final String lectureId;
  final String lectureTitle;
  final String mediaUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final hasAccess = ref.watch(hasUnlockedAccessProvider(courseId));
    if (!hasAccess) return const SizedBox.shrink();
    if (mediaUrl.isEmpty) return const SizedBox.shrink();

    final entity = ref.watch(downloadForLectureProvider(lectureId));
    final notifier = ref.read(downloadsNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _renderFor(context, t, entity, notifier),
    );
  }

  Widget _renderFor(
    BuildContext context,
    AppLocalizations t,
    DownloadEntity? entity,
    DownloadsNotifier notifier,
  ) {
    if (entity == null) {
      return _Pill(
        icon: Icons.download_for_offline_outlined,
        label: t.downloadCta,
        onTap: () => notifier.startDownload(
          lectureId: lectureId,
          courseId: courseId,
          courseTitle: courseTitle,
          lectureTitle: lectureTitle,
          mediaUrl: mediaUrl,
        ),
      );
    }

    switch (entity.status) {
      case DownloadStatus.queued:
      case DownloadStatus.downloading:
        final pct = (entity.progress * 100).round();
        return _Pill(
          icon: Icons.close_rounded,
          label: '${t.downloadInProgress} $pct%',
          progress: entity.progress,
          onTap: () => notifier.pause(lectureId),
        );
      case DownloadStatus.paused:
      case DownloadStatus.failed:
        return Row(
          children: [
            Expanded(
              child: _Pill(
                icon: Icons.refresh_rounded,
                label: t.downloadResume,
                onTap: () => notifier.resume(entity),
              ),
            ),
            const SizedBox(width: 8),
            _IconAction(
              icon: Icons.delete_outline_rounded,
              onTap: () => notifier.delete(lectureId),
              tooltip: t.downloadDelete,
            ),
          ],
        );
      case DownloadStatus.completed:
        return Row(
          children: [
            Expanded(
              child: _Pill(
                icon: Icons.check_circle_rounded,
                label:
                    '${t.downloadCompleted} · ${entity.formattedSize}',
                onTap: null,
                tone: _PillTone.success,
              ),
            ),
            const SizedBox(width: 8),
            _IconAction(
              icon: Icons.delete_outline_rounded,
              onTap: () => notifier.delete(lectureId),
              tooltip: t.downloadDelete,
            ),
          ],
        );
    }
  }
}

enum _PillTone { neutral, success }

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.progress,
    this.tone = _PillTone.neutral,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double? progress;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final bg = tone == _PillTone.success
        ? AppColors.success.withValues(alpha: 0.12)
        : AppColors.primary.withValues(alpha: 0.10);
    final fg = tone == _PillTone.success
        ? AppColors.success
        : AppColors.primary;
    final borderColor = tone == _PillTone.success
        ? AppColors.success.withValues(alpha: 0.30)
        : AppColors.primary.withValues(alpha: 0.25);

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: context.textTheme.titleSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  value: progress! > 0 ? progress : null,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                  backgroundColor: fg.withValues(alpha: 0.18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Icon(icon, color: AppColors.error, size: 20),
        ),
      ),
    );
  }
}
