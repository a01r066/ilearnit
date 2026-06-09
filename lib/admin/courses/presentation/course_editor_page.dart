import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/courses/data/models/course_model.dart';
import '../../../features/courses/data/models/course_section_model.dart';
import '../../../features/courses/data/models/lecture_model.dart';
import '../../../features/courses/domain/entities/instrument_category.dart';
import '../../../features/courses/domain/entities/lecture_type.dart';
import '../../../features/purchases/domain/entities/price_tier.dart';
import '../../shared/providers/admin_providers.dart';
import '../data/admin_storage_service.dart';

/// Course editor — flat, single-page layout.
///
/// History: the original editor used a TabBar + TabBarView with
/// `DropdownButtonFormField`s and `ExpansionTile`s inside a Card-based
/// section list. On Flutter web this combination produced a flood of
/// `Cannot hit test a render box with no size.` assertions during the
/// transient frames between StreamBuilder rebuilds and Tab swipes.
///
/// This rewrite uses only "safe" widgets:
///   • No `TabBar` / `TabBarView` — one `ListView`, scroll the whole page
///   • No `Card` — `Container(decoration, clipBehavior)` for surfaces
///   • No `DropdownButtonFormField` — `Wrap` of `ChoiceChip`s
///   • No `ExpansionTile` — always-visible sections, the header is just
///     a `Text`
///   • Every action button lives in a bounded `SizedBox` so Row's
///     intrinsic-width pass never propagates infinity
///
/// Functionality is unchanged: save metadata, manage sections, manage
/// lectures, upload thumbnail. The lecture-editor dialog at the bottom
/// of this file is kept verbatim — it already used `isExpanded: true`.
class CourseEditorPage extends ConsumerStatefulWidget {
  const CourseEditorPage({super.key, required this.courseId});
  final String courseId;

