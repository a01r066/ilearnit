import 'package:flutter/material.dart';

import '../../../../features/courses/domain/entities/course_status.dart';

/// Hand-rolled status pill — colored background, icon, label. Used on
/// course rows in the admin Courses lists and as the header indicator
/// on the course editor.
///
/// Not the M3 `Chip` widget on purpose. Chip's intrinsic-size logic
/// repeatedly bit the admin pages with "Cannot hit test a render box
/// with no size" — see `admin_instructors_page.dart` for the same fix.
class CourseStatusChip extends StatelessWidget {
  const CourseStatusChip({
    super.key,
    required this.status,
    this.dense = false,
  });

  final CourseStatus status;

  /// Smaller padding + smaller text. Use on dense list rows where the
  /// chip is one of several trailing elements.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final horizontalPadding = dense ? 8.0 : 10.0;
    final verticalPadding = dense ? 3.0 : 4.0;
    final fontSize = dense ? 11.0 : 12.0;
    final iconSize = dense ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: iconSize, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
