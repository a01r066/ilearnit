import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../flavors.dart';
import '../../domain/entities/landing_content.dart';
import '../providers/site_content_form_notifier.dart';
import '../providers/site_content_form_state.dart';
import '../providers/site_content_providers.dart';

/// Landing-page CMS editor. Five collapsible sections — Hero,
/// Features, Pricing, FAQ, Contact — backed by a single Firestore
/// doc. Save lights up when the draft diverges from the last-saved
/// snapshot.
class AdminLandingContentPage extends ConsumerWidget {
  const AdminLandingContentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(siteContentFormNotifierProvider);
    final notifier =
        ref.read(siteContentFormNotifierProvider.notifier);
    final theme = Theme.of(context);

    ref.listen<SiteContentFormState>(siteContentFormNotifierProvider,
        (_, next) {
      if (next.justSaved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Landing page saved.')),
        );
      }
      if (next.lastFailure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.lastFailure!.displayMessage)),
        );
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Landing page',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Edit the content rendered on ilearnit.info. '
                      'Saving publishes immediately — there is no '
                      'separate draft / publish flow.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Preview opens the public landing page in a new tab. It
              // reflects the LAST SAVED state (not the in-memory draft) —
              // tooltip spells this out so the editor doesn't refresh and
              // wonder why their unsaved edits aren't there. URL is
              // flavor-aware: dev → ilearnit-dev.web.app, prod → ilearnit.info.
              // SizedBox-wrapped per the learning-path editor's dartdoc:
              // FilledButton.icon / OutlinedButton.icon adjacent to an
              // Expanded in a Row without an explicit width is a known
              // trigger for "Cannot hit test a render box with no size".
              SizedBox(
                width: 180,
                child: Tooltip(
                  message: state.isDirty
                      ? 'Save first — preview shows the last-saved state.'
                      : 'Opens ${F.landingSiteUrl} in a new tab.',
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(F.landingSiteUrl);
                      final ok = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                        webOnlyWindowName: '_blank',
                      );
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not open preview — copy this URL: '
                              '${F.landingSiteUrl}',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Preview'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (state.isDirty)
                TextButton(
                  onPressed: state.isSubmitting
                      ? null
                      : notifier.discardDraft,
                  child: const Text('Discard changes'),
                ),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                child: FilledButton.icon(
                  icon: state.isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(state.isDirty ? 'Save changes' : 'Saved'),
                  onPressed: state.canSubmit ? notifier.save : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _HeroCard(hero: state.draft.hero, onChanged: notifier.updateHero),
          const SizedBox(height: 16),
          _InstrumentsCard(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _FeaturesCard(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _PricingCard(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _FaqCard(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _AboutCard(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _InstructorCalloutCard(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _NavCard(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _FooterCard(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _StoreBadgesCard(
              badges: state.draft.storeBadges,
              onChanged: notifier.updateStoreBadges),
          const SizedBox(height: 16),
          _MetaCard(
              meta: state.draft.meta, onChanged: notifier.updateMeta),
          const SizedBox(height: 16),
          _ContactCard(
              contact: state.draft.contact,
              onChanged: notifier.updateContact),
        ],
      ),
    );
  }
}

// ---------- Hero ----------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.hero, required this.onChanged});
  final HeroSection hero;
  final ValueChanged<HeroSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Hero',
      subtitle: 'Top-of-page headline + CTAs.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TF(
            label: 'Eyebrow',
            value: hero.eyebrow,
            onChanged: (v) => onChanged(hero.copyWith(eyebrow: v)),
          ),
          _TF(
            label: 'Title',
            value: hero.title,
            maxLines: 2,
            onChanged: (v) => onChanged(hero.copyWith(title: v)),
          ),
          _TF(
            label: 'Subtitle',
            value: hero.subtitle,
            maxLines: 3,
            onChanged: (v) => onChanged(hero.copyWith(subtitle: v)),
          ),
          Row(
            children: [
              Expanded(
                child: _TF(
                  label: 'Primary CTA label',
                  value: hero.ctaPrimaryLabel,
                  onChanged: (v) =>
                      onChanged(hero.copyWith(ctaPrimaryLabel: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TF(
                  label: 'Primary CTA href',
                  value: hero.ctaPrimaryHref,
                  onChanged: (v) =>
                      onChanged(hero.copyWith(ctaPrimaryHref: v)),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _TF(
                  label: 'Secondary CTA label',
                  value: hero.ctaSecondaryLabel,
                  onChanged: (v) =>
                      onChanged(hero.copyWith(ctaSecondaryLabel: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TF(
                  label: 'Secondary CTA href',
                  value: hero.ctaSecondaryHref,
                  onChanged: (v) =>
                      onChanged(hero.copyWith(ctaSecondaryHref: v)),
                ),
              ),
            ],
          ),
          _TF(
            label: 'Hero image URL',
            value: hero.imageUrl,
            onChanged: (v) => onChanged(hero.copyWith(imageUrl: v)),
          ),
        ],
      ),
    );
  }
}

// ---------- Features ------------------------------------------------------

class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard({required this.state, required this.notifier});
  final SiteContentFormState state;
  final SiteContentFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final features = state.draft.features;
    // ReorderableListView is the known root cause of "Cannot hit test a
    // render box with no size" floods in Material 3 (see the dartdoc
    // on lib/admin/learning_paths/.../learning_path_editor_page.dart).
    // Replaced with a plain Column + per-row up/down arrow buttons.
    return _SectionCard(
      title: 'Features',
      subtitle: 'Highlight cards under the hero. Use the arrows to reorder.',
      trailing: TextButton.icon(
        onPressed: notifier.addFeature,
        icon: const Icon(Icons.add),
        label: const Text('Add feature'),
      ),
      child: features.isEmpty
          ? const Text('No features yet.')
          : Column(
              children: [
                for (var index = 0; index < features.length; index++) ...[
                  _FeatureRow(
                    index: index,
                    total: features.length,
                    feature: features[index],
                    onChanged: (f) => notifier.updateFeature(index, f),
                    onRemove: () => notifier.removeFeature(index),
                    onMove: (delta) => notifier.moveFeature(index, delta),
                  ),
                  if (index < features.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.index,
    required this.total,
    required this.feature,
    required this.onChanged,
    required this.onRemove,
    required this.onMove,
  });
  final int index;
  final int total;
  final FeatureItem feature;
  final ValueChanged<FeatureItem> onChanged;
  final VoidCallback onRemove;
  final ValueChanged<int> onMove; // -1 = up, +1 = down

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReorderArrows(
          isFirst: index == 0,
          isLast: index == total - 1,
          onMove: onMove,
        ),
        SizedBox(
          width: 60,
          child: _TF(
            label: 'Icon',
            value: feature.icon,
            onChanged: (v) => onChanged(feature.copyWith(icon: v)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _TF(
                label: 'Title',
                value: feature.title,
                onChanged: (v) =>
                    onChanged(feature.copyWith(title: v)),
              ),
              _TF(
                label: 'Description',
                value: feature.description,
                maxLines: 2,
                onChanged: (v) =>
                    onChanged(feature.copyWith(description: v)),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Remove',
          icon: const Icon(Icons.delete_outline),
          onPressed: onRemove,
        ),
      ],
    );
  }
}

/// Two stacked up/down arrows used by every reorderable row in the
/// landing editor. Disabled at the boundaries so users get visual
/// feedback for the no-op case.
class _ReorderArrows extends StatelessWidget {
  const _ReorderArrows({
    required this.isFirst,
    required this.isLast,
    required this.onMove,
  });
  final bool isFirst;
  final bool isLast;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Move up',
          icon: const Icon(Icons.arrow_upward),
          visualDensity: VisualDensity.compact,
          onPressed: isFirst ? null : () => onMove(-1),
        ),
        IconButton(
          tooltip: 'Move down',
          icon: const Icon(Icons.arrow_downward),
          visualDensity: VisualDensity.compact,
          onPressed: isLast ? null : () => onMove(1),
        ),
      ],
    );
  }
}

// ---------- Pricing -------------------------------------------------------

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.state, required this.notifier});
  final SiteContentFormState state;
  final SiteContentFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final tiers = state.draft.pricingTiers;
    return _SectionCard(
      title: 'Pricing',
      subtitle: 'Tiers shown on the marketing page (not the store SKUs).',
      trailing: TextButton.icon(
        onPressed: notifier.addPricingTier,
        icon: const Icon(Icons.add),
        label: const Text('Add tier'),
      ),
      child: tiers.isEmpty
          ? const Text('No tiers yet.')
          : Column(
              children: [
                for (var i = 0; i < tiers.length; i++) ...[
                  _PricingTierEditor(
                    index: i,
                    tier: tiers[i],
                    onChanged: (t) => notifier.updatePricingTier(i, t),
                    onRemove: () => notifier.removePricingTier(i),
                  ),
                  if (i < tiers.length - 1)
                    const Divider(height: 24),
                ],
              ],
            ),
    );
  }
}

