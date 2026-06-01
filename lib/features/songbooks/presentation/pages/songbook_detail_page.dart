import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/providers/storage_providers.dart';
import '../../data/models/songbook_model.dart';
import '../../data/models/songbook_review_model.dart';
import '../providers/songbook_providers.dart';
import '../widgets/songbook_card.dart';

/// Detail page for a single songbook. Pushes to recent-viewed MRU on
/// mount so the Songbooks tab carousel reflects the visit.
class SongbookDetailPage extends ConsumerStatefulWidget {
  const SongbookDetailPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<SongbookDetailPage> createState() =>
      _SongbookDetailPageState();
}

class _SongbookDetailPageState extends ConsumerState<SongbookDetailPage> {
  bool _expandedDescription = false;
  bool _expandedIncludes = false;
  bool _favorite = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    // Stamp the MRU on the next frame so it's persisted by the time the
    // user backs out.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(prefsProvider).pushRecentSongbook(widget.id);
      ref.invalidate(recentlyViewedSongbooksProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(songbookByIdProvider(widget.id));
    return Scaffold(
      body: book.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (b) {
          if (b == null) {
            return const Center(child: Text('Songbook not found.'));
          }
          return _Body(
            book: b,
            expandedDescription: _expandedDescription,
            expandedIncludes: _expandedIncludes,
            favorite: _favorite,
            saved: _saved,
            onExpandDescription: () =>
                setState(() => _expandedDescription = true),
            onExpandIncludes: () => setState(() => _expandedIncludes = true),
            onToggleFavorite: () => setState(() => _favorite = !_favorite),
            onToggleSaved: () => setState(() => _saved = !_saved),
          );
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.book,
    required this.expandedDescription,
    required this.expandedIncludes,
    required this.favorite,
    required this.saved,
    required this.onExpandDescription,
    required this.onExpandIncludes,
    required this.onToggleFavorite,
    required this.onToggleSaved,
  });

  final SongbookModel book;
  final bool expandedDescription;
  final bool expandedIncludes;
  final bool favorite;
  final bool saved;
  final VoidCallback onExpandDescription;
  final VoidCallback onExpandIncludes;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(songbookReviewsProvider(book.id));
    final similar = ref.watch(similarSongbooksProvider(book.id));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: false,
          floating: true,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {},
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            // Banner image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: book.bannerUrl.isEmpty
                  ? Container(color: context.colors.surfaceContainerHighest)
                  : CachedNetworkImage(
                      imageUrl: book.bannerUrl.isNotEmpty
                          ? book.bannerUrl
                          : book.coverUrl,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 24),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                book.title,
                style: context.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Primary CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    // TODO: wire to IAP/subscription flow.
                  },
                  child: const Text(
                    'Get Songbook',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Action row
            _ActionRow(
              saved: saved,
              favorite: favorite,
              onSaveTap: onToggleSaved,
              onSampleTap: () {},
              onFavoriteTap: onToggleFavorite,
              onShareTap: () {},
            ),
            const SizedBox(height: 24),
            _RatingRow(book: book),
            const SizedBox(height: 16),
            _Description(
              book: book,
              expanded: expandedDescription,
              onExpand: onExpandDescription,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _Includes(
              book: book,
              expanded: expandedIncludes,
              onExpand: onExpandIncludes,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 24),
            _MetadataRow(book: book),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _ReviewsSection(bookId: book.id, reviews: reviews),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _SimilarSection(state: similar),
            const SizedBox(height: 32),
          ]),
        ),
      ],
    );
  }
}

