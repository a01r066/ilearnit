import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../features/auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/landing_content.dart';

part 'landing_content_model.freezed.dart';
part 'landing_content_model.g.dart';

@freezed
abstract class LandingContentModel with _$LandingContentModel {
  const LandingContentModel._();

  const factory LandingContentModel({
    required HeroSectionModel hero,
    @Default(<InstrumentCardModel>[]) List<InstrumentCardModel> instruments,
    @Default(<FeatureItemModel>[]) List<FeatureItemModel> features,
    @Default(<PricingTierModel>[]) List<PricingTierModel> pricingTiers,
    @Default(<FaqItemModel>[]) List<FaqItemModel> faqs,
    required AboutSectionModel about,
    @Default(<AboutStatModel>[]) List<AboutStatModel> aboutStats,
    required InstructorCalloutModel instructorCallout,
    required NavSectionModel nav,
    required FooterSectionModel footer,
    required StoreBadgesModel storeBadges,
    required MetaInfoModel meta,
    required ContactInfoModel contact,
    @TimestampConverter() DateTime? updatedAt,
  }) = _LandingContentModel;

  factory LandingContentModel.fromJson(Map<String, dynamic> json) =>
      _$LandingContentModelFromJson(json);

  /// Reads the singleton doc at `site_content/landing`. Missing fields
  /// fall back to the model's @Default values via freezed's fromJson —
  /// so a legacy doc that only carries `hero` / `features` / `pricingTiers`
  /// / `faqs` / `contact` still parses cleanly. The defaults below cover
  /// instruments, about, aboutStats, nav, footer, storeBadges, meta.
  factory LandingContentModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    // freezed's @Default + fromJson don't backfill required-typed nested
    // models, so seed them here before deserialising.
    final patched = <String, dynamic>{
      'about': const <String, dynamic>{},
      'nav': const <String, dynamic>{},
      'footer': const <String, dynamic>{},
      'storeBadges': const <String, dynamic>{},
      'meta': const <String, dynamic>{},
      'instructorCallout': const <String, dynamic>{},
      ...data,
    };
    return LandingContentModel.fromJson(patched);
  }

  LandingContent toEntity() => LandingContent(
        hero: hero.toEntity(),
        instruments: instruments.map((i) => i.toEntity()).toList(),
        features: features.map((f) => f.toEntity()).toList(),
        pricingTiers:
            pricingTiers.map((p) => p.toEntity()).toList(),
        faqs: faqs.map((f) => f.toEntity()).toList(),
        about: about.toEntity(),
        aboutStats: aboutStats.map((s) => s.toEntity()).toList(),
        instructorCallout: instructorCallout.toEntity(),
        nav: nav.toEntity(),
        footer: footer.toEntity(),
        storeBadges: storeBadges.toEntity(),
        meta: meta.toEntity(),
        contact: contact.toEntity(),
        updatedAt: updatedAt,
      );

  static LandingContentModel fromEntity(LandingContent e) =>
      LandingContentModel(
        hero: HeroSectionModel.fromEntity(e.hero),
        instruments:
            e.instruments.map(InstrumentCardModel.fromEntity).toList(),
        features:
            e.features.map(FeatureItemModel.fromEntity).toList(),
        pricingTiers:
            e.pricingTiers.map(PricingTierModel.fromEntity).toList(),
        faqs: e.faqs.map(FaqItemModel.fromEntity).toList(),
        about: AboutSectionModel.fromEntity(e.about),
        aboutStats: e.aboutStats.map(AboutStatModel.fromEntity).toList(),
        instructorCallout:
            InstructorCalloutModel.fromEntity(e.instructorCallout),
        nav: NavSectionModel.fromEntity(e.nav),
        footer: FooterSectionModel.fromEntity(e.footer),
        storeBadges: StoreBadgesModel.fromEntity(e.storeBadges),
        meta: MetaInfoModel.fromEntity(e.meta),
        contact: ContactInfoModel.fromEntity(e.contact),
        updatedAt: e.updatedAt,
      );
}

// ─────────────────────────── Hero ───────────────────────────

@freezed
abstract class HeroSectionModel with _$HeroSectionModel {
  const HeroSectionModel._();

  const factory HeroSectionModel({
    @Default('') String eyebrow,
    @Default('') String title,
    @Default('') String subtitle,
    @Default('') String ctaPrimaryLabel,
    @Default('') String ctaPrimaryHref,
    @Default('') String ctaSecondaryLabel,
    @Default('') String ctaSecondaryHref,
    @Default('') String imageUrl,
  }) = _HeroSectionModel;

  factory HeroSectionModel.fromJson(Map<String, dynamic> json) =>
      _$HeroSectionModelFromJson(json);

