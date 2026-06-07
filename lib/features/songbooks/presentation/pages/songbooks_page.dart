import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/presentation/widgets/notification_bell.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../subscriptions/presentation/providers/subscription_providers.dart';
import '../../data/models/songbook_model.dart';
import '../providers/songbook_providers.dart';
import '../widgets/songbook_card.dart';

/// Songbooks tab — top-level entry point.
///
/// Mirrors the MuseScore design from the attached screenshot:
///   1. Brand row (logo + bell + profile)
///   2. "Start 7-day free trial" promo banner (hidden if user already has
///      an active subscription)
///   3. Pill search bar + filter icon
///   4. Recently Viewed horizontal carousel of large portrait covers
///   5. Bestsellers horizontal carousel
class SongbooksPage extends ConsumerWidget {
  const SongbooksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasSubscription = ref.watch(hasActiveSubscriptionProvider);
    final recents = ref.watch(recentlyViewedSongbooksProvider);
    final bestsellers = ref.watch(bestsellersStreamProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _BrandHeader(),
            if (!hasSubscription) const _TrialBanner(),
            const SizedBox(height: 16),
            const _SearchBarRow(),
            const SizedBox(height: 24),
            // ---------- Recently viewed ----------
            recents.when(
              loading: () =>
                  const _CarouselSkeleton(label: 'Recently Viewed'),
              error: (e, _) =>
                  _SectionFailure(label: 'Recently Viewed', error: e),
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
                return _SectionCarousel(
                  label: 'Recently Viewed',
                  items: items,
                  cardBuilder: (b) => SongbookCard(
                    book: b,
                    onTap: () => context.goNamed(
                      RouteNames.songbookDetail,
                      pathParameters: {'id': b.id},
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // ---------- Bestsellers ----------
            bestsellers.when(
              loading: () =>
                  const _CarouselSkeleton(label: 'Bestsellers'),
              error: (e, _) =>
                  _SectionFailure(label: 'Bestsellers', error: e),
              data: (items) => _SectionCarousel(
                label: 'Bestsellers',
                items: items,
                cardBuilder: (b) => SongbookCard.compact(
                  book: b,
                  onTap: () => context.goNamed(
                    RouteNames.songbookDetail,
                    pathParameters: {'id': b.id},
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------- subwidgets ----------------------------------------------------

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Icon(Icons.music_note_rounded,
              size: 28, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'songbooks',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
          const NotificationBell(),
        ],
      ),
    );
  }
}

class _TrialBanner extends ConsumerWidget {
  const _TrialBanner();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.goNamed(RouteNames.subscription),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
        color: const Color(0xFFE9E1FA),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start 7-day free trial',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to unlock your 7-day free trial',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _SearchBarRow extends StatelessWidget {
  const _SearchBarRow();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.goNamed(RouteNames.search),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(
                      'Search for Songbooks',
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: const Icon(Icons.tune, size: 22),
          ),
        ],
      ),
    );
  }
}

class _SectionCarousel extends StatelessWidget {
  const _SectionCarousel({
    required this.label,
    required this.items,
    required this.cardBuilder,
  });
  final String label;
  final List<SongbookModel> items;
  final Widget Function(SongbookModel) cardBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 276,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => cardBuilder(items[i]),
          ),
        ),
      ],
    );
  }
}

class _CarouselSkeleton extends StatelessWidget {
  const _CarouselSkeleton({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  )),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Container(
              width: 160,
              height: 216,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionFailure extends StatelessWidget {
  const _SectionFailure({required this.label, required this.error});
  final String label;
  final Object error;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(
        '$label — failed to load.\n$error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
