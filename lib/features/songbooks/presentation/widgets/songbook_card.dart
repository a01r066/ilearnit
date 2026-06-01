import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/songbook_model.dart';

/// Portrait songbook tile used by every carousel + grid in the feature.
///
/// Two sizes:
///   • [SongbookCard]       — full 160×220 cover with title underneath.
///   • SongbookCard.compact — smaller cover only (used in "Bestsellers"
///     carousel where titles are omitted to mirror the MuseScore design).
class SongbookCard extends StatelessWidget {
  const SongbookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.width = 160,
    this.showTitle = true,
  });

  /// Compact constructor — no title row, used by the Bestsellers carousel.
  const SongbookCard.compact({
    super.key,
    required this.book,
    required this.onTap,
    this.width = 140,
  }) : showTitle = false;

  final SongbookModel book;
  final VoidCallback onTap;
  final double width;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverHeight = width * 1.35;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: width,
                // height: coverHeight,
                child: book.coverUrl.isEmpty
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.book_outlined, size: 36),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: book.coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
              ),
            ),
            if (showTitle) ...[
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
