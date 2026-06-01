import 'package:flutter/material.dart';

import '../../../courses/domain/entities/instrument_category.dart';
import '../../domain/entities/search_filter.dart';

/// Bottom sheet for adjusting the [SearchFilter]. Returns the new filter
/// via [Navigator.pop] on Apply; returns null on Cancel / dismiss.
class SearchFilterSheet extends StatefulWidget {
  const SearchFilterSheet({super.key, required this.initial});
  final SearchFilter initial;

  static Future<SearchFilter?> show(
    BuildContext context, {
    required SearchFilter initial,
  }) {
    return showModalBottomSheet<SearchFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SearchFilterSheet(initial: initial),
    );
  }

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late Set<InstrumentCategory> _categories;
  late Set<CourseLevel> _levels;
  late double _minRating;
  int? _maxPriceVnd;

  static const _priceCaps = <int?>[null, 199000, 399000, 799000];

  @override
  void initState() {
    super.initState();
    _categories = {...widget.initial.categories};
    _levels = {...widget.initial.levels};
    _minRating = widget.initial.minRating;
    _maxPriceVnd = widget.initial.maxPriceVnd;
  }

  void _apply() {
    Navigator.of(context).pop(
      SearchFilter(
        categories: _categories,
        levels: _levels,
        minRating: _minRating,
        maxPriceVnd: _maxPriceVnd,
      ),
    );
  }

  void _reset() {
    setState(() {
      _categories = {};
      _levels = {};
      _minRating = 0;
      _maxPriceVnd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Filters',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
              const SizedBox(height: 8),

              // Instrument
              _SectionLabel(label: 'Instrument'),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in InstrumentCategory.values)
                    FilterChip(
                      label: Text(c.label),
                      selected: _categories.contains(c),
                      onSelected: (sel) => setState(() => sel
                          ? _categories.add(c)
                          : _categories.remove(c)),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              _SectionLabel(label: 'Level'),
              Wrap(
                spacing: 8,
                children: [
                  for (final l in CourseLevel.values)
                    FilterChip(
                      label: Text(l.label),
                      selected: _levels.contains(l),
                      onSelected: (sel) => setState(() => sel
                          ? _levels.add(l)
                          : _levels.remove(l)),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              _SectionLabel(label: 'Minimum rating'),
              Slider(
                value: _minRating,
                onChanged: (v) => setState(() => _minRating = v),
                min: 0,
                max: 5,
                divisions: 10,
                label: _minRating == 0
                    ? 'Any'
                    : _minRating.toStringAsFixed(1),
              ),

              const SizedBox(height: 8),
              _SectionLabel(label: 'Max price'),
              Wrap(
                spacing: 8,
                children: [
                  for (final cap in _priceCaps)
                    ChoiceChip(
                      label: Text(_priceLabel(cap)),
                      selected: _maxPriceVnd == cap,
                      onSelected: (_) => setState(() => _maxPriceVnd = cap),
                    ),
                ],
              ),

              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _apply,
                child: const Text('Apply',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _priceLabel(int? vnd) {
    if (vnd == null) return 'Any';
    return '≤ ₫${_thousands(vnd)}';
  }

  static String _thousands(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              )),
    );
  }
}
