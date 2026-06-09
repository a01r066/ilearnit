import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/courses/data/models/course_model.dart';
import '../../../features/learning_paths/data/models/learning_path_model.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';

/// Editor for a single learning path — flat, single-page layout.
///
/// Removed widgets that were the root cause of the hover hit-test
/// floods on the previous version:
///   • `Form` + `TextFormField` validators (use plain TextField + save
///     button validates inline)
///   • `DropdownButtonFormField` (replaced by `ChoiceChip` Wrap)
///   • `ReorderableListView` + `ListTile` (replaced by hand-rolled
///     Container rows with up/down arrows)
///   • Bare `Material` panel wrappers without explicit dimensions
///   • Any `FilledButton.icon` next to an `Expanded` in a Row without
///     an explicit `SizedBox`
class LearningPathEditorPage extends ConsumerStatefulWidget {
  const LearningPathEditorPage({super.key, required this.pathId});

  final String pathId;

  @override
  ConsumerState<LearningPathEditorPage> createState() =>
      _LearningPathEditorPageState();
}

class _LearningPathEditorPageState
    extends ConsumerState<LearningPathEditorPage> {
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _totalHours = TextEditingController();

  String? _coverUrl;
  String? _instrumentId; // null = "Mixed"
  List<String> _courseIds = const <String>[];
  bool _isPublished = false;

  bool _hydrated = false;
  bool _uploadingCover = false;
  bool _saving = false;
  String _coursePickerQuery = '';

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _totalHours.dispose();
    super.dispose();
  }

  void _hydrate(LearningPathModel m) {
    _title.text = m.title;
    _summary.text = m.summary;
    _totalHours.text = m.totalHours.toString();
    _coverUrl = m.coverUrl?.isEmpty == true ? '' : m.coverUrl;
    _instrumentId = m.instrument;
    _courseIds = [...m.courseIds];
    _isPublished = m.isPublished;
    _hydrated = true;
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;

    setState(() => _uploadingCover = true);
    try {
      final storage = ref.read(adminStorageServiceProvider);
      final url = await storage.uploadLearningPathCover(
        pathId: widget.pathId,
        filename:
            'cover_${DateTime.now().millisecondsSinceEpoch}_${file.name}',
        bytes: file.bytes!,
        contentType: 'image/${file.extension ?? 'jpeg'}',
      );
      setState(() => _coverUrl = url);
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminLearningPathsDataSourceProvider).update(
            pathId: widget.pathId,
            title: _title.text.trim(),
            summary: _summary.text.trim(),
            coverUrl: _coverUrl ?? '',
            instrumentId: _instrumentId ?? '',
            courseIds: _courseIds,
            totalHours: double.tryParse(_totalHours.text) ?? 0,
            isPublished: _isPublished,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addCourse(String courseId) {
    if (_courseIds.contains(courseId)) return;
    setState(() => _courseIds = [..._courseIds, courseId]);
  }

  void _removeCourse(int index) {
    setState(() {
      final next = [..._courseIds]..removeAt(index);
      _courseIds = next;
    });
  }

  void _moveCourse(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _courseIds.length) return;
    setState(() {
      final next = [..._courseIds];
      final item = next.removeAt(index);
      next.insert(target, item);
      _courseIds = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pathStream = ref
        .watch(adminLearningPathsDataSourceProvider)
        .watchById(widget.pathId);

    return StreamBuilder<LearningPathModel?>(
      stream: pathStream,
      builder: (context, snap) {
        if (!snap.hasData && !_hydrated) {
          return const Center(child: CircularProgressIndicator());
        }
        final m = snap.data;
        if (m == null) {
          return const Center(child: Text('Path not found.'));
        }
        if (!_hydrated) _hydrate(m);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  title: _title.text.isEmpty ? '(untitled)' : _title.text,
                  isPublished: _isPublished,
                  onTogglePublished: (v) =>
                      setState(() => _isPublished = v),
                  saving: _saving,
                  onSave: _save,
                  onBack: () =>
                      context.goNamed(AdminRoutes.learningPaths),
                ),
                const SizedBox(height: 24),
                _MetadataPanel(
                  titleCtrl: _title,
                  summaryCtrl: _summary,
                  totalHoursCtrl: _totalHours,
                  instrumentId: _instrumentId,
                  onInstrumentChanged: (v) =>
                      setState(() => _instrumentId = v),
                ),
                const SizedBox(height: 24),
                _CoverPanel(
                  url: _coverUrl,
                  uploading: _uploadingCover,
                  onPick: _pickCover,
                ),
                const SizedBox(height: 24),
                _CoursesPanel(
                  selected: _courseIds,
                  query: _coursePickerQuery,
                  onQueryChanged: (v) =>
                      setState(() => _coursePickerQuery = v),
                  onAdd: _addCourse,
                  onRemove: _removeCourse,
                  onMove: _moveCourse,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------- Header --------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.isPublished,
    required this.onTogglePublished,
    required this.saving,
    required this.onSave,
    required this.onBack,
  });

  final String title;
  final bool isPublished;
  final ValueChanged<bool> onTogglePublished;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
        ),
        Expanded(
          child: Text(title, style: theme.textTheme.headlineSmall),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isPublished ? 'Published' : 'Draft'),
            Switch.adaptive(value: isPublished, onChanged: onTogglePublished),
          ],
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 140,
          child: FilledButton.icon(
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save'),
            onPressed: saving ? null : onSave,
          ),
        ),
      ],
    );
  }
}

