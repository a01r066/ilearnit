import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/courses/data/models/course_model.dart';
import '../../../features/courses/data/models/course_section_model.dart';
import '../../../features/courses/data/models/lecture_model.dart';
import '../../../features/courses/data/models/lecture_resource_model.dart';
import '../../../features/courses/domain/entities/course_status.dart';
import '../../../features/courses/domain/entities/instrument_category.dart';
import '../../../features/courses/domain/entities/lecture_type.dart';
import '../../../features/purchases/domain/entities/price_tier.dart';
import '../../shared/providers/admin_providers.dart';
import '../data/admin_storage_service.dart';
import '../data/cloudflare_upload_service.dart';
import 'widgets/course_status_actions.dart';
import 'widgets/course_status_chip.dart';

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

        final status = CourseStatus.fromId(course.status);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title + current status pill in one row, with the
                // workflow actions (Submit / Approve / Publish …)
                // tucked to the trailing edge. Wrap because long
                // titles + status + action could exceed one line on
                // narrow viewports.
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(course.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall),
                    CourseStatusChip(status: status),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CourseStatusActions(
                    courseId: course.id,
                    current: status,
                  ),
                ),
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
                    for (var i = 0; i < items.length; i++)
                      _LectureRow(
                        lecture: items[i],
                        // First row can't move up; last can't move
                        // down. Disabled callbacks render as greyed-
                        // out icons in `_LectureRow`.
                        onMoveUp: i == 0
                            ? null
                            : () => _swap(ref, items[i], items[i - 1]),
                        onMoveDown: i == items.length - 1
                            ? null
                            : () => _swap(ref, items[i], items[i + 1]),
                        onEdit: () =>
                            _editLecture(context, ref, items[i]),
                        onDelete: () =>
                            _deleteLecture(context, ref, items[i]),
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

  /// Swap two adjacent lectures' `order` fields via a Firestore batch.
  /// Driven by the up/down icon buttons on each row. The
  /// `watchLectures` stream reorders the rendered list on the next
  /// snapshot — no local state to keep in sync.
  Future<void> _swap(
    WidgetRef ref,
    LectureModel a,
    LectureModel b,
  ) async {
    await ref.read(adminCoursesDataSourceProvider).swapLectureOrder(
          courseId: courseId,
          sectionId: section.id,
          aId: a.id,
          aOrder: a.order,
          bId: b.id,
          bOrder: b.order,
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
    required this.onMoveUp,
    required this.onMoveDown,
  });
  final LectureModel lecture;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// `null` when this lecture is at the top of the section (move-up
  /// would be a no-op). Renders as a disabled icon so the layout stays
  /// stable across rows.
  final VoidCallback? onMoveUp;

  /// `null` when this lecture is at the bottom of the section.
  final VoidCallback? onMoveDown;

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
          // Reorder — up/down stacked tightly so the actions row stays
          // compact. `visualDensity: compact` shrinks the hit target
          // to ~32×32 (down from the M3 default of 48×48) so the two
          // arrows + edit + delete fit on one line at admin-portal
          // widths.
          IconButton(
            tooltip: 'Move up',
            icon: const Icon(Icons.keyboard_arrow_up),
            visualDensity: VisualDensity.compact,
            onPressed: onMoveUp,
          ),
          IconButton(
            tooltip: 'Move down',
            icon: const Icon(Icons.keyboard_arrow_down),
            visualDensity: VisualDensity.compact,
            onPressed: onMoveDown,
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
    required this.cloudflareVideoId,
    required this.fileSizeBytes,
    required this.order,
    List<LectureResourceModel>? resources,
  }) : resources = resources ?? <LectureResourceModel>[];

  factory _LectureDraft.fromModel(LectureModel m) => _LectureDraft(
        title: m.title,
        description: m.description ?? '',
        type: LectureType.fromId(m.type),
        durationSeconds: m.durationSeconds,
        isPreview: m.isPreview,
        mediaUrl: m.mediaUrl,
        cloudflareVideoId: m.cloudflareVideoId,
        fileSizeBytes: m.fileSizeBytes,
        order: m.order,
        // Defensive copy — the draft is mutable, the model isn't.
        resources: List<LectureResourceModel>.of(m.resources),
      );

  String title;
  String description;
  LectureType type;
  int durationSeconds;
  bool isPreview;
  String? mediaUrl;
  String? cloudflareVideoId;
  int fileSizeBytes;
  int order;

  /// Supplementary downloads (PDF / audio / doc) attached to this
  /// lecture. The main lecture media (video / audio file / PDF) lives
  /// on `mediaUrl` or `cloudflareVideoId`; this list is everything
  /// *extra* — sheet music, exercise PDFs, MP3 backing tracks, etc.
  /// Rendered on the mobile lecture page below the player via
  /// `DocumentLectureResourceTile`.
  List<LectureResourceModel> resources;

  LectureModel toModel(String id) => LectureModel(
        id: id,
        title: title,
        type: type.id,
        durationSeconds: durationSeconds,
        order: order,
        isPreview: isPreview,
        mediaUrl: mediaUrl,
        cloudflareVideoId:
            cloudflareVideoId?.trim().isEmpty == true
                ? null
                : cloudflareVideoId,
        description: description.isEmpty ? null : description,
        fileSizeBytes: fileSizeBytes,
        resources: List<LectureResourceModel>.of(resources),
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
  CloudflareUploadProgress? _cfProgress;

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
          cloudflareVideoId: null,
          fileSizeBytes: 0,
          order: widget.order,
        );
    _title = TextEditingController(text: _draft.title);
    _description = TextEditingController(text: _draft.description);
    _cloudflareId =
        TextEditingController(text: _draft.cloudflareVideoId ?? '');
  }

  late final TextEditingController _cloudflareId;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _cloudflareId.dispose();
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

  /// True while a Cloudflare upload is in flight (URL request or
  /// bytes upload). Drives the button's disabled state + label.
  bool get _cfBusy {
    final p = _cfProgress;
    if (p == null) return false;
    return p.phase == CloudflareUploadPhase.requestingUrl ||
        p.phase == CloudflareUploadPhase.uploading;
  }

  /// Pick a video file from local disk and upload it straight to
  /// Cloudflare Stream via the direct-creator-upload flow. The
  /// `cloudflareVideoId` field on the draft is populated automatically
  /// when the upload completes — no manual UID paste needed.
  ///
  /// Safe to call without saving the lecture first (unlike
  /// `_pickMedia`, which writes to Firebase Storage under the lecture
  /// id) — Cloudflare assigns the UID independently.
  void _uploadCloudflare() {
    final stream = ref.read(cloudflareUploadServiceProvider).pickAndUpload();
    stream.listen((p) {
      if (!mounted) return;
      setState(() {
        _cfProgress = p;
        if (p.phase == CloudflareUploadPhase.completed && p.videoUid != null) {
          _draft.cloudflareVideoId = p.videoUid;
          _cloudflareId.text = p.videoUid!;
        }
      });
    });
  }

  /// Pending resource upload (one at a time). Drives the inline
  /// progress bar under the "Add resource" button. `null` outside an
  /// active upload.
  UploadProgress? _resourceProgress;

  /// Pick a supplementary file (PDF / audio / doc / image) and upload
  /// it to the lecture's `resources/` Storage path. On success, the
  /// upload's download URL + a `LectureResourceModel` is appended to
  /// the draft so it gets persisted by the outer Save flow.
  Future<void> _pickResource() async {
    final cid = widget.courseId;
    final sid = widget.sectionId;
    final lid = widget.lectureId;
    if (cid == null || sid == null || lid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Save the lecture first, then re-open to add resources.',
          ),
        ),
      );
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final ext = (file.extension ?? '').toLowerCase();
    final format = _resourceFormatFor(ext);
    final contentType = _resourceContentTypeFor(ext);

    final stream = ref.read(adminStorageServiceProvider).uploadLectureResource(
          courseId: cid,
          sectionId: sid,
          lectureId: lid,
          filename: file.name,
          bytes: bytes,
          contentType: contentType,
        );

    stream.listen((p) {
      if (!mounted) return;
      setState(() {
        _resourceProgress = p;
        if (p.phase == UploadPhase.completed && p.downloadUrl != null) {
          // Append to the draft list. Name defaults to the picked
          // filename minus extension — admin can rename inline later
          // via the row's rename button.
          final displayName = _stripExtension(file.name);
          _draft.resources = [
            ..._draft.resources,
            LectureResourceModel(
              name: displayName,
              url: p.downloadUrl!,
              format: format,
              sizeBytes: p.totalBytes,
            ),
          ];
          // Clear the progress block after a beat so the user gets
          // visual confirmation before the indicator disappears.
          Future<void>.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            setState(() => _resourceProgress = null);
          });
        }
      });
    });
  }

  void _removeResource(LectureResourceModel r) {
    setState(() {
      _draft.resources = _draft.resources
          .where((x) => !(x.url == r.url && x.name == r.name))
          .toList();
    });
    // We DON'T delete the file from Storage — the URL might still
    // resolve from cached entitlements. Hard cleanup is an admin
    // janitor task; the practical effect of the remove button is
    // "drop this from the lecture's manifest."
  }

  Future<void> _renameResource(LectureResourceModel r) async {
    final ctrl = TextEditingController(text: r.name);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename resource'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Display name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (next == null || next.isEmpty) return;
    setState(() {
      _draft.resources = _draft.resources
          .map((x) => (x.url == r.url) ? x.copyWith(name: next) : x)
          .toList();
    });
  }

  /// Maps a file extension to the `format` string consumed by
  /// `DocumentLectureResourceTile` (drives the icon + the local
  /// filename when downloaded).
  String _resourceFormatFor(String ext) {
    if (ext == 'pdf') return 'pdf';
    if (ext == 'doc' || ext == 'docx') return ext;
    if (ext == 'mp3' || ext == 'm4a' || ext == 'wav' || ext == 'aac') {
      return ext;
    }
    return ext.isEmpty ? 'bin' : ext;
  }

  String _resourceContentTypeFor(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'png':
      case 'jpg':
      case 'jpeg':
        return 'image/$ext';
      default:
        return 'application/octet-stream';
    }
  }

  String _stripExtension(String name) {
    final i = name.lastIndexOf('.');
    return i <= 0 ? name : name.substring(0, i);
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
              // ---- Cloudflare Stream -----------------------------------
              // When set, this UID takes precedence over the Firebase
              // Storage `mediaUrl` below. The player resolves it through
              // the `resolveStreamPlayback` Cloud Function so the API
              // token stays server-side.
              Text('Cloudflare Stream video',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),

              // ── One-click upload to Cloudflare Stream ──────────
              // Picks a local video file and POSTs it directly to a
              // one-time URL minted by the createCloudflareUpload
              // Cloud Function. The UID is filled in automatically on
              // success — no Cloudflare dashboard round-trip needed.
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _cfBusy
                        ? 'Uploading…'
                        : _draft.cloudflareVideoId == null
                            ? 'Upload video file'
                            : 'Replace video file',
                  ),
                  onPressed: _cfBusy ? null : _uploadCloudflare,
                ),
              ),
              if (_cfProgress != null) ...[
                const SizedBox(height: 8),
                _CloudflareProgressIndicator(progress: _cfProgress!),
              ],
              const SizedBox(height: 12),

              TextField(
                controller: _cloudflareId,
                decoration: const InputDecoration(
                  labelText: 'Video UID (32 hex chars)',
                  hintText: 'bf53017eb20e5db311c21d30ffb5a075',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => _draft.cloudflareVideoId =
                    v.trim().isEmpty ? null : v.trim(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Auto-filled after Upload. Or paste manually: find the '
                  'UID in Cloudflare Stream → your video → URL (e.g. '
                  'cloudflarestream.com/<uid>/manifest/video.m3u8).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Divider(height: 32),
              Text('Media file (legacy fallback)',
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

              // ---- Resources -------------------------------------
              // Attached PDFs / audio / docs surfaced to students
              // below the player in the consumer app. See
              // `DocumentLectureResourceTile` for the renderer.
              const Divider(height: 32),
              Text('Resources',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Sheet music, backing tracks, exercise PDFs — anything '
                'students should be able to download alongside the lecture.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              if (_draft.resources.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No resources attached yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final r in _draft.resources)
                      _ResourceRow(
                        resource: r,
                        onRename: () => _renameResource(r),
                        onRemove: () => _removeResource(r),
                      ),
                  ],
                ),
              if (_resourceProgress != null && !_resourceProgress!.isTerminal)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: LinearProgressIndicator(
                    value: _resourceProgress!.fraction,
                  ),
                ),
              if (_resourceProgress?.phase == UploadPhase.failed)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Upload failed: ${_resourceProgress?.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(
                    _resourceProgress != null &&
                            !_resourceProgress!.isTerminal
                        ? 'Uploading…'
                        : 'Add resource',
                  ),
                  onPressed: (_resourceProgress != null &&
                          !_resourceProgress!.isTerminal)
                      ? null
                      : _pickResource,
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

/// Single row inside the "Resources" panel of the lecture editor.
/// Icon + display name + format chip + rename / remove buttons.
class _ResourceRow extends StatelessWidget {
  const _ResourceRow({
    required this.resource,
    required this.onRename,
    required this.onRemove,
  });
  final LectureResourceModel resource;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  IconData get _icon {
    switch (resource.format.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'mp3':
      case 'm4a':
      case 'wav':
      case 'aac':
        return Icons.audiotrack_outlined;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(_icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${resource.format.toUpperCase()} · '
                  '${_formatBytes(resource.sizeBytes)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(Icons.edit_outlined),
            visualDensity: VisualDensity.compact,
            onPressed: onRename,
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close, color: Colors.red),
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Tiny status block shown under the "Upload video file" button while
/// a Cloudflare Stream upload is in flight (or after it completes /
/// fails). Renders a determinate progress bar during upload and a
/// success / error line afterwards.
class _CloudflareProgressIndicator extends StatelessWidget {
  const _CloudflareProgressIndicator({required this.progress});
  final CloudflareUploadProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (progress.phase) {
      case CloudflareUploadPhase.requestingUrl:
        return Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text('Requesting upload URL…',
                style: theme.textTheme.bodySmall),
          ],
        );
      case CloudflareUploadPhase.uploading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: progress.fraction),
            const SizedBox(height: 4),
            Text(
              'Uploading to Cloudflare Stream… '
              '${(progress.fraction * 100).round()}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      case CloudflareUploadPhase.completed:
        return Text(
          'Upload complete · UID ${progress.videoUid}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.w600,
          ),
        );
      case CloudflareUploadPhase.failed:
        return Text(
          'Upload failed: ${progress.error}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.red,
          ),
        );
    }
  }
}
