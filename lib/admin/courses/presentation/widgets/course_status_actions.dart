import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/courses/domain/entities/course_status.dart';
import '../../../shared/providers/admin_providers.dart';

/// Renders the workflow buttons available to the viewer for the
/// current `CourseStatus`. Driven by
/// `CourseStatus.allowedNextStates(role)` — the state machine is the
/// single source of truth for which buttons exist.
///
/// Used on the course editor header (admins + instructors) and on the
/// admin All Courses list rows (admins only).
class CourseStatusActions extends ConsumerStatefulWidget {
  const CourseStatusActions({
    super.key,
    required this.courseId,
    required this.current,
    this.compact = false,
  });

  final String courseId;
  final CourseStatus current;

  /// Render labels-only buttons in a horizontal Wrap for list rows.
  /// Otherwise render the primary action as a filled button + secondary
  /// actions in an overflow menu, suitable for the editor header.
  final bool compact;

  @override
  ConsumerState<CourseStatusActions> createState() =>
      _CourseStatusActionsState();
}

class _CourseStatusActionsState extends ConsumerState<CourseStatusActions> {
  bool _busy = false;

  Future<void> _apply(CourseStatus next) async {
    if (_busy) return;
    // Destructive transitions (archive, send-back-to-draft) get a
    // confirmation. Everything else applies immediately so the
    // admin can move through review quickly.
    final destructive = next == CourseStatus.archived ||
        next == CourseStatus.draft ||
        next == CourseStatus.changesRequested;
    if (destructive) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${next.actionLabel}?'),
          content: Text(
            'This will move the course from "${widget.current.label}" '
            'to "${next.label}". You can change it again later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(next.actionLabel),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(adminCoursesDataSourceProvider).updateCourseStatus(
            courseId: widget.courseId,
            status: next.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status → ${next.label}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    // `role.id` is the stable string ('admin' / 'instructor' / …) that
    // CourseStatus.allowedNextStates understands.
    final next = widget.current.allowedNextStates(user?.role.id ?? '');
    if (next.isEmpty) return const SizedBox.shrink();

    if (widget.compact) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final s in next)
            _CompactActionButton(
              label: s.actionLabel,
              icon: s.icon,
              color: s.color,
              busy: _busy,
              onTap: () => _apply(s),
            ),
        ],
      );
    }

    // Header layout — primary action is the first entry; the rest go
    // into a popup menu so the header stays clean.
    final primary = next.first;
    final secondaries = next.skip(1).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderPrimaryButton(
          label: primary.actionLabel,
          icon: primary.icon,
          color: primary.color,
          busy: _busy,
          onTap: () => _apply(primary),
        ),
        if (secondaries.isNotEmpty) ...[
          const SizedBox(width: 8),
          PopupMenuButton<CourseStatus>(
            tooltip: 'More actions',
            icon: const Icon(Icons.more_horiz),
            onSelected: _apply,
            itemBuilder: (_) => [
              for (final s in secondaries)
                PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(s.icon, size: 18, color: s.color),
                      const SizedBox(width: 12),
                      Text(s.actionLabel),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------- Hand-rolled buttons ----------------------------------------
// Same anti-MaterialButton pattern as `admin_instructors_page.dart`:
// flex children inside Row + Material 3 button widgets blow up with
// "ConstrainedBox forces an infinite width" inside list rows. Keep
// these as InkWell over Container.

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderPrimaryButton extends StatelessWidget {
  const _HeaderPrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
