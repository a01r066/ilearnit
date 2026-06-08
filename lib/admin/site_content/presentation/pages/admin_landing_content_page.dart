import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          _FeaturesCard(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _PricingCard(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _FaqCard(state: state, notifier: notifier),
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
    return _SectionCard(
      title: 'Features',
      subtitle: 'Highlight cards under the hero. Drag to reorder.',
      trailing: TextButton.icon(
        onPressed: notifier.addFeature,
        icon: const Icon(Icons.add),
        label: const Text('Add feature'),
      ),
      child: features.isEmpty
          ? const Text('No features yet.')
          : ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: features.length,
              onReorder: notifier.reorderFeature,
              itemBuilder: (context, index) {
                final f = features[index];
                return Padding(
                  key: ValueKey('feature-$index'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                          child: Icon(Icons.drag_indicator),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: _TF(
                          label: 'Icon',
                          value: f.icon,
                          onChanged: (v) => notifier.updateFeature(
                              index, f.copyWith(icon: v)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            _TF(
                              label: 'Title',
                              value: f.title,
                              onChanged: (v) => notifier.updateFeature(
                                  index, f.copyWith(title: v)),
                            ),
                            _TF(
                              label: 'Description',
                              value: f.description,
                              maxLines: 2,
                              onChanged: (v) => notifier.updateFeature(
                                  index, f.copyWith(description: v)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => notifier.removeFeature(index),
                      ),
                    ],
                  ),
                );
              },
            ),
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
      subtitle: 'Drag to reorder.',
      trailing: TextButton.icon(
        onPressed: notifier.addFaq,
        icon: const Icon(Icons.add),
        label: const Text('Add Q&A'),
      ),
      child: faqs.isEmpty
          ? const Text('No FAQ entries yet.')
          : ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: faqs.length,
              onReorder: notifier.reorderFaq,
              itemBuilder: (context, index) {
                final q = faqs[index];
                return Padding(
                  key: ValueKey('faq-$index'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                          child: Icon(Icons.drag_indicator),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _TF(
                              label: 'Question',
                              value: q.question,
                              onChanged: (v) => notifier.updateFaq(
                                  index, q.copyWith(question: v)),
                            ),
                            _TF(
                              label: 'Answer',
                              value: q.answer,
                              maxLines: 3,
                              onChanged: (v) => notifier.updateFaq(
                                  index, q.copyWith(answer: v)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => notifier.removeFaq(index),
                      ),
                    ],
                  ),
                );
              },
            ),
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
