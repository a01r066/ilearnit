import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../courses/data/models/course_model.dart';
import '../../domain/entities/course_badge.dart';
import 'course_badge_chip.dart';

/// One row in the result list. Mirrors the attached design:
///
///   ┌─────┐  Title (bold, max 2 lines)
///   │     │  Instructor name
///   │ img │  ⭐ 4.7 ★★★★★ (1297)
///   └─────┘  ₫399.000
///           [Bestseller]   ← optional
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.course,
    required this.priceLabel,
    this.badge,
    required this.onTap,
  });

  final CourseModel course;
  final String priceLabel;
  final CourseBadge? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(url: course.thumbnailUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.instructorName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _RatingRow(
                    rating: course.rating,
                    count: course.enrollmentCount,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 8),
                    CourseBadgeChip(badge: badge!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 24),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 88,
        height: 88,
        child: url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.count});
  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFFB4690E),
          ),
        ),
        const SizedBox(width: 4),
        _Stars(rating: rating),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 5-star row with half-star support, painted in Udemy gold.
class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final double rating;
  static const Color _gold = Color(0xFFE59819);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final diff = rating - i;
        IconData icon;
        if (diff >= 1.0) {
          icon = Icons.star_rounded;
        } else if (diff >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, size: 14, color: _gold);
      }),
    );
  }
}