class _PricingTierEditor extends StatelessWidget {
  const _PricingTierEditor({
    required this.index,
    required this.tier,
    required this.onChanged,
    required this.onRemove,
  });
  final int index;
  final PricingTier tier;
  final ValueChanged<PricingTier> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _TF(
                label: 'Name',
                value: tier.name,
                onChanged: (v) => onChanged(tier.copyWith(name: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TF(
                label: 'Price label',
                value: tier.priceLabel,
                onChanged: (v) =>
                    onChanged(tier.copyWith(priceLabel: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TF(
                label: 'Billing note',
                value: tier.billingNote,
                onChanged: (v) =>
                    onChanged(tier.copyWith(billingNote: v)),
              ),
            ),
            IconButton(
              tooltip: 'Remove tier',
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _TF(
                label: 'CTA label',
                value: tier.ctaLabel,
                onChanged: (v) => onChanged(tier.copyWith(ctaLabel: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TF(
                label: 'CTA href',
                value: tier.ctaHref,
                onChanged: (v) => onChanged(tier.copyWith(ctaHref: v)),
              ),
            ),
            const SizedBox(width: 12),
            FilterChip(
              label: const Text('Featured'),
              selected: tier.isFeatured,
              onSelected: (s) =>
                  onChanged(tier.copyWith(isFeatured: s)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Perks (one per line):',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TextField(
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          controller: TextEditingController(text: tier.perks.join('\n'))
            ..selection = TextSelection.collapsed(
              offset: tier.perks.join('\n').length,
            ),
          onChanged: (v) {
            final lines = v
                .split('\n')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            onChanged(tier.copyWith(perks: lines));
          },
        ),
      ],
    );
  }
}

// ---------- FAQ -----------------------------------------------------------

class _FaqCard extends StatelessWidget {
  const _FaqCard({required this.state, required this.notifier});
  final SiteContentFormState state;
  final SiteContentFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final faqs = state.draft.faqs;
    return _SectionCard(
      title: 'FAQ',
      subtitle: 'Use the arrows to reorder.',
      trailing: TextButton.icon(
        onPressed: notifier.addFaq,
        icon: const Icon(Icons.add),
        label: const Text('Add Q&A'),
      ),
      child: faqs.isEmpty
          ? const Text('No FAQ entries yet.')
          : Column(
              children: [
                for (var index = 0; index < faqs.length; index++) ...[
                  _FaqRow(
                    index: index,
                    total: faqs.length,
                    faq: faqs[index],
                    onChanged: (v) => notifier.updateFaq(index, v),
                    onRemove: () => notifier.removeFaq(index),
                    onMove: (delta) => notifier.moveFaq(index, delta),
                  ),
                  if (index < faqs.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({
    required this.index,
    required this.total,
    required this.faq,
    required this.onChanged,
    required this.onRemove,
    required this.onMove,
  });
  final int index;
  final int total;
  final FaqItem faq;
  final ValueChanged<FaqItem> onChanged;
  final VoidCallback onRemove;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReorderArrows(
          isFirst: index == 0,
          isLast: index == total - 1,
          onMove: onMove,
        ),
        Expanded(
          child: Column(
            children: [
              _TF(
                label: 'Question',
                value: faq.question,
                onChanged: (v) =>
                    onChanged(faq.copyWith(question: v)),
              ),
              _TF(
                label: 'Answer',
                value: faq.answer,
                maxLines: 3,
                onChanged: (v) =>
                    onChanged(faq.copyWith(answer: v)),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Remove',
          icon: const Icon(Icons.delete_outline),
          onPressed: onRemove,
        ),
      ],
    );
  }
}

// ---------- Contact -------------------------------------------------------

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, required this.onChanged});
  final ContactInfo contact;
  final ValueChanged<ContactInfo> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Contact + social',
      subtitle: 'Footer details and social links.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: _TF(
                label: 'Email',
                value: contact.email,
                onChanged: (v) => onChanged(contact.copyWith(email: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TF(
                label: 'Phone',
                value: contact.phone,
                onChanged: (v) => onChanged(contact.copyWith(phone: v)),
              ),
            ),
          ]),
          _TF(
            label: 'Address',
            value: contact.address,
            maxLines: 2,
            onChanged: (v) => onChanged(contact.copyWith(address: v)),
          ),
          Row(children: [
            Expanded(
              child: _TF(
                label: 'Twitter URL',
                value: contact.twitterUrl,
                onChanged: (v) =>
                    onChanged(contact.copyWith(twitterUrl: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TF(
                label: 'Instagram URL',
                value: contact.instagramUrl,
                onChanged: (v) =>
                    onChanged(contact.copyWith(instagramUrl: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TF(
                label: 'YouTube URL',
                value: contact.youtubeUrl,
                onChanged: (v) =>
                    onChanged(contact.copyWith(youtubeUrl: v)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ---------- Building blocks -----------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  // ↓↓↓ Build is below — implementations of the new cards live above this
  // sentinel block. Look for `class _InstrumentsCard`, `_AboutCard`,
  // `_NavCard`, `_FooterCard`, `_StoreBadgesCard`, `_MetaCard`.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// New section cards (Instruments / About / Nav / Footer / Store badges / Meta)
// ============================================================================

// ---------- Instruments ---------------------------------------------------

class _InstrumentsCard extends StatelessWidget {
  const _InstrumentsCard({required this.state, required this.notifier});
  final SiteContentFormState state;
  final SiteContentFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final items = state.draft.instruments;
    return _SectionCard(
      title: 'Instruments',
      subtitle:
          'The three instrument cards under the hero. Slug drives the '
          'CSS tint (guitar / piano / violin).',
      trailing: TextButton.icon(
        onPressed: notifier.addInstrument,
        icon: const Icon(Icons.add),
        label: const Text('Add instrument'),
      ),
      child: items.isEmpty
          ? const Text('No instruments yet.')
          : Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _InstrumentEditor(
                    index: i,
                    item: items[i],
                    onChanged: (v) => notifier.updateInstrument(i, v),
                    onRemove: () => notifier.removeInstrument(i),
                  ),
                  if (i < items.length - 1) const Divider(height: 24),
                ],
              ],
            ),
    );
  }
}

class _InstrumentEditor extends StatelessWidget {
  const _InstrumentEditor({
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });
  final int index;
  final InstrumentCard item;
  final ValueChanged<InstrumentCard> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: _TF(
            label: 'Slug',
            value: item.slug,
            onChanged: (v) => onChanged(item.copyWith(slug: v)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _TF(
                label: 'Title',
                value: item.title,
                onChanged: (v) => onChanged(item.copyWith(title: v)),
              ),
              _TF(
                label: 'Description',
                value: item.description,
                maxLines: 2,
                onChanged: (v) =>
                    onChanged(item.copyWith(description: v)),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Remove',
          icon: const Icon(Icons.delete_outline),
          onPressed: onRemove,
        ),
      ],
    );
  }
}

// ---------- About + stats -------------------------------------------------

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.state, required this.notifier});
  final SiteContentFormState state;
  final SiteContentFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final about = state.draft.about;
    final stats = state.draft.aboutStats;
    return _SectionCard(
      title: 'About + stats',
      subtitle: 'Mid-page blurb and the four stat tiles.',
      trailing: TextButton.icon(
        onPressed: notifier.addAboutStat,
        icon: const Icon(Icons.add),
        label: const Text('Add stat'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TF(
            label: 'Eyebrow',
            value: about.eyebrow,
            onChanged: (v) =>
                notifier.updateAbout(about.copyWith(eyebrow: v)),
          ),
          _TF(
            label: 'Title',
            value: about.title,
            maxLines: 2,
            onChanged: (v) =>
                notifier.updateAbout(about.copyWith(title: v)),
          ),
          _TF(
            label: 'Paragraph 1',
            value: about.paragraph1,
            maxLines: 4,
            onChanged: (v) =>
                notifier.updateAbout(about.copyWith(paragraph1: v)),
          ),
          _TF(
            label: 'Paragraph 2',
            value: about.paragraph2,
            maxLines: 4,
            onChanged: (v) =>
                notifier.updateAbout(about.copyWith(paragraph2: v)),
          ),
          Row(
            children: [
              Expanded(
                child: _TF(
                  label: 'Paragraph 2 link label',
                  value: about.paragraph2LinkLabel,
                  onChanged: (v) => notifier.updateAbout(
                      about.copyWith(paragraph2LinkLabel: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TF(
                  label: 'Paragraph 2 link href',
                  value: about.paragraph2LinkHref,
                  onChanged: (v) => notifier.updateAbout(
                      about.copyWith(paragraph2LinkHref: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Stats',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (stats.isEmpty)
            const Text('No stats yet.')
          else
            for (var i = 0; i < stats.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: _TF(
                        label: 'Value',
                        value: stats[i].value,
                        onChanged: (v) => notifier.updateAboutStat(
                            i, stats[i].copyWith(value: v)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TF(
                        label: 'Label',
                        value: stats[i].label,
                        onChanged: (v) => notifier.updateAboutStat(
                            i, stats[i].copyWith(label: v)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => notifier.removeAboutStat(i),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

// ---------- Become an instructor -----------------------------------------

class _InstructorCalloutCard extends StatelessWidget {
  const _InstructorCalloutCard(
      {required this.state, required this.notifier});
  final SiteContentFormState state;
  final SiteContentFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final c = state.draft.instructorCallout;
    return _SectionCard(
      title: 'Become an instructor',
      subtitle:
          'Marketing callout funneling teachers into the admin portal '
          'apply flow.',
      trailing: TextButton.icon(
        onPressed: notifier.addInstructorPerk,
        icon: const Icon(Icons.add),
        label: const Text('Add perk'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TF(
            label: 'Eyebrow',
            value: c.eyebrow,
            onChanged: (v) =>
                notifier.updateInstructorCallout(c.copyWith(eyebrow: v)),
          ),
          _TF(
            label: 'Title',
            value: c.title,
            maxLines: 2,
            onChanged: (v) =>
                notifier.updateInstructorCallout(c.copyWith(title: v)),
          ),
          _TF(
            label: 'Subtitle / body',
            value: c.subtitle,
            maxLines: 4,
            onChanged: (v) =>
                notifier.updateInstructorCallout(c.copyWith(subtitle: v)),
          ),
          Row(
            children: [
              Expanded(
                child: _TF(
                  label: 'Primary CTA label',
                  value: c.ctaLabel,
                  onChanged: (v) => notifier.updateInstructorCallout(
                      c.copyWith(ctaLabel: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TF(
                  label: 'Primary CTA href',
                  value: c.ctaHref,
                  onChanged: (v) => notifier.updateInstructorCallout(
                      c.copyWith(ctaHref: v)),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _TF(
                  label: 'Secondary CTA label',
                  value: c.secondaryCtaLabel,
                  onChanged: (v) => notifier.updateInstructorCallout(
                      c.copyWith(secondaryCtaLabel: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TF(
                  label: 'Secondary CTA href',
                  value: c.secondaryCtaHref,
                  onChanged: (v) => notifier.updateInstructorCallout(
                      c.copyWith(secondaryCtaHref: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Perks',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (c.perks.isEmpty)
            const Text('No perks yet.')
          else
            for (var i = 0; i < c.perks.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _TF(
                        label: 'Perk #${i + 1}',
                        value: c.perks[i],
                        maxLines: 2,
                        onChanged: (v) =>
                            notifier.updateInstructorPerk(i, v),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => notifier.removeInstructorPerk(i),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

// ---------- Nav -----------------------------------------------------------

class _NavCard extends StatelessWidget {
  const _NavCard({required this.state, required this.notifier});
  final SiteContentFormState state;
  final SiteContentFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final nav = state.draft.nav;
    return _SectionCard(
      title: 'Top nav',
      subtitle: 'Header link labels + the "Get the app" CTA.',
      trailing: TextButton.icon(
        onPressed: notifier.addNavLink,
        icon: const Icon(Icons.add),
        label: const Text('Add link'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _TF(
                  label: 'CTA label',
                  value: nav.ctaLabel,
                  onChanged: (v) =>
                      notifier.updateNavCta(v, nav.ctaHref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TF(
                  label: 'CTA href',
                  value: nav.ctaHref,
                  onChanged: (v) =>
                      notifier.updateNavCta(nav.ctaLabel, v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Links',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (nav.links.isEmpty)
            const Text('No links yet.')
          else
            for (var i = 0; i < nav.links.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _TF(
                        label: 'Label',
                        value: nav.links[i].label,
                        onChanged: (v) => notifier.updateNavLink(
                            i, nav.links[i].copyWith(label: v)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TF(
                        label: 'Href',
                        value: nav.links[i].href,
                        onChanged: (v) => notifier.updateNavLink(
                            i, nav.links[i].copyWith(href: v)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => notifier.removeNavLink(i),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

// ---------- Footer --------------------------------------------------------

class _FooterCard extends StatelessWidget {
  const _FooterCard({required this.state, required this.notifier});
  final SiteContentFormState state;
  final SiteContentFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final footer = state.draft.footer;
    return _SectionCard(
      title: 'Footer',
      subtitle: 'Brand tagline, link columns, copyright + credit lines.',
      trailing: TextButton.icon(
        onPressed: notifier.addFooterColumn,
        icon: const Icon(Icons.add),
        label: const Text('Add column'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TF(
            label: 'Tagline',
            value: footer.tagline,
            maxLines: 2,
            onChanged: (v) => notifier.updateFooterCopy(tagline: v),
          ),
          Row(
            children: [
              Expanded(
                child: _TF(
                  label: 'Copyright suffix',
                  value: footer.copyrightSuffix,
                  onChanged: (v) =>
                      notifier.updateFooterCopy(copyrightSuffix: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TF(
                  label: 'Credit',
                  value: footer.credit,
                  onChanged: (v) =>
                      notifier.updateFooterCopy(credit: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Columns',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (footer.columns.isEmpty)
            const Text('No columns yet.')
          else
            for (var i = 0; i < footer.columns.length; i++) ...[
              _FooterColumnEditor(
                index: i,
                column: footer.columns[i],
                onChanged: (v) => notifier.updateFooterColumn(i, v),
                onRemove: () => notifier.removeFooterColumn(i),
              ),
              if (i < footer.columns.length - 1)
                const Divider(height: 24),
            ],
        ],
      ),
    );
  }
}

class _FooterColumnEditor extends StatelessWidget {
  const _FooterColumnEditor({
    required this.index,
    required this.column,
    required this.onChanged,
    required this.onRemove,
  });
  final int index;
  final FooterColumn column;
  final ValueChanged<FooterColumn> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _TF(
                label: 'Heading',
                value: column.heading,
                onChanged: (v) =>
                    onChanged(column.copyWith(heading: v)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Link'),
              onPressed: () => onChanged(
                column.copyWith(
                  links: [...column.links, const NavLink()],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove column',
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < column.links.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 16),
            child: Row(
              children: [
                Expanded(
                  child: _TF(
                    label: 'Label',
                    value: column.links[i].label,
                    onChanged: (v) {
                      final next = [...column.links]..[i] =
                          column.links[i].copyWith(label: v);
                      onChanged(column.copyWith(links: next));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TF(
                    label: 'Href',
                    value: column.links[i].href,
                    onChanged: (v) {
                      final next = [...column.links]..[i] =
                          column.links[i].copyWith(href: v);
                      onChanged(column.copyWith(links: next));
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Remove link',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    final next = [...column.links]..removeAt(i);
                    onChanged(column.copyWith(links: next));
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------- Store badges -------------------------------------------------

class _StoreBadgesCard extends StatelessWidget {
  const _StoreBadgesCard(
      {required this.badges, required this.onChanged});
  final StoreBadges badges;
  final ValueChanged<StoreBadges> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Store badges',
      subtitle:
          'App Store / Play Store href targets. "#" hides the click target '
          'while you wait for the real listings.',
      child: Row(
        children: [
          Expanded(
            child: _TF(
              label: 'App Store href',
              value: badges.appStoreHref,
              onChanged: (v) =>
                  onChanged(badges.copyWith(appStoreHref: v)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TF(
              label: 'Play Store href',
              value: badges.playStoreHref,
              onChanged: (v) =>
                  onChanged(badges.copyWith(playStoreHref: v)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- SEO / page metadata ------------------------------------------

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.meta, required this.onChanged});
  final MetaInfo meta;
  final ValueChanged<MetaInfo> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'SEO / page metadata',
      subtitle:
          '<title>, description, OG tags, canonical URL. Applied client-'
          'side after the Firestore fetch — some legacy crawlers may still '
          'see the baseline tags in index.html.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TF(
            label: 'Page title',
            value: meta.pageTitle,
            onChanged: (v) => onChanged(meta.copyWith(pageTitle: v)),
          ),
          _TF(
            label: 'Meta description',
            value: meta.description,
            maxLines: 2,
            onChanged: (v) => onChanged(meta.copyWith(description: v)),
          ),
          _TF(
            label: 'OG title',
            value: meta.ogTitle,
            onChanged: (v) => onChanged(meta.copyWith(ogTitle: v)),
          ),
          _TF(
            label: 'OG description',
            value: meta.ogDescription,
            maxLines: 2,
            onChanged: (v) =>
                onChanged(meta.copyWith(ogDescription: v)),
          ),
          _TF(
            label: 'OG image URL',
            value: meta.ogImageUrl,
            onChanged: (v) =>
                onChanged(meta.copyWith(ogImageUrl: v)),
          ),
          _TF(
            label: 'Canonical URL',
            value: meta.canonicalUrl,
            onChanged: (v) =>
                onChanged(meta.copyWith(canonicalUrl: v)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================

/// Stateful TextField wrapper that keeps its own controller in sync
/// with the upstream `value`. Without this, every state-notifier
/// update wipes the cursor position.
class _TF extends StatefulWidget {
  const _TF({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  State<_TF> createState() => _TFState();
}

class _TFState extends State<_TF> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TF old) {
    super.didUpdateWidget(old);
    // Reconcile the controller when an external rebuild (e.g. the
    // bootstrap load) brings in fresh content. Skip if the user is
    // mid-type and the values already match (saves the cursor).
    if (widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
      _ctrl.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          labelText: widget.label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
