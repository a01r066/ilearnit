import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/cohort_matrix.dart';

/// Triangular retention heat-map.
///
/// Each row is a signup cohort (label = "Apr '26"). Each column is
/// "months since signup". Cell color saturation scales with retention
/// rate. Empty cells are intentionally blank — they represent months
/// that haven't happened yet for that cohort.
class CohortHeatmap extends StatelessWidget {
  const CohortHeatmap({super.key, required this.matrix});
  final CohortMatrix matrix;

  @override
  Widget build(BuildContext context) {
    if (matrix.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Not enough history yet — cohorts will populate as users sign up.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final cohortLabelStyle = theme.textTheme.bodySmall;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — month offsets.
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text('Cohort',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
              ),
              SizedBox(
                width: 56,
                child: Text('Size',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
              ),
              const SizedBox(width: 8),
              for (var off = 0; off <= matrix.maxOffset; off++)
                SizedBox(
                  width: 44,
                  child: Text(
                    'M+$off',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final row in matrix.rows) ...[
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    DateFormat("MMM ''yy").format(row.cohortMonth),
                    style: cohortLabelStyle,
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    '${row.cohortSize}',
                    textAlign: TextAlign.right,
                    style: cohortLabelStyle,
                  ),
                ),
                const SizedBox(width: 8),
                for (var off = 0; off <= matrix.maxOffset; off++)
                  _cell(theme, row, off),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _cell(ThemeData theme, CohortRow row, int offset) {
    final rendered = offset < row.retainedByOffset.length;
    if (!rendered) {
      return const SizedBox(width: 44);
    }
    final pct = row.retentionAt(offset);
    final color = theme.colorScheme.primary.withValues(
      // Floor at 0.08 so even zero cells are visible against the
      // background as "we measured this and it was zero".
      alpha: 0.08 + 0.85 * pct,
    );
    return Container(
      width: 44,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        pct == 0 ? '·' : '${(pct * 100).round()}%',
        style: theme.textTheme.bodySmall?.copyWith(
          color: pct > 0.45
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
