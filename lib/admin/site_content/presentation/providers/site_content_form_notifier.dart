import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/landing_content_model.dart';
import '../../data/site_content_datasource.dart';
import '../../domain/entities/landing_content.dart';
import 'site_content_form_state.dart';

/// Coordinates the landing-page editor: loads the current Firestore
/// content, surfaces section-edit helpers that mutate the draft, and
/// writes the whole doc on save.
class SiteContentFormNotifier extends StateNotifier<SiteContentFormState> {
  SiteContentFormNotifier({required SiteContentDataSource datasource})
      : _datasource = datasource,
        super(SiteContentFormState.initial()) {
    _bootstrap();
  }

  final SiteContentDataSource _datasource;

  Future<void> _bootstrap() async {
    try {
      final model = await _datasource.fetchOnce();
      if (model == null) return; // keep the seeded defaults
      final entity = model.toEntity();
      state = state.copyWith(draft: entity, original: entity);
    } catch (e) {
      state = state.copyWith(
        lastFailure: Failure.unexpected(
          message: 'Could not load landing-page content.',
          error: e,
        ),
      );
    }
  }

  // ----- Section edit helpers ----------------------------------------------

  void updateHero(HeroSection hero) {
    state = state.copyWith(draft: state.draft.copyWith(hero: hero));
  }

  void updateContact(ContactInfo contact) {
    state = state.copyWith(draft: state.draft.copyWith(contact: contact));
  }

  // Features
  void addFeature() {
    final next = [...state.draft.features, const FeatureItem(icon: '🎵')];
    state = state.copyWith(draft: state.draft.copyWith(features: next));
  }

  void updateFeature(int index, FeatureItem item) {
    if (index < 0 || index >= state.draft.features.length) return;
    final next = [...state.draft.features]..[index] = item;
    state = state.copyWith(draft: state.draft.copyWith(features: next));
  }

  void removeFeature(int index) {
    if (index < 0 || index >= state.draft.features.length) return;
    final next = [...state.draft.features]..removeAt(index);
    state = state.copyWith(draft: state.draft.copyWith(features: next));
  }

  void reorderFeature(int oldIndex, int newIndex) {
    final list = [...state.draft.features];
    if (oldIndex < newIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(draft: state.draft.copyWith(features: list));
  }

  /// Swap-style reorder used by the up/down arrow rows that replaced
  /// ReorderableListView (which triggered the "Cannot hit test a render
  /// box with no size" floods in Material 3).
  void moveFeature(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= state.draft.features.length) return;
    final list = [...state.draft.features];
    final item = list.removeAt(index);
    list.insert(target, item);
    state = state.copyWith(draft: state.draft.copyWith(features: list));
  }

  // Pricing tiers
  void addPricingTier() {
    final next = [...state.draft.pricingTiers, const PricingTier()];
    state = state.copyWith(
      draft: state.draft.copyWith(pricingTiers: next),
    );
  }

  void updatePricingTier(int index, PricingTier tier) {
    if (index < 0 || index >= state.draft.pricingTiers.length) return;
    final next = [...state.draft.pricingTiers]..[index] = tier;
    state = state.copyWith(
      draft: state.draft.copyWith(pricingTiers: next),
    );
  }

  void removePricingTier(int index) {
    if (index < 0 || index >= state.draft.pricingTiers.length) return;
    final next = [...state.draft.pricingTiers]..removeAt(index);
    state = state.copyWith(
      draft: state.draft.copyWith(pricingTiers: next),
    );
  }

  // FAQ
  void addFaq() {
    final next = [...state.draft.faqs, const FaqItem()];
    state = state.copyWith(draft: state.draft.copyWith(faqs: next));
  }

  void updateFaq(int index, FaqItem item) {
    if (index < 0 || index >= state.draft.faqs.length) return;
    final next = [...state.draft.faqs]..[index] = item;
    state = state.copyWith(draft: state.draft.copyWith(faqs: next));
  }

  void removeFaq(int index) {
    if (index < 0 || index >= state.draft.faqs.length) return;
    final next = [...state.draft.faqs]..removeAt(index);
    state = state.copyWith(draft: state.draft.copyWith(faqs: next));
  }

  void reorderFaq(int oldIndex, int newIndex) {
    final list = [...state.draft.faqs];
    if (oldIndex < newIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(draft: state.draft.copyWith(faqs: list));
  }

  /// Swap-style reorder for the up/down arrow rows. See [moveFeature]
  /// for the rationale.
  void moveFaq(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= state.draft.faqs.length) return;
    final list = [...state.draft.faqs];
    final item = list.removeAt(index);
    list.insert(target, item);
    state = state.copyWith(draft: state.draft.copyWith(faqs: list));
  }

  // Instruments — 3 by default, but variable-length to support adding
  // additional verticals later (e.g. cello, flute).
  void addInstrument() {
    final next = [
      ...state.draft.instruments,
      const InstrumentCard(slug: 'guitar'),
    ];
    state = state.copyWith(
      draft: state.draft.copyWith(instruments: next),
    );
  }

