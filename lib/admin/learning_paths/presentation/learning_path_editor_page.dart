import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/courses/data/models/course_model.dart';
import '../../../features/courses/domain/entities/instrument_category.dart';
import '../../../features/learning_paths/data/models/learning_path_model.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';

/// Editor for a single learning path. Lives at
/// `/admin/learning-paths/:id`. The admin list page creates a fresh
/// draft and routes here.
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
  final _formKey = GlobalKey<FormState>();

  String? _coverUrl;
  String? _instrumentId; // null = "Mixed"
  List<String> _courseIds = const <String>[];
  bool _isPublished = false;

  bool _hydrated = false;
  bool _uploadingCover = false;
  bool _saving = false;

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
    _coverUrl = m.coverUrl;
    _instrumentId = m.instrument;
    _courseIds = [...m.courseIds];
    _isPublished = m.isPublished;
    _hydrated = true;
  }

  @override
  Widget build(BuildContext context) {
    final pathStream =
        ref.watch(adminLearningPathsDataSourceProvider).watchById(widget.pathId);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<LearningPathModel?>(
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

          return Form(
            key: _formKey,
            child: ListView(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.goNamed(
                          AdminRoutes.learningPaths),
                    ),
                    Expanded(
                      child: Text(
                        m.title.isEmpty ? '(untitled)' : m.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Switch.adaptive(
                      value: _isPublished,
                      onChanged: (v) =>
                          setState(() => _isPublished = v),
                    ),
                    Text(_isPublished ? 'Published' : 'Draft'),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      label: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Text('Save'),
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ----- Cover --------------------------------------------------
                _SectionLabel('Cover'),
                _CoverPicker(
                  url: _coverUrl,
                  uploading: _uploadingCover,
                  onPick: _pickCover,
                ),
                const SizedBox(height: 24),

                // ----- Metadata ----------------------------------------------
                _SectionLabel('Title'),
                TextFormField(
                  controller: _title,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _SectionLabel('Summary'),
                TextFormField(
                  controller: _summary,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('Total hours'),
                          TextFormField(
                            controller: _totalHours,
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              return double.tryParse(v) == null
                                  ? 'Enter a number'
                                  : null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('Instrument'),
                          DropdownButtonFormField<String?>(
                            value: _instrumentId,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Mixed'),
                              ),
                              DropdownMenuItem(
                                value: 'guitar',
                                child: Text('Guitar'),
                              ),
                              DropdownMenuItem(
                                value: 'piano',
                                child: Text('Piano'),
                              ),
                              DropdownMenuItem(
                                value: 'violin',
                                child: Text('Violin'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _instrumentId = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ----- Courses -----------------------------------------------
                _SectionLabel(
                    'Courses in order (${_courseIds.length})'),
                _CoursesPicker(
                  selected: _courseIds,
                  onChanged: (next) => setState(() => _courseIds = next),
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null) return;

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
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ---------- Cover picker --------------------------------------------------

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.url,
    required this.uploading,
    required this.onPick,
  });

  final String? url;
  final bool uploading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 240,
          height: 135,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            image: (url != null && url!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(url!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: (url == null || url!.isEmpty)
              ? const Icon(Icons.image_outlined, size: 40)
              : null,
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          icon: uploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_outlined),
          label: const Text('Replace cover'),
          onPressed: uploading ? null : onPick,
        ),
      ],
    );
  }
}

// ---------- Courses multi-select -----------------------------------------

class _CoursesPicker extends ConsumerStatefulWidget {
  const _CoursesPicker({required this.selected, required this.onChanged});

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  ConsumerState<_CoursesPicker> createState() => _CoursesPickerState();
}

class _CoursesPickerState extends ConsumerState<_CoursesPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final coursesStream =
        ref.watch(adminCoursesDataSourceProvider).watchAllCourses();
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected (ordered) row — drag handle reorders.
            if (widget.selected.isNotEmpty)
              StreamBuilder<List<CourseModel>>(
                stream: coursesStream,
                builder: (context, snap) {
                  // Explicit typing — the empty-list fallback was inferring
                  // `List<dynamic>`, which propagated to a
                  // `Map<dynamic, dynamic>` and broke `Text(course?.title)`.
                  final byId = <String, CourseModel>{
                    for (final c in snap.data ?? const <CourseModel>[])
                      c.id: c,
                  };
                  return SizedBox(
                    height: 220,
                    child: ReorderableListView.builder(
                      itemCount: widget.selected.length,
                      onReorder: (oldIndex, newIndex) {
                        final next = [...widget.selected];
                        if (newIndex > oldIndex) newIndex--;
                        final id = next.removeAt(oldIndex);
                        next.insert(newIndex, id);
                        widget.onChanged(next);
                      },
                      itemBuilder: (_, i) {
                        final id = widget.selected[i];
                        final course = byId[id];
                        return ListTile(
                          key: ValueKey(id),
                          leading: CircleAvatar(child: Text('${i + 1}')),
                          title: Text(
                            course?.title ?? '(course not found)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle:
                              Text(course?.instructorName ?? id),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              final next = [...widget.selected]
                                ..removeAt(i);
                              widget.onChanged(next);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            const Divider(height: 24),
            // Picker — search + tap to add.
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Add a course by title',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<CourseModel>>(
              stream: coursesStream,
              builder: (context, snap) {
                final all = snap.data ?? const <CourseModel>[];
                final filtered = (_query.isEmpty
                        ? all.take(8).toList()
                        : all
                            .where((c) => c.title
                                .toLowerCase()
                                .contains(_query.toLowerCase()))
                            .take(20)
                            .toList())
                    .where((c) => !widget.selected.contains(c.id))
                    .toList();
                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No matching courses.'),
                  );
                }
                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${c.category} · ${c.instructorName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () =>
                            widget.onChanged([...widget.selected, c.id]),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Section label ------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

// Silence the unused-import warning if InstrumentCategory is needed in
// future refactors.
// ignore: unused_element
typedef _Unused = InstrumentCategory;
