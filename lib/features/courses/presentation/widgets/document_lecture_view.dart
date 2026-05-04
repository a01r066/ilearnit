import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/providers/dio_provider.dart';
import '../../domain/entities/lecture_entity.dart';
import '../../domain/entities/lecture_resource_entity.dart';
import '../../domain/entities/lecture_type.dart';

/// Body for PDF / Word lectures: an icon hero + a primary download button +
/// any extra resources attached to the lecture.
class DocumentLectureView extends StatelessWidget {
  const DocumentLectureView({super.key, required this.lecture});
  final LectureEntity lecture;

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
          ),
        if (lecture.hasResources) ...[
          const SizedBox(height: 24),
          Text('Additional resources', style: context.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final r in lecture.resources)
            DocumentLectureResourceTile(resource: r),
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
  });

  final LectureResourceEntity resource;
  final bool isPrimary;
  final String? overrideFileName;

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
    final dio = ref.read(dioProvider);
    final dir = await getApplicationDocumentsDirectory();
    final fileName = widget.overrideFileName ??
        widget.resource.name
                .replaceAll(RegExp(r'[^\w\s.-]'), '_')
                .trim() +
            '.${widget.resource.format}';
    final savePath = '${dir.path}/ilearnit/$fileName';
    final saveFile = File(savePath);
    await saveFile.parent.create(recursive: true);

    setState(() {
      _progress = 0;
      _error = null;
    });

    _cancelToken = CancelToken();
    try {
      await dio.download(
        widget.resource.url,
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
        _error = 'Download failed.';
      });
    }
  }

  Future<void> _open() async {
    if (_localPath == null) return;
    final result = await OpenFilex.open(_localPath!);
    if (result.type != ResultType.done && mounted) {
      // Fall back to the URL launcher if no app can handle the format.
      await launchUrl(
        Uri.parse(widget.resource.url),
        mode: LaunchMode.externalApplication,
      );
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
        icon: const Icon(Icons.download_rounded),
        onPressed: _download,
      );
    }
    if (_progress! < 1) {
      return IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => _cancelToken?.cancel('user'),
      );
    }
    return FilledButton.tonal(
      onPressed: _open,
      child: const Text('Open'),
    );
  }
}