// ---------- Metadata ------------------------------------------------------

class _MetadataPanel extends StatelessWidget {
  const _MetadataPanel({
    required this.titleCtrl,
    required this.summaryCtrl,
    required this.totalHoursCtrl,
    required this.instrumentId,
    required this.onInstrumentChanged,
  });

  final TextEditingController titleCtrl;
  final TextEditingController summaryCtrl;
  final TextEditingController totalHoursCtrl;
  final String? instrumentId;
  final ValueChanged<String?> onInstrumentChanged;

  static const _instruments = <MapEntry<String?, String>>[
    MapEntry<String?, String>(null, 'Mixed'),
    MapEntry<String?, String>('guitar', 'Guitar'),
    MapEntry<String?, String>('piano', 'Piano'),
    MapEntry<String?, String>('violin', 'Violin'),
  ];

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
            controller: titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: summaryCtrl,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Summary',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: totalHoursCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Total hours',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Instrument',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _instruments)
                ChoiceChip(
                  label: Text(e.value),
                  selected: instrumentId == e.key,
                  onSelected: (s) {
                    if (s) onInstrumentChanged(e.key);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Cover panel ---------------------------------------------------

class _CoverPanel extends StatelessWidget {
  const _CoverPanel({
    required this.url,
    required this.uploading,
    required this.onPick,
  });

  final String? url;
  final bool uploading;
  final VoidCallback onPick;

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
          Text('Cover',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 240,
                height: 135,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: (url == null || url!.isEmpty)
                    ? const Center(
                        child: Icon(Icons.image_outlined, size: 40))
                    : Image.network(
                        url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined,
                              size: 40),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 180,
                child: OutlinedButton.icon(
                  icon: uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_outlined),
                  label: Text(url == null ? 'Upload cover' : 'Replace'),
                  onPressed: uploading ? null : onPick,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Courses panel -------------------------------------------------

class _CoursesPanel extends ConsumerWidget {
  const _CoursesPanel({
    required this.selected,
    required this.query,
    required this.onQueryChanged,
    required this.onAdd,
    required this.onRemove,
    required this.onMove,
  });

  final List<String> selected;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int index, int delta) onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coursesStream =
        ref.watch(adminCoursesDataSourceProvider).watchAllCourses();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: StreamBuilder<List<CourseModel>>(
        stream: coursesStream,
        builder: (context, snap) {
          final all = snap.data ?? const <CourseModel>[];
          final byId = <String, CourseModel>{
            for (final c in all) c.id: c,
          };

          // Filter for the add-picker: hide already-selected and
          // apply the query.
          final filtered = (query.isEmpty
                  ? all.take(8).toList()
                  : all
                      .where((c) => c.title
                          .toLowerCase()
                          .contains(query.toLowerCase()))
                      .take(20)
                      .toList())
              .where((c) => !selected.contains(c.id))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Courses in order (${selected.length})',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (selected.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No courses added yet — search below to add one.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < selected.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SelectedCourseRow(
                          index: i,
                          course: byId[selected[i]],
                          courseId: selected[i],
                          canMoveUp: i > 0,
                          canMoveDown: i < selected.length - 1,
                          onUp: () => onMove(i, -1),
                          onDown: () => onMove(i, 1),
                          onRemove: () => onRemove(i),
                        ),
                      ),
                  ],
                ),
              const Divider(height: 32),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Add a course by title',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: onQueryChanged,
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No matching courses.'),
                )
              else
                Column(
                  children: [
                    for (final c in filtered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _CandidateCourseRow(
                          course: c,
                          onAdd: () => onAdd(c.id),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectedCourseRow extends StatelessWidget {
  const _SelectedCourseRow({
    required this.index,
    required this.course,
    required this.courseId,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onUp,
    required this.onDown,
    required this.onRemove,
  });

  final int index;
  final CourseModel? course;
  final String courseId;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Text('${index + 1}',
                style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course?.title ?? '(course not found)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  course?.instructorName ?? courseId,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Move up',
            icon: const Icon(Icons.arrow_upward),
            onPressed: canMoveUp ? onUp : null,
          ),
          IconButton(
            tooltip: 'Move down',
            icon: const Icon(Icons.arrow_downward),
            onPressed: canMoveDown ? onDown : null,
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _CandidateCourseRow extends StatelessWidget {
  const _CandidateCourseRow({required this.course, required this.onAdd});
  final CourseModel course;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${course.category} · ${course.instructorName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline),
            ],
          ),
        ),
      ),
    );
  }
}
