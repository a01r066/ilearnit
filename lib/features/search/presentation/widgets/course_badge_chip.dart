import 'package:flutter/material.dart';

import '../../domain/entities/course_badge.dart';
import '../../../../l10n/l10n.dart';

/// Small filled chip rendered under the price on the result tile. Yellow
/// for bestseller, amber for highest-rated, green for new release.
class CourseBadgeChip extends StatelessWidget {
  const CourseBadgeChip({super.key, required this.badge});
  final CourseBadge badge;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(context, badge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        spec.label,
        style: TextStyle(
          color: spec.fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _BadgeSpec _specFor(BuildContext context, CourseBadge b) {
    final t = context.l10n;
    switch (b) {
      case CourseBadge.bestseller:
        return _BadgeSpec(
          label: t.badgeBestseller,
          bg: const Color(0xFFECEAB1),
          fg: const Color(0xFF3D3A00),
        );
      case CourseBadge.highestRated:
        return _BadgeSpec(
          label: t.badgeHighestRated,
          bg: const Color(0xFFF7C788),
          fg: const Color(0xFF3D2400),
        );
      case CourseBadge.newRelease:
        return _BadgeSpec(
          label: t.badgeNew,
          bg: const Color(0xFFB5DCC8),
          fg: const Color(0xFF103B2C),
        );
    }
  }
}

class _BadgeSpec {
  const _BadgeSpec({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;
}
