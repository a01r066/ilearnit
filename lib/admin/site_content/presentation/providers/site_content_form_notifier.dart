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
