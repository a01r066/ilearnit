import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/songbooks/data/models/songbook_model.dart';
import '../../courses/data/admin_storage_service.dart';
import '../../shared/providers/admin_providers.dart';

/// Single-page editor for one [SongbookModel].
///
/// Layout: cover/banner uploaders on the right, metadata form on the
/// left (title, description, instrument, publisher, productId, topics,
/// includes, isBestseller). Save button persists the entire model.
class SongbookEditorPage extends ConsumerStatefulWidget {
  const SongbookEditorPage({super.key, required this.songbookId});
  final String songbookId;

  @override
  ConsumerState<SongbookEditorPage> createState() =>
      _SongbookEditorPageState();
}

class _SongbookEditorPageState extends ConsumerState<SongbookEditorPage> {
  @override
  Widget build(BuildContext context) {
    final stream =
        ref.watch(adminSongbooksDataSourceProvider).watchById(widget.songbookId);

    return StreamBuilder<SongbookModel?>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final book = snap.data;
        if (book == null) {
          return const Center(child: Text('Songbook not found.'));
        }
        return _Form(book: book);
      },
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.book});
  final SongbookModel book;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _publisher;
  late final TextEditingController _productId;
  late final TextEditingController _instrument;
  late final TextEditingController _topics;
  late final TextEditingController _includes;

  late bool _isBestseller;
  String? _coverUrl;
  String? _bannerUrl;
  UploadProgress? _coverProgress;
  UploadProgress? _bannerProgress;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _title = TextEditingController(text: b.title);
    _description = TextEditingController(text: b.description);
    _publisher = TextEditingController(text: b.publisher);
    _productId = TextEditingController(text: b.productId);
    _instrument = TextEditingController(text: b.instrument);
    _topics = TextEditingController(text: b.topics.join(', '));
    _includes = TextEditingController(text: b.includes.join(', '));
    _isBestseller = b.isBestseller;
    _coverUrl = b.coverUrl.isEmpty ? null : b.coverUrl;
    _bannerUrl = b.bannerUrl.isEmpty ? null : b.bannerUrl;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _publisher.dispose();
    _productId.dispose();
    _instrument.dispose();
    _topics.dispose();
    _includes.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String input) => input
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminSongbooksDataSourceProvider).update(
            widget.book.copyWith(
              title: _title.text.trim(),
              description: _description.text.trim(),
              publisher: _publisher.text.trim(),
              productId: _productId.text.trim(),
              instrument: _instrument.text.trim(),
              topics: _splitCsv(_topics.text),
              includes: _splitCsv(_includes.text),
              isBestseller: _isBestseller,
              coverUrl: _coverUrl ?? '',
              bannerUrl: _bannerUrl ?? '',
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

  Future<void> _pickImage({required bool isBanner}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final svc = ref.read(adminStorageServiceProvider);
    final stream = isBanner
        ? svc.uploadSongbookBanner(
            songbookId: widget.book.id,
            filename: file.name,
            bytes: bytes,
            contentType: _guessImageType(file.extension),
          )
        : svc.uploadSongbookCover(
            songbookId: widget.book.id,
            filename: file.name,
            bytes: bytes,
            contentType: _guessImageType(file.extension),
          );

    stream.listen((p) {
      if (!mounted) return;
      setState(() {
        if (isBanner) {
          _bannerProgress = p;
          if (p.phase == UploadPhase.completed && p.downloadUrl != null) {
            _bannerUrl = p.downloadUrl;
          }
        } else {
          _coverProgress = p;
          if (p.phase == UploadPhase.completed && p.downloadUrl != null) {
            _coverUrl = p.downloadUrl;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.book.title,
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- Metadata ----------
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _title,
                        decoration:
                            const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _description,
                        minLines: 3,
                        maxLines: 6,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _instrument,
                              decoration: const InputDecoration(
                                labelText: 'Instrument',
                                hintText: 'Piano · Guitar · Mixed',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _publisher,
                              decoration: const InputDecoration(
                                  labelText: 'Publisher'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _productId,
                        decoration: const InputDecoration(
                          labelText: 'IAP product ID',
                          hintText: 'info.ilearnit.songbook.<id>',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _topics,
                        decoration: const InputDecoration(
                          labelText: 'Topics (comma-separated)',
                          hintText: 'Beginner, Pop, Standards',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _includes,
                        minLines: 2,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Includes (comma-separated song titles)',
                          hintText:
                              'Autumn Leaves, Hallelujah, Yesterday, …',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        title: const Text('Bestseller'),
                        contentPadding: EdgeInsets.zero,
                        value: _isBestseller,
                        onChanged: (v) =>
                            setState(() => _isBestseller = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // ---------- Cover + banner uploaders ----------
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ImageBlock(
                        label: 'Cover (3:4)',
                        url: _coverUrl,
                        aspectRatio: 3 / 4,
                        progress: _coverProgress,
                        onPick: () => _pickImage(isBanner: false),
                      ),
                      const SizedBox(height: 16),
                      _ImageBlock(
                        label: 'Banner (16:9)',
                        url: _bannerUrl,
                        aspectRatio: 16 / 9,
                        progress: _bannerProgress,
                        onPick: () => _pickImage(isBanner: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
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
          ],
        ),
      ),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({
    required this.label,
    required this.url,
    required this.aspectRatio,
    required this.progress,
    required this.onPick,
  });

  final String label;
  final String? url;
  final double aspectRatio;
  final UploadProgress? progress;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running =
        progress != null && progress!.phase == UploadPhase.running;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: url == null
                ? const Center(child: Icon(Icons.image_outlined, size: 48))
                : Image.network(url!, fit: BoxFit.cover),
          ),
        ),
        if (running)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(value: progress!.fraction),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.upload_outlined),
          label: Text(url == null ? 'Upload' : 'Replace'),
        ),
      ],
    );
  }
}