// ---------- Action row ----------------------------------------------------

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.saved,
    required this.favorite,
    required this.onSaveTap,
    required this.onSampleTap,
    required this.onFavoriteTap,
    required this.onShareTap,
  });
  final bool saved;
  final bool favorite;
  final VoidCallback onSaveTap;
  final VoidCallback onSampleTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _PillButton(
              icon: saved ? Icons.favorite : Icons.favorite_outline,
              label: 'Save',
              onTap: onSaveTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PillButton(
              icon: Icons.description_outlined,
              label: 'Sample',
              onTap: onSampleTap,
            ),
          ),
          const SizedBox(width: 8),
          _IconPill(
            icon: favorite ? Icons.star : Icons.star_outline,
            onTap: onFavoriteTap,
          ),
          const SizedBox(width: 8),
          _IconPill(icon: Icons.ios_share, onTap: onShareTap),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  const _IconPill({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

// ---------- Rating, description, includes ---------------------------------

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.book});
  final SongbookModel book;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.star, size: 18),
          const SizedBox(width: 4),
          Text(
            book.rating.toStringAsFixed(2),
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· ${book.instrument}',
            style: context.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({
    required this.book,
    required this.expanded,
    required this.onExpand,
  });
  final SongbookModel book;
  final bool expanded;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final text = book.description;
    final tooLong = text.length > 150;
    final body = expanded || !tooLong ? text : '${text.substring(0, 150)}…';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RichText(
        text: TextSpan(
          style: context.textTheme.bodyLarge,
          children: [
            TextSpan(text: body),
            if (tooLong && !expanded)
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: onExpand,
                  child: Text(
                    ' view all',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Includes extends StatelessWidget {
  const _Includes({
    required this.book,
    required this.expanded,
    required this.onExpand,
  });
  final SongbookModel book;
  final bool expanded;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final shown = expanded
        ? book.includes
        : book.includes.take(7).toList();
    final more = book.includes.length > shown.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Includes',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: context.textTheme.bodyLarge,
              children: [
                TextSpan(text: shown.join(', ')),
                if (more)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: onExpand,
                      child: Text(
                        ' view all',
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.book});
  final SongbookModel book;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _MetaCol(
              label: 'INSTRUMENT',
              value: book.instrument,
            ),
          ),
          Expanded(
            child: _MetaCol(
              label: 'TOPICS',
              value: book.topics.isEmpty ? '—' : book.topics.first,
            ),
          ),
          Expanded(
            child: _MetaCol(
              label: 'PUBLISHER',
              value: book.publisher,
              align: TextAlign.left,
            ),
          ),
        ],
      ).withDividerBetween(theme.dividerColor),
    );
  }
}

class _MetaCol extends StatelessWidget {
  const _MetaCol({
    required this.label,
    required this.value,
    this.align = TextAlign.center,
  });
  final String label;
  final String value;
  final TextAlign align;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            letterSpacing: 1.2,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: align,
        ),
      ],
    );
  }
}

/// Small extension to drop thin vertical dividers between Row children —
/// used by the INSTRUMENT / TOPICS / PUBLISHER strip.
extension _RowDivider on Row {
  Widget withDividerBetween(Color color) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      out.add(children[i]);
      if (i != children.length - 1) {
        out.add(SizedBox(
          height: 56,
          child: VerticalDivider(width: 1, color: color),
        ));
      }
    }
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: out,
    );
  }
}

// ---------- Reviews -------------------------------------------------------

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.bookId, required this.reviews});
  final String bookId;
  final AsyncValue<List<SongbookReviewModel>> reviews;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMMM');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          reviews.when(
            loading: () => Text('Reviews',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            error: (_, __) => Text('Reviews —',
                style: context.textTheme.titleLarge),
            data: (list) => Row(
              children: [
                Text('Reviews',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(width: 6),
                Text('${list.length}',
                    style: context.textTheme.titleLarge),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 12),
          reviews.when(
            loading: () =>
                const SizedBox(height: 80, child: LinearProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) {
              if (list.isEmpty) {
                return Text(
                  'No reviews yet.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                );
              }
              final r = list.first;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.body,
                      style: context.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.createdAt == null
                          ? r.userName
                          : '${fmt.format(r.createdAt!)}, ${r.userName}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------- Similar -------------------------------------------------------

class _SimilarSection extends StatelessWidget {
  const _SimilarSection({required this.state});
  final AsyncValue<List<SongbookModel>> state;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('You might also like',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  )),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox.shrink(),
            data: (items) => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SongbookCard.compact(
                book: items[i],
                width: 130,
                onTap: () => context.pushNamed(
                  RouteNames.songbookDetail,
                  pathParameters: {'id': items[i].id},
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
