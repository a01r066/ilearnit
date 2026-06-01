import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../domain/entities/search_suggestion.dart';
import '../providers/search_providers.dart';
import '../providers/search_state.dart';
import '../widgets/search_app_bar.dart';
import '../widgets/search_filter_sheet.dart';
import '../widgets/search_result_tile.dart';
import '../widgets/search_suggestion_tile.dart';

/// Two-mode search screen — Suggestions when the user is typing,
/// Results when a query is committed. Toggles transparently as state
/// changes; the URL stays at `/search` regardless.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Open with the keyboard up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    ref.read(searchNotifierProvider.notifier).onQueryChanged(value);
  }

  void _onSubmitted(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    _focusNode.unfocus();
    ref.read(searchNotifierProvider.notifier).submit(query: q);
  }

  void _onClear() {
    _controller.clear();
    ref.read(searchNotifierProvider.notifier).clearQuery();
    _focusNode.requestFocus();
  }

  void _onCancel() {
    _focusNode.unfocus();
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  Future<void> _onFilterTap() async {
    final current = ref.read(searchNotifierProvider).filter;
    final next = await SearchFilterSheet.show(context, initial: current);
    if (next != null) {
      ref.read(searchNotifierProvider.notifier).setFilter(next);
      // If we have a query but haven't submitted yet, run results now.
      final s = ref.read(searchNotifierProvider);
      if (s.mode == SearchMode.suggestions && s.hasQuery) {
        await ref.read(searchNotifierProvider.notifier).submit();
      }
    }
  }

  void _onSuggestionTap(SearchSuggestion s) {
    switch (s) {
      case SearchKeyword(:final term):
        _controller.text = term;
        _focusNode.unfocus();
        ref.read(searchNotifierProvider.notifier).submit(query: term);
      case SearchCourseHit(:final course):
        _focusNode.unfocus();
        context.goNamed(
          RouteNames.courseDetail,
          pathParameters: {'id': course.id},
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchNotifierProvider);
    final showCancel = _focusNode.hasFocus || state.hasQuery;

    return Scaffold(
      appBar: SearchAppBar(
        controller: _controller,
        focusNode: _focusNode,
        showCancel: showCancel,
        activeFilterCount: state.filter.activeCount,
        onCancel: _onCancel,
        onClear: _onClear,
        onChanged: _onChanged,
        onSubmitted: _onSubmitted,
        onFilterTap: _onFilterTap,
      ),
      body: state.mode == SearchMode.suggestions
          ? _SuggestionsBody(state: state, onSuggestion: _onSuggestionTap)
          : _ResultsBody(state: state),
    );
  }
}

// ---------- Suggestions body ----------------------------------------------

class _SuggestionsBody extends ConsumerWidget {
  const _SuggestionsBody({required this.state, required this.onSuggestion});
  final SearchState state;
  final ValueChanged<SearchSuggestion> onSuggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchNotifierProvider.notifier);
    final t = AppLocalizations.of(context);
    final children = <Widget>[];

    if (!state.hasQuery && state.recentSearches.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t.searchRecentSearches,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              TextButton(
                onPressed: notifier.clearRecentSearches,
                child: Text(t.searchClear),
              ),
            ],
          ),
        ),
      );
      for (final r in state.recentSearches) {
        children.add(SearchSuggestionTile(
          suggestion: SearchKeyword(r),
          highlight: '',
          onTap: () => onSuggestion(SearchKeyword(r)),
        ));
      }
      children.add(const Divider(height: 1));
    }

    if (state.suggestions.isNotEmpty) {
      for (final s in state.suggestions) {
        children.add(SearchSuggestionTile(
          suggestion: s,
          highlight: state.query,
          onTap: () => onSuggestion(s),
        ));
      }
    }

    if (children.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            t.searchEmptyState,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView(children: children);
  }
}

// ---------- Results body --------------------------------------------------

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({required this.state});
  final SearchState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.lastFailure != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.lastFailure!.displayMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
    if (!state.hasResults) {
      final t = AppLocalizations.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 56),
              const SizedBox(height: 12),
              Text(
                t.searchNoMatchesForQuery(state.query),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                t.searchTryDifferent,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: state.results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final c = state.results[i];
        final entity = c.toEntity();
        return SearchResultTile(
          course: c,
          priceLabel: _formatPrice(context, entity),
          badge: state.badges[c.id],
          onTap: () => context.goNamed(
            RouteNames.courseDetail,
            pathParameters: {'id': c.id},
          ),
        );
      },
    );
  }

  String _formatPrice(BuildContext context, CourseEntity entity) {
    // Use the locale-appropriate price label. For VI we want VND; for
    // everything else we use the tier's USD fallback.
    final localeCode = Localizations.localeOf(context).languageCode;
    if (localeCode == 'vi') {
      final raw = entity.priceTier.rawFallbackPrice;
      // Tier prices in PriceTier are in USD; for VND-locale UI we map to
      // the corresponding Vietnamese price using the same tier table.
      final vnd = _vndFor(entity.priceTier.id);
      return '₫${NumberFormat.decimalPattern("vi").format(vnd)}';
    }
    return entity.priceTier.fallbackPrice;
  }

  int _vndFor(String tierId) {
    switch (tierId) {
      case 'basic':
        return 199000;
      case 'standard':
        return 399000;
      case 'premium':
        return 799000;
      default:
        return 0;
    }
  }
}
