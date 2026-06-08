import 'package:freezed_annotation/freezed_annotation.dart';

part 'landing_content.freezed.dart';

/// All editable content on the public landing page. Persisted as a
/// single Firestore doc at `site_content/landing` so the admin only
/// has to save once and the public web reads it in a single round-
/// trip.
///
/// Why one big doc and not separate subcollections?
///   • The static landing site is HTML+JS — fewer Firestore reads
///     means a faster first paint, especially on cold cache.
///   • Editorial scope is small (one hero, ~6 features, ~10 FAQ).
///   • If we cross the 1 MiB doc-size cap we'll split (unlikely).
@freezed
abstract class LandingContent with _$LandingContent {
  const LandingContent._();

  const factory LandingContent({
    required HeroSection hero,
    @Default(<FeatureItem>[]) List<FeatureItem> features,
    @Default(<PricingTier>[]) List<PricingTier> pricingTiers,
    @Default(<FaqItem>[]) List<FaqItem> faqs,
    required ContactInfo contact,
    DateTime? updatedAt,
  }) = _LandingContent;

  /// Sensible defaults so the admin form starts in a sane state when
  /// the Firestore doc doesn't exist yet.
  factory LandingContent.initial() => const LandingContent(
        hero: HeroSection(
          eyebrow: 'iLearnIt',
          title: 'Classical music lessons, taught by world-class artists.',
          subtitle:
              'On-demand video lessons, structured curricula, and a '
              'practice toolkit — all in one app.',
          ctaPrimaryLabel: 'Start learning',
          ctaPrimaryHref: '/help',
          ctaSecondaryLabel: 'Browse courses',
          ctaSecondaryHref: '/help#courses',
          imageUrl: '',
        ),
        contact: ContactInfo(
          email: 'hello@ilearnit.info',
          phone: '',
          address: '',
          twitterUrl: '',
          instagramUrl: '',
          youtubeUrl: '',
        ),
      );
}

@freezed
abstract class HeroSection with _$HeroSection {
  const factory HeroSection({
    @Default('') String eyebrow,
    @Default('') String title,
    @Default('') String subtitle,
    @Default('') String ctaPrimaryLabel,
    @Default('') String ctaPrimaryHref,
    @Default('') String ctaSecondaryLabel,
    @Default('') String ctaSecondaryHref,
    @Default('') String imageUrl,
  }) = _HeroSection;
}

@freezed
abstract class FeatureItem with _$FeatureItem {
  const factory FeatureItem({
    /// Emoji or short icon glyph rendered at the top of the card.
    /// Keeping this as plain text avoids a font dependency on the
    /// public web bundle.
    @Default('🎵') String icon,
    @Default('') String title,
    @Default('') String description,
  }) = _FeatureItem;
}

@freezed
abstract class PricingTier with _$PricingTier {
  const factory PricingTier({
    @Default('') String name,
    @Default('') String priceLabel,
    @Default('') String billingNote,
    @Default('') String ctaLabel,
    @Default('') String ctaHref,
    @Default(false) bool isFeatured,
    @Default(<String>[]) List<String> perks,
  }) = _PricingTier;
}

@freezed
abstract class FaqItem with _$FaqItem {
  const factory FaqItem({
    @Default('') String question,
    @Default('') String answer,
  }) = _FaqItem;
}

@freezed
abstract class ContactInfo with _$ContactInfo {
  const factory ContactInfo({
    @Default('') String email,
    @Default('') String phone,
    @Default('') String address,
    @Default('') String twitterUrl,
    @Default('') String instagramUrl,
    @Default('') String youtubeUrl,
  }) = _ContactInfo;
}
