import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/storage/offline_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/providers/dio_provider.dart';
import '../../data/datasources/lecture_media_service.dart';
import '../../domain/entities/lecture_entity.dart';
import '../providers/courses_providers.dart';
import '../../domain/entities/lecture_resource_entity.dart';
import '../../domain/entities/lecture_type.dart';
import '../../../../l10n/l10n.dart';

/// Body for PDF / Word lectures: an icon hero + a primary download button +
/// any extra resources attached to the lecture.
class DocumentLectureView extends StatelessWidget {
  const DocumentLectureView({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.lecture,
  });
  final String courseId;
  final String sectionId;
  final LectureEntity lecture;

  LectureMediaRequest _req([int? resourceIndex]) => LectureMediaRequest(
        courseId: courseId,
        sectionId: sectionId,
        lectureId: lecture.id,
        resourceIndex: resourceIndex,
      );

  @override
  Widget build(BuildContext context) {
    final fileName = '${lecture.id}.${lecture.type == LectureType.pdf ? 'pdf' : 'docx'}';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: lecture.type == LectureType.pdf
                ? AppColors.error.withValues(alpha: 0.10)
                : AppColors.info.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Icon(
            lecture.type.icon,
            size: 80,
            color: lecture.type == LectureType.pdf
                ? AppColors.error
                : AppColors.info,
          ),
        ),
        const SizedBox(height: 24),
        Text(lecture.title, style: context.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${lecture.type.label} • ${_fmtBytes(lecture.fileSizeBytes)}',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (lecture.description != null && lecture.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(lecture.description!, style: context.textTheme.bodyLarge),
        ],
        const SizedBox(height: 24),
        if (lecture.mediaUrl != null && lecture.mediaUrl!.isNotEmpty)
          DocumentLectureResourceTile(
            resource: LectureResourceEntity(
              name: lecture.title,
              url: lecture.mediaUrl!,
              format: lecture.type == LectureType.pdf ? 'pdf' : 'docx',
              sizeBytes: lecture.fileSizeBytes,
            ),
            isPrimary: true,
            overrideFileName: fileName,
            source: _req(),
          ),
        if (lecture.hasResources) ...[
          const SizedBox(height: 24),
          Text(
            context.l10n.lectureAdditionalResources,
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final (i, r) in lecture.resources.indexed)
            DocumentLectureResourceTile(resource: r, source: _req(i)),
        ],
      ],
    );
  }

  static String _fmtBytes(int bytes) {
    if (bytes <= 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    var value = bytes.toDouble();
    while (value >= 1024 && i < units.length - 1) {
      value /= 1024;
      i++;
    }
    return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[i]}';
  }
}

/// Tile for a single downloadable file. Two-state UI:
///   - Idle: download icon, tap to fetch.
///   - Downloading: linear progress bar + bytes/total.
///   - Done: "Open" action to hand off to the OS viewer.
class DocumentLectureResourceTile extends ConsumerStatefulWidget {
  const DocumentLectureResourceTile({
    super.key,
    required this.resource,
    this.isPrimary = false,
    this.overrideFileName,
    this.source,
  });

  final LectureResourceEntity resource;
  final bool isPrimary;
  final String? overrideFileName;

  /// Where to resolve a signed URL when [resource.url] is a private
  /// Storage reference (`gs://…`). Ignored for plain https URLs.
  final LectureMediaRequest? source;

  @override
  ConsumerState<DocumentLectureResourceTile> createState() =>
      _DocumentLectureResourceTileState();
}