  HeroSection toEntity() => HeroSection(
        eyebrow: eyebrow,
        title: title,
        subtitle: subtitle,
        ctaPrimaryLabel: ctaPrimaryLabel,
        ctaPrimaryHref: ctaPrimaryHref,
        ctaSecondaryLabel: ctaSecondaryLabel,
        ctaSecondaryHref: ctaSecondaryHref,
        imageUrl: imageUrl,
      );

  static HeroSectionModel fromEntity(HeroSection e) => HeroSectionModel(
        eyebrow: e.eyebrow,
        title: e.title,
        subtitle: e.subtitle,
        ctaPrimaryLabel: e.ctaPrimaryLabel,
        ctaPrimaryHref: e.ctaPrimaryHref,
        ctaSecondaryLabel: e.ctaSecondaryLabel,
        ctaSecondaryHref: e.ctaSecondaryHref,
        imageUrl: e.imageUrl,
      );
}

// ─────────────────────────── Instruments ─────────────────────

@freezed
abstract class InstrumentCardModel with _$InstrumentCardModel {
  const InstrumentCardModel._();

  const factory InstrumentCardModel({
    @Default('guitar') String slug,
    @Default('') String title,
    @Default('') String description,
  }) = _InstrumentCardModel;

  factory InstrumentCardModel.fromJson(Map<String, dynamic> json) =>
      _$InstrumentCardModelFromJson(json);

  InstrumentCard toEntity() =>
      InstrumentCard(slug: slug, title: title, description: description);

  static InstrumentCardModel fromEntity(InstrumentCard e) =>
      InstrumentCardModel(
          slug: e.slug, title: e.title, description: e.description);
}

// ─────────────────────────── Features ────────────────────────

@freezed
abstract class FeatureItemModel with _$FeatureItemModel {
  const FeatureItemModel._();

  const factory FeatureItemModel({
    @Default('🎵') String icon,
    @Default('') String title,
    @Default('') String description,
  }) = _FeatureItemModel;

  factory FeatureItemModel.fromJson(Map<String, dynamic> json) =>
      _$FeatureItemModelFromJson(json);

  FeatureItem toEntity() => FeatureItem(
        icon: icon,
        title: title,
        description: description,
      );

  static FeatureItemModel fromEntity(FeatureItem e) => FeatureItemModel(
        icon: e.icon,
        title: e.title,
        description: e.description,
      );
}

// ─────────────────────────── Pricing ─────────────────────────

@freezed
abstract class PricingTierModel with _$PricingTierModel {
  const PricingTierModel._();

  const factory PricingTierModel({
    @Default('') String name,
    @Default('') String priceLabel,
    @Default('') String billingNote,
    @Default('') String ctaLabel,
    @Default('') String ctaHref,
    @Default(false) bool isFeatured,
    @Default(<String>[]) List<String> perks,
  }) = _PricingTierModel;

  factory PricingTierModel.fromJson(Map<String, dynamic> json) =>
      _$PricingTierModelFromJson(json);

  PricingTier toEntity() => PricingTier(
        name: name,
        priceLabel: priceLabel,
        billingNote: billingNote,
        ctaLabel: ctaLabel,
        ctaHref: ctaHref,
        isFeatured: isFeatured,
        perks: perks,
      );

  static PricingTierModel fromEntity(PricingTier e) => PricingTierModel(
        name: e.name,
        priceLabel: e.priceLabel,
        billingNote: e.billingNote,
        ctaLabel: e.ctaLabel,
        ctaHref: e.ctaHref,
        isFeatured: e.isFeatured,
        perks: e.perks,
      );
}

// ─────────────────────────── FAQ ─────────────────────────────

@freezed
abstract class FaqItemModel with _$FaqItemModel {
  const FaqItemModel._();

  const factory FaqItemModel({
    @Default('') String question,
    @Default('') String answer,
  }) = _FaqItemModel;

  factory FaqItemModel.fromJson(Map<String, dynamic> json) =>
      _$FaqItemModelFromJson(json);

  FaqItem toEntity() => FaqItem(question: question, answer: answer);

  static FaqItemModel fromEntity(FaqItem e) =>
      FaqItemModel(question: e.question, answer: e.answer);
}

// ─────────────────────────── About ───────────────────────────

@freezed
abstract class AboutSectionModel with _$AboutSectionModel {
  const AboutSectionModel._();

  const factory AboutSectionModel({
    @Default('') String eyebrow,
    @Default('') String title,
    @Default('') String paragraph1,
    @Default('') String paragraph2,
    @Default('') String paragraph2LinkLabel,
    @Default('') String paragraph2LinkHref,
  }) = _AboutSectionModel;

