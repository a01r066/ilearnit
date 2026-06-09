import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/songbooks/data/models/songbook_model.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';

/// Minimal "Songbooks" list — flat page, no `Card` wrapping the list,
/// no `ListTile`, no `PopupMenuButton`, no `FilledButton.icon` in an
/// unconstrained Row. Image.network always has an `errorBuilder`.
class AdminSongbooksPage extends ConsumerStatefulWidget {
  const AdminSongbooksPage({super.key});

  @override
  ConsumerState<AdminSongbooksPage> createState() =>
      _AdminSongbooksPageState();
}

class _AdminSongbooksPageState extends ConsumerState<AdminSongbooksPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(adminSongbooksDataSourceProvider).watchAll();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title row.
          Text('Songbooks', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          // Filter + button row — every right-side widget is in a
          // bounded SizedBox.
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Filter by title or publisher',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New songbook'),
                  onPressed: _createSongbook,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List body.
          Expanded(
            child: StreamBuilder<List<SongbookModel>>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data!;
                final items = _query.isEmpty
                    ? all
                    : all.where((s) =>
                        s.title.toLowerCase().contains(_query) ||
                        s.publisher.toLowerCase().contains(_query)).toList();
                if (items.isEmpty) {
                  return Center(
                    child: Text('No songbooks match.',
                        style: theme.textTheme.bodyLarge),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _SongbookRow(book: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createSongbook() async {
    final titleCtrl = TextEditingController(text: 'Untitled songbook');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create songbook'),
        content: TextField(
          controller: titleCtrl,
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
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final id = await ref.read(adminSongbooksDataSourceProvider).create(
          SongbookModel(
            id: '', // populated by datasource
            title: titleCtrl.text.trim(),
            instrument: 'Piano',
            publisher: '',
            productId: '',
          ),
        );
    if (mounted) {
      context.goNamed(
        AdminRoutes.songbookEditor,
        pathParameters: {'id': id},
      );
    }
  }
}

/// Hand-rolled row — Material+InkWell+Container rather than ListTile +
/// PopupMenuButton. Each action is an `IconButton` so the row has no
/// `[Expanded, FilledButton.icon]` mix to trigger the intrinsic-width
/// pass.
class _SongbookRow extends ConsumerWidget {
  const _SongbookRow({required this.book});
  final SongbookModel book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.goNamed(
          AdminRoutes.songbookEditor,
          pathParameters: {'id': book.id},
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 60,
                child: book.coverUrl.isEmpty
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.book_outlined),
                      )
                    : Image.network(
                        book.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child:
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    Text(
                      '${book.instrument} · ${book.publisher.isEmpty ? "—" : book.publisher}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (book.isBestseller)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Bestseller',
                      style: TextStyle(fontSize: 12)),
                ),
              IconButton(
                tooltip: book.isBestseller
                    ? 'Unmark as bestseller'
                    : 'Mark as bestseller',
                icon: Icon(
                  book.isBestseller ? Icons.star : Icons.star_border,
                ),
                onPressed: () => ref
                    .read(adminSongbooksDataSourceProvider)
                    .setBestseller(book.id, !book.isBestseller),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete songbook?'),
        content: Text(
          '"${book.title}" and all of its reviews will be permanently '
          'deleted from Firestore. Storage files (cover/banner) remain '
          '— clean those up separately.',
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
    if (ok == true) {
      await ref.read(adminSongbooksDataSourceProvider).delete(book.id);
    }
  }
}