class _DocumentLectureResourceTileState
    extends ConsumerState<DocumentLectureResourceTile> {
  double? _progress; // null = idle, [0..1] = downloading, 1.0 + filePath = done
  String? _localPath;
  String? _error;
  CancelToken? _cancelToken;

  Future<void> _download() async {
    // Use the dedicated media-download Dio (no `AuthInterceptor`,
    // no JSON `Accept` / `Content-Type` defaults). The main
    // `dioProvider` is configured for our backend API, and its
    // BaseOptions leak `Content-Type: application/json` onto every
    // GET, which has been observed to provoke 403s from Firebase
    // Storage's newer `*.firebasestorage.app` buckets. See
    // `mediaDownloadDioProvider` for the rationale.
    final dio = ref.read(mediaDownloadDioProvider);
    final dir = await OfflineStorage.dir('resources');
    final String fileName;
    final override = widget.overrideFileName;
    if (override != null) {
      // Already unique: `{lectureId}.{pdf|docx}`.
      fileName = override.replaceAll(RegExp(r'[\\/]'), '_');
    } else {
      // `format` comes from Firestore (instructor-controlled): whitelist
      // it so it can't inject path separators.
      final ext = widget.resource.format.toLowerCase();
      final safeExt = RegExp(r'^[a-z0-9]{1,8}$').hasMatch(ext) ? ext : 'bin';
      final baseName = widget.resource.name
          .replaceAll(RegExp(r'[^\w\s.-]'), '_')
          .trim();
      // Prefix with a hash of the URL so same-named resources from
      // different lectures don't overwrite each other.
      fileName =
          '${widget.resource.url.hashCode.toUnsigned(32).toRadixString(16)}'
          '_$baseName.$safeExt';
    }
    final savePath = '${dir.path}/$fileName';
    final saveFile = File(savePath);
    await saveFile.parent.create(recursive: true);
    if (!mounted) return;

    setState(() {
      _progress = 0;
      _error = null;
    });

    _cancelToken = CancelToken();
    try {
      final url = await _resolvedUrl();
      await dio.download(
        url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (!mounted || total <= 0) return;
          setState(() => _progress = received / total);
        },
      );
      if (!mounted) return;
      setState(() {
        _progress = 1;
        _localPath = savePath;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _progress = null;
        _error = e is LectureMediaException && e.isLocked
            ? context.l10n.downloadPurchaseToDownload
            : context.l10n.downloadFailed;
      });
    }
  }

  /// Signed URL for private Storage files, the raw URL otherwise.
  Future<String> _resolvedUrl() async {
    final source = widget.source;
    if (source != null &&
        LectureMediaService.needsResolution(widget.resource.url)) {
      return ref.read(lectureMediaServiceProvider).resolve(source);
    }
    return widget.resource.url;
  }

  Future<void> _open() async {
    if (_localPath == null) return;
    final result = await OpenFilex.open(_localPath!);
    if (result.type != ResultType.done && mounted) {
      // Fall back to the browser if no app can handle the format.
      try {
        final url = await _resolvedUrl();
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isPrimary
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).hintColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              widget.resource.format == 'pdf'
                  ? Icons.picture_as_pdf_outlined
                  : Icons.description_outlined,
              color: color,
            ),
            title: Text(
              widget.resource.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                widget.resource.format.toUpperCase(),
                if (widget.resource.sizeBytes > 0)
                  DocumentLectureView._fmtBytes(widget.resource.sizeBytes),
              ].join(' • '),
            ),
            trailing: _trailing(),
          ),
          if (_progress != null && _progress! < 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: LinearProgressIndicator(value: _progress),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _trailing() {
    if (_progress == null) {
      return IconButton(
        tooltip: context.l10n.downloadCta,
        icon: const Icon(Icons.download_rounded),
        onPressed: _download,
      );
    }
    if (_progress! < 1) {
      return IconButton(
        tooltip: context.l10n.commonCancelDownload,
        icon: const Icon(Icons.close_rounded),
        onPressed: () => _cancelToken?.cancel('user'),
      );
    }
    // Bounded width — `ListTile.trailing` asserts that the trailing
    // widget's intrinsic width plus `contentPadding` doesn't exceed
    // the tile width. M3's `FilledButton` family wants to expand to
    // fill (`tapTargetSize: TapTargetSize.padded` adds 48dp of slop
    // on top of the label width), which trips that assertion and
    // floods the log with `Trailing widget consumes the entire tile
    // width`. Constraining the width also matches the visual rhythm
    // of the other two states (IconButton ≈ 48dp).
    return SizedBox(
      width: 80,
      child: FilledButton.tonal(
        onPressed: _open,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(context.l10n.commonOpen),
      ),
    );
  }
}
