import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../courses/data/models/course_model.dart';
import '../../data/models/instructor_model.dart';
import '../providers/instructor_providers.dart';

/// Detail page for one instructor / publisher.
///
/// Mirrors the attached Udemy-style design:
///   • Top app bar: back + "Instructor" title + share
///   • Avatar/logo + bold name + tagline
///   • 2-column stats: Total students • Reviews
///   • "About me" with show more/less toggle
///   • "My courses (N)" list of Udemy-style row cards
///   • Social links at the bottom (Website / Facebook / …)
class InstructorDetailPage extends ConsumerStatefulWidget {
  const InstructorDetailPage({super.key, required this.instructorId});
  final String instructorId;

  @override
  ConsumerState<InstructorDetailPage> createState() =>
      _InstructorDetailPageState();
}

class _InstructorDetailPageState
    extends ConsumerState<InstructorDetailPage> {
  bool _bioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final instructor = ref.watch(instructorByIdProvider(widget.instructorId));
    final courses =
        ref.watch(coursesByInstructorProvider(widget.instructorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor'),
        centerTitle: true,
        leading: _CircleIconButton(
          icon: Icons.chevron_left,
          onTap: () => context.pop(),
        ),
        actions: [
          _CircleIconButton(
            icon: Icons.ios_share,
            onTap: () {
              // TODO: wire to share_plus when added.
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: instructor.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (m) {
          if (m == null) {
            return const Center(child: Text('Instructor not found.'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _Header(instructor: m),
              const SizedBox(height: 24),
              _StatsRow(instructor: m),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              _About(
                instructor: m,
                expanded: _bioExpanded,
                onToggle: () =>
                    setState(() => _bioExpanded = !_bioExpanded),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              courses.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text(
                  'Failed to load courses: $e',
                  style: TextStyle(color: context.colors.error),
                ),
                data: (items) => _MyCoursesSection(items: items),
              ),
              const SizedBox(height: 16),
              if (m.hasAnySocialLink) ...[
                const Divider(height: 1),
                const SizedBox(height: 8),
                _SocialLinks(instructor: m),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ---------- Header --------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.instructor});
  final InstructorModel instructor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 96,
            height: 96,
            child: instructor.photoUrl.isEmpty
                ? Container(
                    color: context.colors.surfaceContainerHighest,
                    child: const Icon(Icons.person_outline, size: 40),
                  )
                : CachedNetworkImage(
                    imageUrl: instructor.photoUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: context.colors.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instructor.name,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              if (instructor.tagline != null &&
                  instructor.tagline!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  instructor.tagline!,
                  style: context.textTheme.bodyLarge,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- Stats ---------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.instructor});
  final InstructorModel instructor;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    return Row(
      children: [
        Expanded(
          child: _Stat(
            label: 'Total students',
            value: fmt.format(instructor.studentCount),
          ),
        ),
        Expanded(
          child: _Stat(
            label: 'Reviews',
            value: fmt.format(instructor.reviewCount),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 6),
        Text(value,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            )),
      ],
    );
  }
}

// ---------- About ---------------------------------------------------------

class _About extends StatelessWidget {
  const _About({
    required this.instructor,
    required this.expanded,
    required this.onToggle,
  });
  final InstructorModel instructor;
  final bool expanded;
  final VoidCallback onToggle;

  static const int _collapsedLength = 280;

  @override
  Widget build(BuildContext context) {
    final bio = instructor.bio;
    final tooLong = bio.length > _collapsedLength;
    final body = expanded || !tooLong
        ? bio
        : '${bio.substring(0, _collapsedLength)}…';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About me',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            )),
        const SizedBox(height: 16),
        Text(
          'About ${instructor.name}',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(body, style: context.textTheme.bodyLarge),
        if (tooLong) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onToggle,
            child: Text(
              expanded ? 'Show less' : 'Show more',
              style: context.textTheme.bodyLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------- My courses ----------------------------------------------------

class _MyCoursesSection extends StatelessWidget {
  const _MyCoursesSection({required this.items});
  final List<CourseModel> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My courses (${items.length})',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Text(
            'No published courses yet.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            _CourseRow(course: items[i]),
            if (i != items.length - 1) const SizedBox(height: 16),
          ],
      ],
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.goNamed(
        RouteNames.courseDetail,
        pathParameters: {'id': course.id},
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: 88,
              height: 88,
              child: course.thumbnailUrl.isEmpty
                  ? Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_outlined),
                    )
                  : CachedNetworkImage(
                      imageUrl: course.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
          ),
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
                if (course.isFeatured) ...[
                  const SizedBox(height: 6),
                  const _BestsellerChip(),
                ],
                const SizedBox(height: 4),
                _RatingRow(
                  rating: course.rating,
                  count: course.enrollmentCount,
                ),
                const SizedBox(height: 4),
                Text(
                  course.instructorName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(context, course.priceTier),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(BuildContext context, String tierId) {
    final localeCode = Localizations.localeOf(context).languageCode;
    if (localeCode == 'vi') {
      final vnd = _vndFor(tierId);
      return '₫${NumberFormat.decimalPattern("vi").format(vnd)}';
    }
    switch (tierId) {
      case 'basic':
        return r'$9.99';
      case 'standard':
        return r'$19.99';
      case 'premium':
        return r'$39.99';
      default:
        return r'$0';
    }
  }

  int _vndFor(String tierId) {
    switch (tierId) {
      case 'basic':
        return 199000;
      case 'standard':
        return 399000;
      case 'premium':
        return 799000;
      default:
        return 0;
    }
  }
}

class _BestsellerChip extends StatelessWidget {
  const _BestsellerChip();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFECEAB1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: const Text(
        'Bestseller',
        style: TextStyle(
          color: Color(0xFF3D3A00),
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
    final fmt = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
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
          '(${fmt.format(count)})',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

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

// ---------- Social --------------------------------------------------------

class _SocialLinks extends StatelessWidget {
  const _SocialLinks({required this.instructor});
  final InstructorModel instructor;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    void add(IconData icon, String label, String? url) {
      if (url == null || url.isEmpty) return;
      rows.add(
        InkWell(
          onTap: () => _open(url),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label,
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
    }

    add(Icons.link, 'Website', instructor.websiteUrl);
    add(Icons.facebook, 'Facebook', instructor.facebookUrl);
    add(Icons.alternate_email, 'X / Twitter', instructor.twitterUrl);
    add(Icons.play_circle_outline, 'YouTube', instructor.youtubeUrl);
    add(Icons.camera_alt_outlined, 'Instagram', instructor.instagramUrl);

    return Column(children: rows);
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ---------- Shared --------------------------------------------------------

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon),
          ),
        ),
      ),
    );
  }
}
