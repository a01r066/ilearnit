import 'package:flutter/material.dart';

import '../../domain/entities/search_suggestion.dart';

/// One row in the suggestion list. Renders the leading icon depending on
/// the suggestion type and bolds the substring matching [highlight].
class SearchSuggestionTile extends StatelessWidget {
  const SearchSuggestionTile({
    super.key,
    required this.suggestion,
    required this.highlight,
    required this.onTap,
  });

  final SearchSuggestion suggestion;
  final String highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final icon = switch (suggestion) {
      SearchKeyword() => Icons.search,
      SearchCourseHit() => Icons.cast_for_education_outlined,
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _BoldMatched(
                text: suggestion.displayText,
                match: highlight,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders [text] with substrings matching [match] in bold.
///
/// Case-insensitive. Falls back to a single span when [match] is empty.
class _BoldMatched extends StatelessWidget {
  const _BoldMatched({
    required this.text,
    required this.match,
    required this.style,
  });

  final String text;
  final String match;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? const TextStyle();
    final boldStyle = base.copyWith(fontWeight: FontWeight.w800);

    if (match.trim().isEmpty) {
      return Text(text, style: boldStyle);
    }

    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final needle = match.toLowerCase();
    int cursor = 0;
    while (true) {
      final idx = lower.indexOf(needle, cursor);
      if (idx == -1) {
        if (cursor < text.length) {
          spans.add(TextSpan(text: text.substring(cursor), style: base));
        }
        break;
      }
      if (idx > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, idx), style: base));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + needle.length),
        style: boldStyle,
      ));
      cursor = idx + needle.length;
    }
    return RichText(text: TextSpan(children: spans));
  }
}