  factory AboutSectionModel.fromJson(Map<String, dynamic> json) =>
      _$AboutSectionModelFromJson(json);

  AboutSection toEntity() => AboutSection(
        eyebrow: eyebrow,
        title: title,
        paragraph1: paragraph1,
        paragraph2: paragraph2,
        paragraph2LinkLabel: paragraph2LinkLabel,
        paragraph2LinkHref: paragraph2LinkHref,
      );

  static AboutSectionModel fromEntity(AboutSection e) =>
      AboutSectionModel(
        eyebrow: e.eyebrow,
        title: e.title,
        paragraph1: e.paragraph1,
        paragraph2: e.paragraph2,
        paragraph2LinkLabel: e.paragraph2LinkLabel,
        paragraph2LinkHref: e.paragraph2LinkHref,
      );
}

@freezed
abstract class AboutStatModel with _$AboutStatModel {
  const AboutStatModel._();

  const factory AboutStatModel({
    @Default('') String value,
    @Default('') String label,
  }) = _AboutStatModel;

  factory AboutStatModel.fromJson(Map<String, dynamic> json) =>
      _$AboutStatModelFromJson(json);

  AboutStat toEntity() => AboutStat(value: value, label: label);

  static AboutStatModel fromEntity(AboutStat e) =>
      AboutStatModel(value: e.value, label: e.label);
}

// ─────────────────────────── Become an instructor ──────────

@freezed
abstract class InstructorCalloutModel with _$InstructorCalloutModel {
  const InstructorCalloutModel._();

  const factory InstructorCalloutModel({
    @Default('') String eyebrow,
    @Default('') String title,
    @Default('') String subtitle,
    @Default(<String>[]) List<String> perks,
    @Default('Become an instructor') String ctaLabel,
    @Default('/admin') String ctaHref,
    @Default('') String secondaryCtaLabel,
    @Default('') String secondaryCtaHref,
  }) = _InstructorCalloutModel;

  factory InstructorCalloutModel.fromJson(Map<String, dynamic> json) =>
      _$InstructorCalloutModelFromJson(json);

  InstructorCallout toEntity() => InstructorCallout(
        eyebrow: eyebrow,
        title: title,
        subtitle: subtitle,
        perks: perks,
        ctaLabel: ctaLabel,
        ctaHref: ctaHref,
        secondaryCtaLabel: secondaryCtaLabel,
        secondaryCtaHref: secondaryCtaHref,
      );

  static InstructorCalloutModel fromEntity(InstructorCallout e) =>
      InstructorCalloutModel(
        eyebrow: e.eyebrow,
        title: e.title,
        subtitle: e.subtitle,
        perks: e.perks,
        ctaLabel: e.ctaLabel,
        ctaHref: e.ctaHref,
        secondaryCtaLabel: e.secondaryCtaLabel,
        secondaryCtaHref: e.secondaryCtaHref,
      );
}

// ─────────────────────────── Nav / Footer chrome ─────────────

@freezed
abstract class NavLinkModel with _$NavLinkModel {
  const NavLinkModel._();

  const factory NavLinkModel({
    @Default('') String label,
    @Default('#') String href,
  }) = _NavLinkModel;

  factory NavLinkModel.fromJson(Map<String, dynamic> json) =>
      _$NavLinkModelFromJson(json);

  NavLink toEntity() => NavLink(label: label, href: href);

  static NavLinkModel fromEntity(NavLink e) =>
      NavLinkModel(label: e.label, href: e.href);
}

@freezed
abstract class NavSectionModel with _$NavSectionModel {
  const NavSectionModel._();

  const factory NavSectionModel({
    @Default(<NavLinkModel>[]) List<NavLinkModel> links,
    @Default('Get the app') String ctaLabel,
    @Default('#download') String ctaHref,
  }) = _NavSectionModel;

  factory NavSectionModel.fromJson(Map<String, dynamic> json) =>
      _$NavSectionModelFromJson(json);

  NavSection toEntity() => NavSection(
        links: links.map((l) => l.toEntity()).toList(),
        ctaLabel: ctaLabel,
        ctaHref: ctaHref,
      );

  static NavSectionModel fromEntity(NavSection e) => NavSectionModel(
        links: e.links.map(NavLinkModel.fromEntity).toList(),
        ctaLabel: e.ctaLabel,
        ctaHref: e.ctaHref,
      );
}

@freezed
abstract class FooterColumnModel with _$FooterColumnModel {
  const FooterColumnModel._();

  const factory FooterColumnModel({
    @Default('') String heading,
    @Default(<NavLinkModel>[]) List<NavLinkModel> links,
  }) = _FooterColumnModel;