  void updateInstrument(int index, InstrumentCard item) {
    if (index < 0 || index >= state.draft.instruments.length) return;
    final next = [...state.draft.instruments]..[index] = item;
    state = state.copyWith(
      draft: state.draft.copyWith(instruments: next),
    );
  }

  void removeInstrument(int index) {
    if (index < 0 || index >= state.draft.instruments.length) return;
    final next = [...state.draft.instruments]..removeAt(index);
    state = state.copyWith(
      draft: state.draft.copyWith(instruments: next),
    );
  }

  // About + stats
  void updateAbout(AboutSection about) {
    state = state.copyWith(draft: state.draft.copyWith(about: about));
  }

  void addAboutStat() {
    final next = [...state.draft.aboutStats, const AboutStat()];
    state = state.copyWith(
      draft: state.draft.copyWith(aboutStats: next),
    );
  }

  void updateAboutStat(int index, AboutStat item) {
    if (index < 0 || index >= state.draft.aboutStats.length) return;
    final next = [...state.draft.aboutStats]..[index] = item;
    state = state.copyWith(
      draft: state.draft.copyWith(aboutStats: next),
    );
  }

  void removeAboutStat(int index) {
    if (index < 0 || index >= state.draft.aboutStats.length) return;
    final next = [...state.draft.aboutStats]..removeAt(index);
    state = state.copyWith(
      draft: state.draft.copyWith(aboutStats: next),
    );
  }

  // Nav
  void updateNavCta(String label, String href) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        nav: state.draft.nav.copyWith(ctaLabel: label, ctaHref: href),
      ),
    );
  }

  void addNavLink() {
    final next = [...state.draft.nav.links, const NavLink()];
    state = state.copyWith(
      draft: state.draft.copyWith(
        nav: state.draft.nav.copyWith(links: next),
      ),
    );
  }

  void updateNavLink(int index, NavLink link) {
    if (index < 0 || index >= state.draft.nav.links.length) return;
    final next = [...state.draft.nav.links]..[index] = link;
    state = state.copyWith(
      draft: state.draft.copyWith(
        nav: state.draft.nav.copyWith(links: next),
      ),
    );
  }

  void removeNavLink(int index) {
    if (index < 0 || index >= state.draft.nav.links.length) return;
    final next = [...state.draft.nav.links]..removeAt(index);
    state = state.copyWith(
      draft: state.draft.copyWith(
        nav: state.draft.nav.copyWith(links: next),
      ),
    );
  }

  // Footer
  void updateFooterCopy({
    String? tagline,
    String? copyrightSuffix,
    String? credit,
  }) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        footer: state.draft.footer.copyWith(
          tagline: tagline ?? state.draft.footer.tagline,
          copyrightSuffix:
              copyrightSuffix ?? state.draft.footer.copyrightSuffix,
          credit: credit ?? state.draft.footer.credit,
        ),
      ),
    );
  }

  void addFooterColumn() {
    final next = [
      ...state.draft.footer.columns,
      const FooterColumn(),
    ];
    state = state.copyWith(
      draft: state.draft.copyWith(
        footer: state.draft.footer.copyWith(columns: next),
      ),
    );
  }

  void updateFooterColumn(int index, FooterColumn column) {
    if (index < 0 || index >= state.draft.footer.columns.length) return;
    final next = [...state.draft.footer.columns]..[index] = column;
    state = state.copyWith(
      draft: state.draft.copyWith(
        footer: state.draft.footer.copyWith(columns: next),
      ),
    );
  }

  void removeFooterColumn(int index) {
    if (index < 0 || index >= state.draft.footer.columns.length) return;
    final next = [...state.draft.footer.columns]..removeAt(index);
    state = state.copyWith(
      draft: state.draft.copyWith(
        footer: state.draft.footer.copyWith(columns: next),
      ),
    );
  }

  // Store badges
  void updateStoreBadges(StoreBadges badges) {
    state = state.copyWith(
      draft: state.draft.copyWith(storeBadges: badges),
    );
  }

  // Page metadata (SEO)
  void updateMeta(MetaInfo meta) {
    state = state.copyWith(draft: state.draft.copyWith(meta: meta));
  }

  // ----- Save --------------------------------------------------------------

  Future<bool> save() async {
    if (!state.canSubmit) return false;
    state = state.copyWith(
      isSubmitting: true,
      justSaved: false,
      lastFailure: null,
    );
    try {
      final model = LandingContentModel.fromEntity(state.draft);
      await _datasource.save(model);
      state = state.copyWith(
        isSubmitting: false,
        justSaved: true,
        original: state.draft,
      );
      return true;
    } catch (e, st) {
      // Surface the actual underlying error in the snackbar so
      // PERMISSION_DENIED / connectivity / serialization issues are
      // immediately visible instead of being swallowed.
      // ignore: avoid_print
      print('[site_content save] $e\n$st');
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: Failure.unexpected(
          message: 'Could not save: $e',
          error: e,
          stackTrace: st,
        ),
      );
      return false;
    }
  }

  void discardDraft() {
    state = state.copyWith(draft: state.original, lastFailure: null);
  }
}
