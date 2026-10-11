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
import '../widgets/songbook_reader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../purchases/presentation/providers/purchases_providers.dart';
import '../../../../l10n/l10n.dart';

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
        error: (e, _) => Center(child: Text(context.l10n.songbookLoadFailed)),
        data: (b) {
          if (b == null) {
            return Center(child: Text(context.l10n.songbookNotFound));
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
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => context.pop(),
          ),
          // (Placeholder profile button with no action removed — a dead
          // control is an App Review 2.1 risk.)
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
            // Primary CTA — Get / Open (hidden until the admin uploads
            // the PDF; see _GetSongbookButton).
            _GetSongbookButton(book: book),
            const SizedBox(height: 12),
            // Action row
            _ActionRow(
              saved: saved,
              favorite: favorite,
              onSaveTap: onToggleSaved,
              onSampleTap: book.samplePages.isEmpty
                  ? null
                  : () => showSongbookSample(context, book.samplePages),
              onFavoriteTap: onToggleFavorite,
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

// ---------- Get / Open CTA -----------------------------------------------

class _GetSongbookButton extends ConsumerStatefulWidget {
  const _GetSongbookButton({required this.book});
  final SongbookModel book;

  @override
  ConsumerState<_GetSongbookButton> createState() => _GetSongbookButtonState();
}

class _GetSongbookButtonState extends ConsumerState<_GetSongbookButton> {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    if (widget.book.productId.isNotEmpty) {
      Future.microtask(() => ref
          .read(songbookPurchasesNotifierProvider.notifier)
          .loadPrice(widget.book.productId));
    }
  }

  Future<void> _open() async {
    setState(() => _opening = true);
    await openSongbook(context, ref, widget.book.id);
    if (mounted) setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final book = widget.book;

    ref.listen<String?>(
      songbookPurchasesNotifierProvider.select((s) => s.lastError),
      (_, err) {
        if (err == null) return;
        context.showSnack(err);
        ref.read(songbookPurchasesNotifierProvider.notifier).clearError();
      },
    );

    final hasContent =
        ref.watch(songbookHasContentProvider(book.id)).value ?? false;
    if (!hasContent) return const SizedBox.shrink();

    final hasAccess = ref.watch(hasSongbookAccessProvider(book.id));
    final purchases = ref.watch(songbookPurchasesNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final storeAvailable = ref.watch(purchasesNotifierProvider).isAvailable;

    VoidCallback? onPressed;
    Widget label;
    if (hasAccess) {
      onPressed = _opening ? null : _open;
      label = _opening
          ? const _ButtonSpinner()
          : Text(t.songbookOpen, style: _ctaStyle);
    } else {
      if (book.productId.isEmpty || !storeAvailable) {
        return const SizedBox.shrink();
      }
      final buying = purchases.isBuying(book.productId);
      final price = purchases.priceByProductId[book.productId];
      onPressed = buying
          ? null
          : () {
              if (user == null) {
                context.showSnack(t.songbookSignInToGet);
                context.goNamed(RouteNames.login);
                return;
              }
              ref
                  .read(songbookPurchasesNotifierProvider.notifier)
                  .buy(book.productId);
            };
      label = buying
          ? const _ButtonSpinner()
          : Text(
              price == null ? t.songbookGet : t.songbookGetForPrice(price),
              style: _ctaStyle,
            );
    }

    return Padding(
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
          onPressed: onPressed,
          child: label,
        ),
      ),
    );
  }

  static const _ctaStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
}

// ---------- Action row ----------------------------------------------------

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.saved,
    required this.favorite,
    required this.onSaveTap,
    required this.onSampleTap,
    required this.onFavoriteTap,
  });
  final bool saved;
  final bool favorite;
  final VoidCallback onSaveTap;

  /// Null when the songbook has no sample pages — the pill is hidden.
  final VoidCallback? onSampleTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _PillButton(
              icon: saved ? Icons.favorite : Icons.favorite_outline,
              label: context.l10n.songbookSave,
              onTap: onSaveTap,
            ),
          ),
          if (onSampleTap != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _PillButton(
                icon: Icons.description_outlined,
                label: context.l10n.songbookSample,
                onTap: onSampleTap!,
              ),
            ),
          ],
          const SizedBox(width: 8),
          _IconPill(
            icon: favorite ? Icons.star : Icons.star_outline,
            onTap: onFavoriteTap,
          ),
          // (Share pill removed until sharing is implemented.)
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
                child: Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: onExpand,
                    child: Text(
                      ' ${context.l10n.songbookViewAll}',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: AppColors.primary,
                      ),
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
          Text(context.l10n.songbookIncludes,
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
                    child: Semantics(
                      button: true,
                      child: GestureDetector(
                        onTap: onExpand,
                        child: Text(
                          ' ${context.l10n.songbookViewAll}',
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: AppColors.primary,
                          ),
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
              label: context.l10n.songbookInstrument,
              value: book.instrument,
            ),
          ),
          Expanded(
            child: _MetaCol(
              label: context.l10n.songbookTopics,
              value: book.topics.isEmpty ? '—' : book.topics.first,
            ),
          ),
          Expanded(
            child: _MetaCol(
              label: context.l10n.songbookPublisher,
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
            loading: () => Text(context.l10n.songbookReviews,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            error: (_, __) => Text('${context.l10n.songbookReviews} —',
                style: context.textTheme.titleLarge),
            data: (list) => Row(
              children: [
                Text(context.l10n.songbookReviews,
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
                  context.l10n.songbookNoReviewsYet,
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
              Text(context.l10n.songbookYouMightAlsoLike,
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
