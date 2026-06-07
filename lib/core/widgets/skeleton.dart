import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shared shimmer primitives used to build per-feature loading states.
///
/// Keep one [SkeletonShimmer] at the root of a skeleton tree (it owns the
/// animation), then drop [SkeletonBox] / [SkeletonText] descendants for
/// the actual shapes. The descendants don't run their own animations —
/// they paint into the parent's gradient sweep.
///
/// Example:
///
/// ```dart
/// SkeletonShimmer(
///   child: Column(
///     children: const [
///       SkeletonBox(width: 64, height: 64, borderRadius: 32),
///       SizedBox(height: 8),
///       SkeletonText(width: 120),
///       SizedBox(height: 6),
///       SkeletonText(width: 80, height: 10),
///     ],
///   ),
/// );
/// ```

// ---------- Root wrapper --------------------------------------------------

/// Single Shimmer that drives every nested SkeletonBox / SkeletonText.
/// Putting the shimmer at the root means one paint pass covers the whole
/// subtree — much cheaper than nesting Shimmer widgets per shape.
class SkeletonShimmer extends StatelessWidget {
  const SkeletonShimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1200),
  });

  final Widget child;
  final Duration period;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surfaceContainerHigh,
      period: period,
      child: child,
    );
  }
}

// ---------- Shapes --------------------------------------------------------

/// Rounded-rectangle placeholder. Paints solid — the parent
/// [SkeletonShimmer] adds the moving highlight.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;

  /// Use the box's own height for a circular avatar
  /// (`borderRadius: height / 2`), or 0 for a hard rectangle.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Convenience: a thin horizontal bar styled like a text line. Pass
/// `width: double.infinity` for full-width lines (default).
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 12,
    this.borderRadius = 4,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

/// Circular avatar placeholder. Sized so it pairs cleanly with a
/// `ListTile`'s leading slot (40-48px is typical).
class SkeletonAvatar extends StatelessWidget {
  const SkeletonAvatar({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }
}
