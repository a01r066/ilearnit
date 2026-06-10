import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholder for a [CourseCard]. Used during the initial
/// course list load and as a footer while `loadMore()` is in flight.
///
/// Aspect ratio + padding mirror the real card so the grid doesn't jump
/// when results arrive.
class CourseCardSkeleton extends StatelessWidget {
  const CourseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surfaceContainerHigh;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        period: const Duration(milliseconds: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(color: base),
            ),
            // Inner gaps trimmed from 10/10/12/12 to 8/8/8/8 — saves
            // the ~5.2px overflow at narrow grid widths without
            // changing the visual rhythm meaningfully.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chips row
                  Row(
                    children: [
                      _Bar(width: 56, height: 18, color: base),
                      const SizedBox(width: 6),
                      _Bar(width: 64, height: 18, color: base),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title — two lines
                  _Bar(width: double.infinity, height: 14, color: base),
                  const SizedBox(height: 6),
                  _Bar(width: 180, height: 14, color: base),
                  const SizedBox(height: 8),
                  // Instructor line
                  _Bar(width: 120, height: 12, color: base),
                  const SizedBox(height: 8),
                  // Stats row
                  Row(
                    children: [
                      _Bar(width: 40, height: 12, color: base),
                      const SizedBox(width: 12),
                      _Bar(width: 60, height: 12, color: base),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Grid of [CourseCardSkeleton]s sized to mirror the live `CoursesPage`
/// grid. Used as the initial loading state so the user sees structure
/// rather than a centered spinner.
class CourseGridSkeleton extends StatelessWidget {
  const CourseGridSkeleton({super.key, this.count = 6});

  /// How many placeholder cards to render. The default fills 2 columns ×
  /// 3 rows on a phone, which is enough to feel substantive without
  /// burning frames on shimmer animations.
  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // Disable scrolling — the parent owns scroll behavior. Suppressing
      // also stops the skeleton from interfering with the page's
      // ScrollController.
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const CourseCardSkeleton(),
    );
  }
}
