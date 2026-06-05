import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/songbooks/data/models/songbook_model.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';

/// Admin-only: every songbook in the catalogue. Mirrors AdminCoursesPage —
/// filter input, list of rows with bestseller chip + edit/delete actions.
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
          Row(
            children: [
              Expanded(
                child: Text('Songbooks',
                    style: theme.textTheme.headlineMedium),
              ),
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Filter by title or publisher',
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New songbook'),
                onPressed: _createSongbook,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                return Card(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _SongbookRow(book: items[i]),
                  ),
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

class _SongbookRow extends ConsumerWidget {
  const _SongbookRow({required this.book});
  final SongbookModel book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 60,
        child: book.coverUrl.isEmpty
            ? Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.book_outlined),
              )
            : Image.network(book.coverUrl, fit: BoxFit.cover),
      ),
      title: Text(book.title),
      subtitle: Text(
        '${book.instrument} · ${book.publisher.isEmpty ? "—" : book.publisher}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (book.isBestseller)
            Chip(
              label: const Text('Bestseller'),
              visualDensity: VisualDensity.compact,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.10),
            ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (a) => _action(context, ref, a),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'open', child: Text('Open editor')),
              PopupMenuItem(
                value: 'bestseller',
                child: Text(book.isBestseller
                    ? 'Unmark as bestseller'
                    : 'Mark as bestseller'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      onTap: () => context.goNamed(
        AdminRoutes.songbookEditor,
        pathParameters: {'id': book.id},
      ),
    );
  }

  Future<void> _action(
      BuildContext context, WidgetRef ref, String action) async {
    final ds = ref.read(adminSongbooksDataSourceProvider);
    switch (action) {
      case 'open':
        context.goNamed(AdminRoutes.songbookEditor,
            pathParameters: {'id': book.id});
        break;
      case 'bestseller':
        await ds.setBestseller(book.id, !book.isBestseller);
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete songbook?'),
            content: Text(
                '"${book.title}" and all of its reviews will be permanently '
                'deleted from Firestore. Storage files (cover/banner) remain — '
                'clean those up separately.'),
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
        if (ok == true) await ds.delete(book.id);
        break;
    }
  }
}