  factory FooterColumnModel.fromJson(Map<String, dynamic> json) =>
      _$FooterColumnModelFromJson(json);

  FooterColumn toEntity() => FooterColumn(
        heading: heading,
        links: links.map((l) => l.toEntity()).toList(),
      );

  static FooterColumnModel fromEntity(FooterColumn e) =>
      FooterColumnModel(
        heading: e.heading,
        links: e.links.map(NavLinkModel.fromEntity).toList(),
      );
}

@freezed
abstract class FooterSectionModel with _$FooterSectionModel {
  const FooterSectionModel._();

  const factory FooterSectionModel({
    @Default('') String tagline,
    @Default(<FooterColumnModel>[]) List<FooterColumnModel> columns,
    @Default('iLearnIt. All rights reserved.') String copyrightSuffix,
    @Default('Built for musicians, with musicians.') String credit,
  }) = _FooterSectionModel;

  factory FooterSectionModel.fromJson(Map<String, dynamic> json) =>
      _$FooterSectionModelFromJson(json);

  FooterSection toEntity() => FooterSection(
        tagline: tagline,
        columns: columns.map((c) => c.toEntity()).toList(),
        copyrightSuffix: copyrightSuffix,
        credit: credit,
      );

  static FooterSectionModel fromEntity(FooterSection e) =>
      FooterSectionModel(
        tagline: e.tagline,
        columns: e.columns.map(FooterColumnModel.fromEntity).toList(),
        copyrightSuffix: e.copyrightSuffix,
        credit: e.credit,
      );
}

@freezed
abstract class StoreBadgesModel with _$StoreBadgesModel {
  const StoreBadgesModel._();

  const factory StoreBadgesModel({
    @Default('#') String appStoreHref,
    @Default('#') String playStoreHref,
  }) = _StoreBadgesModel;

  factory StoreBadgesModel.fromJson(Map<String, dynamic> json) =>
      _$StoreBadgesModelFromJson(json);

  StoreBadges toEntity() =>
      StoreBadges(appStoreHref: appStoreHref, playStoreHref: playStoreHref);

  static StoreBadgesModel fromEntity(StoreBadges e) => StoreBadgesModel(
        appStoreHref: e.appStoreHref,
        playStoreHref: e.playStoreHref,
      );
}

// ─────────────────────────── SEO / page metadata ─────────────

@freezed
abstract class MetaInfoModel with _$MetaInfoModel {
  const MetaInfoModel._();

  const factory MetaInfoModel({
    @Default('') String pageTitle,
    @Default('') String description,
    @Default('') String ogTitle,
    @Default('') String ogDescription,
    @Default('') String ogImageUrl,
    @Default('') String canonicalUrl,
  }) = _MetaInfoModel;

  factory MetaInfoModel.fromJson(Map<String, dynamic> json) =>
      _$MetaInfoModelFromJson(json);

  MetaInfo toEntity() => MetaInfo(
        pageTitle: pageTitle,
        description: description,
        ogTitle: ogTitle,
        ogDescription: ogDescription,
        ogImageUrl: ogImageUrl,
        canonicalUrl: canonicalUrl,
      );

  static MetaInfoModel fromEntity(MetaInfo e) => MetaInfoModel(
        pageTitle: e.pageTitle,
        description: e.description,
        ogTitle: e.ogTitle,
        ogDescription: e.ogDescription,
        ogImageUrl: e.ogImageUrl,
        canonicalUrl: e.canonicalUrl,
      );
}

// ─────────────────────────── Contact ─────────────────────────

@freezed
abstract class ContactInfoModel with _$ContactInfoModel {
  const ContactInfoModel._();

  const factory ContactInfoModel({
    @Default('') String email,
    @Default('') String phone,
    @Default('') String address,
    @Default('') String twitterUrl,
    @Default('') String instagramUrl,
    @Default('') String youtubeUrl,
  }) = _ContactInfoModel;

  factory ContactInfoModel.fromJson(Map<String, dynamic> json) =>
      _$ContactInfoModelFromJson(json);

  ContactInfo toEntity() => ContactInfo(
        email: email,
        phone: phone,
        address: address,
        twitterUrl: twitterUrl,
        instagramUrl: instagramUrl,
        youtubeUrl: youtubeUrl,
      );

  static ContactInfoModel fromEntity(ContactInfo e) => ContactInfoModel(
        email: e.email,
        phone: e.phone,
        address: e.address,
        twitterUrl: e.twitterUrl,
        instagramUrl: e.instagramUrl,
        youtubeUrl: e.youtubeUrl,
      );
}