  @override
  ConsumerState<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _CourseEditorPageState extends ConsumerState<CourseEditorPage> {
  @override
  Widget build(BuildContext context) {
    final stream =
        ref.watch(adminCoursesDataSourceProvider).watchCourse(widget.courseId);

    return StreamBuilder<CourseModel?>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final course = snap.data;
        if (course == null) {
          return const Center(child: Text('Course not found.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(course.title,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                _MetadataSection(course: course),
                const SizedBox(height: 32),
                _CurriculumSection(courseId: course.id),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------- Metadata section ---------------------------------------------

class _MetadataSection extends ConsumerStatefulWidget {
  const _MetadataSection({required this.course});
  final CourseModel course;

  @override
  ConsumerState<_MetadataSection> createState() =>
      _MetadataSectionState();
}

class _MetadataSectionState extends ConsumerState<_MetadataSection> {
  late final TextEditingController _title;
  late final TextEditingController _summary;
  late InstrumentCategory _category;
  late CourseLevel _level;
  late PriceTier _tier;
  String? _thumbnailUrl;
  bool _saving = false;
  UploadProgress? _thumbProgress;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.course.title);
    _summary = TextEditingController(text: widget.course.summary);
    _category = InstrumentCategory.fromId(widget.course.category);
    _level = CourseLevel.fromId(widget.course.level);
    _tier = PriceTier.fromId(widget.course.priceTier);
    _thumbnailUrl = widget.course.thumbnailUrl.isEmpty
        ? null
        : widget.course.thumbnailUrl;
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminCoursesDataSourceProvider).updateCourse(
            widget.course.copyWith(
              title: _title.text.trim(),
              summary: _summary.text.trim(),
              category: _category.id,
              level: _level.id,
              priceTier: _tier.id,
              thumbnailUrl: _thumbnailUrl ?? '',
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final stream =
        ref.read(adminStorageServiceProvider).uploadCourseThumbnail(
              courseId: widget.course.id,
              filename: file.name,
              bytes: bytes,
              contentType: _guessImageType(file.extension),
            );
    stream.listen((p) {
      if (!mounted) return;
      setState(() => _thumbProgress = p);
      if (p.phase == UploadPhase.completed && p.downloadUrl != null) {
        setState(() => _thumbnailUrl = p.downloadUrl);
      }
    });
  }

  String _guessImageType(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _summary,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Summary',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Chip-pickers replace DropdownButtonFormField. The chip
          // widgets size to their content within a Wrap so they never
          // ask for intrinsic widths from their parents.
          _ChipPicker<InstrumentCategory>(
            label: 'Instrument',
            value: _category,
            options: InstrumentCategory.values,
            optionLabel: (v) => v.label,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 16),
          _ChipPicker<CourseLevel>(
            label: 'Level',
            value: _level,
            options: CourseLevel.values,
            optionLabel: (v) => v.label,
            onChanged: (v) => setState(() => _level = v),
          ),
          const SizedBox(height: 16),
          _ChipPicker<PriceTier>(
            label: 'Price tier',
            value: _tier,
            options: PriceTier.values,
            optionLabel: (v) => '${v.id} · ${v.fallbackPrice}',
            onChanged: (v) => setState(() => _tier = v),
          ),

          const SizedBox(height: 24),
          Text('Thumbnail', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: _thumbnailUrl == null
                ? const Center(child: Icon(Icons.image_outlined, size: 48))
                : Image.network(
                    _thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined, size: 48),
                    ),
                  ),
          ),
          if (_thumbProgress != null &&
              _thumbProgress!.phase == UploadPhase.running)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                  value: _thumbProgress!.fraction),
            ),
          const SizedBox(height: 12),
          // Buttons always inside bounded SizedBox — no intrinsic-width
          // surprises.
          SizedBox(
            width: 220,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Upload thumbnail'),
              onPressed: _pickThumbnail,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic chip-based picker — replaces `DropdownButtonFormField`.
class _ChipPicker<T> extends StatelessWidget {
  const _ChipPicker({
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              ChoiceChip(
                label: Text(optionLabel(o)),
                selected: o == value,
                onSelected: (selected) {
                  if (selected) onChanged(o);
                },
              ),
          ],
        ),
      ],
    );
  }
}

// ---------- Curriculum section -------------------------------------------

class _CurriculumSection extends ConsumerWidget {
  const _CurriculumSection({required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sections = ref
        .watch(adminCoursesDataSourceProvider)
        .watchSections(courseId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: StreamBuilder<List<CourseSectionModel>>(
        stream: sections,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final items = snap.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Curriculum',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                  SizedBox(
                    width: 180,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add section'),
                      onPressed: () =>
                          _addSection(context, ref, items.length),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No sections yet — add one to start.'),
                ),
              for (final s in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SectionPanel(courseId: courseId, section: s),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addSection(
    BuildContext context,
    WidgetRef ref,
    int currentLength,
  ) async {
    final ctrl = TextEditingController(text: 'New section');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add section'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(adminCoursesDataSourceProvider).createSection(
          courseId: courseId,
          title: ctrl.text.trim(),
          order: currentLength,
        );
  }
}

// ---------- Section panel (replaces ExpansionTile) -----------------------

class _SectionPanel extends ConsumerWidget {
  const _SectionPanel({required this.courseId, required this.section});
  final String courseId;
  final CourseSectionModel section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lectures = ref
        .watch(adminCoursesDataSourceProvider)
        .watchLectures(courseId: courseId, sectionId: section.id);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(section.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                ),
                IconButton(
                  tooltip: 'Delete section',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteSection(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<LectureModel>>(
              stream: lectures,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  );
                }
                final items = snap.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final l in items)
                      _LectureRow(
                        lecture: l,
                        onEdit: () =>
                            _editLecture(context, ref, l),
                        onDelete: () =>
                            _deleteLecture(context, ref, l),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 180,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _addLecture(context, ref, items.length),
                        icon: const Icon(Icons.add),
                        label: const Text('Add lecture'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addLecture(
      BuildContext context, WidgetRef ref, int currentLen) async {
    final result = await showDialog<_LectureDraft>(
      context: context,
      builder: (_) => _LectureEditorDialog(order: currentLen),
    );
    if (result == null) return;
    await ref.read(adminCoursesDataSourceProvider).createLecture(
          courseId: courseId,
          sectionId: section.id,
          lecture: result.toModel(''),
        );
  }

  Future<void> _editLecture(
      BuildContext context, WidgetRef ref, LectureModel lecture) async {
    final draft = _LectureDraft.fromModel(lecture);
    final result = await showDialog<_LectureDraft>(
      context: context,
      builder: (_) => _LectureEditorDialog(
        order: lecture.order,
        initial: draft,
        courseId: courseId,
        sectionId: section.id,
        lectureId: lecture.id,
      ),
    );
    if (result == null) return;
    await ref.read(adminCoursesDataSourceProvider).updateLecture(
          courseId: courseId,
          sectionId: section.id,
          lecture: result.toModel(lecture.id),
        );
  }

  Future<void> _deleteLecture(
      BuildContext context, WidgetRef ref, LectureModel lecture) async {
    await ref.read(adminCoursesDataSourceProvider).deleteLecture(
          courseId: courseId,
          sectionId: section.id,
          lectureId: lecture.id,
        );
  }

  Future<void> _deleteSection(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete section?'),
        content: Text(
          'Section "${section.title}" and all of its lectures will be '
          'removed from this course.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(adminCoursesDataSourceProvider).deleteSection(
          courseId: courseId,
          sectionId: section.id,
        );
  }
}

class _LectureRow extends StatelessWidget {
  const _LectureRow({
    required this.lecture,
    required this.onEdit,
    required this.onDelete,
  });
  final LectureModel lecture;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(LectureType.fromId(lecture.type).icon,
              color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lecture.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${lecture.type} · ${_formatBytes(lecture.fileSizeBytes)}'
                  '${lecture.isPreview ? " · free preview" : ""}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit / upload',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB'];
  var i = 0;
  var v = bytes.toDouble();
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(1)} ${units[i]}';
}

// ---------- Lecture editor dialog -----------------------------------------
// (Kept verbatim — already uses `isExpanded: true` on its dropdown.)

class _LectureDraft {
  _LectureDraft({
    required this.title,
    required this.description,
    required this.type,
    required this.durationSeconds,
    required this.isPreview,
    required this.mediaUrl,
    required this.fileSizeBytes,
    required this.order,
  });

  factory _LectureDraft.fromModel(LectureModel m) => _LectureDraft(
        title: m.title,
        description: m.description ?? '',
        type: LectureType.fromId(m.type),
        durationSeconds: m.durationSeconds,
        isPreview: m.isPreview,
        mediaUrl: m.mediaUrl,
        fileSizeBytes: m.fileSizeBytes,
        order: m.order,
      );

  String title;
  String description;
  LectureType type;
  int durationSeconds;
  bool isPreview;
  String? mediaUrl;
  int fileSizeBytes;
  int order;

  LectureModel toModel(String id) => LectureModel(
        id: id,
        title: title,
        type: type.id,
        durationSeconds: durationSeconds,
        order: order,
        isPreview: isPreview,
        mediaUrl: mediaUrl,
        description: description.isEmpty ? null : description,
        fileSizeBytes: fileSizeBytes,
      );
}

class _LectureEditorDialog extends ConsumerStatefulWidget {
  const _LectureEditorDialog({
    required this.order,
    this.initial,
    this.courseId,
    this.sectionId,
    this.lectureId,
  });

  final int order;
  final _LectureDraft? initial;
  final String? courseId;
  final String? sectionId;
  final String? lectureId;

  @override
  ConsumerState<_LectureEditorDialog> createState() =>
      _LectureEditorDialogState();
}

class _LectureEditorDialogState extends ConsumerState<_LectureEditorDialog> {
  late _LectureDraft _draft;
  late final TextEditingController _title;
  late final TextEditingController _description;
  UploadProgress? _progress;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial ??
        _LectureDraft(
          title: 'New lecture',
          description: '',
          type: LectureType.video,
          durationSeconds: 0,
          isPreview: false,
          mediaUrl: null,
          fileSizeBytes: 0,
          order: widget.order,
        );
    _title = TextEditingController(text: _draft.title);
    _description = TextEditingController(text: _draft.description);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final cid = widget.courseId;
    final sid = widget.sectionId;
    final lid = widget.lectureId;
    if (cid == null || sid == null || lid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Save the lecture first, then re-open to upload media.'),
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: _pickerType(_draft.type),
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final stream =
        ref.read(adminStorageServiceProvider).uploadLectureMedia(
              courseId: cid,
              sectionId: sid,
              lectureId: lid,
              filename: file.name,
              bytes: bytes,
              contentType: _contentTypeFor(_draft.type, file.extension),
            );
    stream.listen((p) {
      if (!mounted) return;
      setState(() {
        _progress = p;
        if (p.phase == UploadPhase.completed && p.downloadUrl != null) {
          _draft.mediaUrl = p.downloadUrl;
          _draft.fileSizeBytes = p.totalBytes;
        }
      });
    });
  }

  FileType _pickerType(LectureType t) {
    switch (t) {
      case LectureType.video:
        return FileType.video;
      case LectureType.audio:
        return FileType.audio;
      case LectureType.pdf:
      case LectureType.doc:
        return FileType.any;
    }
  }

  String _contentTypeFor(LectureType t, String? ext) {
    final e = ext?.toLowerCase() ?? '';
    switch (t) {
      case LectureType.video:
        return e == 'mov' ? 'video/quicktime' : 'video/mp4';
      case LectureType.audio:
        return e == 'wav' ? 'audio/wav' : 'audio/mpeg';
      case LectureType.pdf:
        return 'application/pdf';
      case LectureType.doc:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add lecture' : 'Edit lecture'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (v) => _draft.title = v,
              ),
              const SizedBox(height: 12),
              // Type uses ChoiceChips here too — same reasoning as the
              // outer page.
              _ChipPicker<LectureType>(
                label: 'Type',
                value: _draft.type,
                options: LectureType.values,
                optionLabel: (t) => t.label,
                onChanged: (v) => setState(() => _draft.type = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4,
                onChanged: (v) => _draft.description = v,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: 'Duration (seconds)'),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: _draft.durationSeconds.toString()),
                      onChanged: (v) =>
                          _draft.durationSeconds = int.tryParse(v) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SwitchListTile.adaptive(
                      title: const Text('Free preview'),
                      contentPadding: EdgeInsets.zero,
                      value: _draft.isPreview,
                      onChanged: (v) =>
                          setState(() => _draft.isPreview = v),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text('Media file',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_draft.mediaUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Uploaded · ${_formatBytes(_draft.fileSizeBytes)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('No file uploaded yet.'),
                ),
              if (_progress != null && !_progress!.isTerminal)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(value: _progress!.fraction),
                ),
              if (_progress?.phase == UploadPhase.failed)
                Text('Upload failed: ${_progress?.error}',
                    style: const TextStyle(color: Colors.red)),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.upload_outlined),
                  label: Text(_draft.mediaUrl == null
                      ? 'Upload media'
                      : 'Replace media'),
                  onPressed: _pickMedia,
                ),
              ),
              if (widget.lectureId == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Tip: save the lecture first, then re-open to upload media.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            _draft.title = _title.text.trim();
            _draft.description = _description.text.trim();
            Navigator.of(context).pop(_draft);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
