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
    @Default(<FeatureItemModel>[]) List<FeatureItemModel> features,
    @Default(<PricingTierModel>[]) List<PricingTierModel> pricingTiers,
    @Default(<FaqItemModel>[]) List<FaqItemModel> faqs,
    required ContactInfoModel contact,
    @TimestampConverter() DateTime? updatedAt,
  }) = _LandingContentModel;

  factory LandingContentModel.fromJson(Map<String, dynamic> json) =>
      _$LandingContentModelFromJson(json);

  /// Reads the singleton doc at `site_content/landing`.
  factory LandingContentModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return LandingContentModel.fromJson(data);
  }

  LandingContent toEntity() => LandingContent(
        hero: hero.toEntity(),
        features: features.map((f) => f.toEntity()).toList(),
        pricingTiers:
            pricingTiers.map((p) => p.toEntity()).toList(),
        faqs: faqs.map((f) => f.toEntity()).toList(),
        contact: contact.toEntity(),
        updatedAt: updatedAt,
      );

  static LandingContentModel fromEntity(LandingContent e) =>
      LandingContentModel(
        hero: HeroSectionModel.fromEntity(e.hero),
        features:
            e.features.map(FeatureItemModel.fromEntity).toList(),
        pricingTiers:
            e.pricingTiers.map(PricingTierModel.fromEntity).toList(),
        faqs: e.faqs.map(FaqItemModel.fromEntity).toList(),
        contact: ContactInfoModel.fromEntity(e.contact),
        updatedAt: e.updatedAt,
      );
}

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
