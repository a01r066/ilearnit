import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/instrument_category.dart';
import '../providers/courses_notifier.dart';
import '../providers/courses_providers.dart';
import '../providers/courses_state.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/course_card.dart';
import '../widgets/course_card_skeleton.dart';

/// Catalogue browse page with cursor-paginated infinite scroll.
///
/// Trigger: when the user scrolls past 80% of `maxScrollExtent` we kick
/// `CoursesNotifier.loadNextPage()`. The notifier coalesces concurrent
/// calls so we don't have to debounce here.
class CoursesPage extends ConsumerStatefulWidget {
  const CoursesPage({super.key});

  @override
  ConsumerState<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends ConsumerState<CoursesPage> {
  final _scrollCtrl = ScrollController();

  /// Fraction of [ScrollPosition.maxScrollExtent] past which we trigger a
  /// page fetch. 0.80 matches the roadmap spec.
  static const double _loadMoreThreshold = 0.80;

  /// Last URL filter signature we applied — e.g.
  /// `"category=guitar|featured=true"`. Compared against the current
  /// URL on every build; we only re-apply when the signature changes.
  ///
  /// This is a string (not a bool latch) on purpose. The
  /// `_CoursesPageState` instance persists across tab switches inside
  /// the shell navigator, so a one-shot bool would block a second
  /// "See all" tap from a different home rail. A signature-based
  /// comparison reacts to every URL change but ignores manual filter
  /// changes (which don't touch the URL).
  String? _lastAppliedQuery;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  /// Reads `?category=<id>` and `?featured=true` from the current
  /// route and pushes them into `CoursesNotifier` via a SINGLE atomic
  /// `applyFilters` call. Runs from `build()` (GoRouterState isn't
  /// available in `initState`) but is idempotent — it only fires when
  /// the URL filter signature changes.
  ///
  /// **Race-free.** The single-call shape means one state mutation +
  /// one refresh, instead of two `filterBy*` calls each kicking off
  /// their own refresh that races the constructor's initial refresh.
  /// `CoursesNotifier.refresh()` carries a generation counter so a
  /// stale unfiltered result from the constructor can't overwrite
  /// the filtered result we want.
  void _applyInitialCategory() {
    final qp = GoRouterState.of(context).uri.queryParameters;
    final rawCategory = qp['category'] ?? '';
    final rawFeatured = qp['featured'] ?? '';
    final signature = 'category=$rawCategory|featured=$rawFeatured';
    if (signature == _lastAppliedQuery) return;
    _lastAppliedQuery = signature;

    InstrumentCategory? category;
    if (rawCategory.isNotEmpty) {
      // Strict id match — `InstrumentCategory.fromId` falls back to
      // `piano` for unknown values, which would silently mis-filter
      // on a typo'd deep link.
      for (final c in InstrumentCategory.values) {
        if (c.id == rawCategory) {
          category = c;
          break;
        }
      }
    }
    final featured = rawFeatured == 'true' || rawFeatured == '1';

    // Skip the apply when nothing differs from current state — keeps
    // an idempotent tab-switch from refetching the same list.
    final current = ref.read(coursesNotifierProvider);
    final sameCategory = category == null
        ? current.category == null
        : current.category == category;
    final sameFeatured = current.featured == featured;
    if (sameCategory && sameFeatured) return;

    final notifier = ref.read(coursesNotifierProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      notifier.applyFilters(
        // category=null + clearCategory=true means "drop the existing
        // category" — relevant when the user navigates from a
        // category-scoped see-all back to a generic /courses with no
        // `?category=`.
        category: category,
        clearCategory: rawCategory.isEmpty,
        featured: featured,
      );
    });
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.maxScrollExtent <= 0) return; // not yet sized
    final fraction = pos.pixels / pos.maxScrollExtent;
    if (fraction >= _loadMoreThreshold) {
      // The notifier no-ops if already loading / no more pages / failure
      // pending — safe to call on every scroll tick.
      ref.read(coursesNotifierProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coursesNotifierProvider);
    final notifier = ref.read(coursesNotifierProvider.notifier);
    final t = AppLocalizations.of(context);

    // First-build deep-link handler. Idempotent via `_initialCategoryApplied`.
    _applyInitialCategory();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.coursesTitle),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => context.goNamed(RouteNames.search),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          CategoryFilterBar(
            selected: state.category,
            onChanged: notifier.filterByCategory,
          ),
          // Featured-only banner. Self-hides when the filter is off,
          // so the page reads as "everything" by default.
          if (state.featured)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _FeaturedBanner(
                onClear: () => notifier.filterByFeatured(false),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(state, notifier, t)),
        ],
      ),
    );
  }

  Widget _buildBody(
    CoursesState state,
    CoursesNotifier notifier,
    AppLocalizations t,
  ) {
    // Initial load → skeleton grid. Lets the chrome (header + filter bar)
    // stay stable while results stream in.
    if (state.isLoading && state.items.isEmpty) {
      return const CourseGridSkeleton();
    }
    // Hard failure on the initial load — full-bleed retry.
    if (state.failure != null && state.items.isEmpty) {
      return ErrorView(
        message: state.failure!.displayMessage,
        onRetry: notifier.refresh,
      );
    }
    if (state.isEmpty) {
      return EmptyView(message: t.coursesEmpty);
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverGrid.builder(
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // Card height ≈ width / 0.82 — leaves the 16:9 thumbnail
                // and ~3 lines of content (chips, title, instructor,
                // stats) without tripping a RenderFlex overflow at
                // narrow widths.
                childAspectRatio: 0.82,
              ),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final c = state.items[index];
                return CourseCard(
                  course: c,
                  onTap: () => context.goNamed(
                    RouteNames.courseDetail,
                    pathParameters: {'id': c.id},
                  ),
                );
              },
            ),
          ),
          // ----- footer: skeleton OR retry OR end-of-list sentinel -----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _buildFooter(state, notifier, t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    CoursesState state,
    CoursesNotifier notifier,
    AppLocalizations t,
  ) {
    // Active page fetch — render a row of skeleton cards. Two columns by
    // default; the grid will gracefully reflow on tablets but the spinner
    // is fine for the footer too at that width.
    if (state.isLoadingMore) {
      return Column(
        children: [
          const CourseGridSkeleton(count: 2),
          const SizedBox(height: 8),
          Text(
            t.coursesLoadingMore,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    // Inline retry — keeps the user at their current scroll position.
    if (state.loadMoreFailure != null) {
      return _LoadMoreError(
        message: state.loadMoreFailure!.displayMessage,
        onRetry: notifier.loadNextPage,
        retryLabel: t.commonRetry,
      );
    }

    // Sentinel — we're done.
    if (!state.hasMore && state.items.isNotEmpty) {
      return Center(
        child: Text(
          t.coursesEndOfList,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Inline "Showing featured only" indicator. Renders when the
/// featured filter is active (entered via the home Featured carousel
/// "See all" tap or the `?featured=true` deep-link). Tap the X to
/// clear and reload the full catalogue.
class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing featured courses',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.primary,
            tooltip: 'Show all courses',
            onPressed: onClear,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
