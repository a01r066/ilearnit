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
///
/// Sections (everything below is editable from `/admin/landing-page`):
///   • [hero]          — eyebrow / title / subtitle / 2 CTAs.
///   • [instruments]   — Guitar / Piano / Violin cards (3 by default).
///   • [features]      — Variable-length feature grid.
///   • [pricingTiers]  — Pricing cards.
///   • [faqs]          — Variable-length FAQ accordion.
///   • [about]         — About blurb + 4 stat tiles.
///   • [aboutStats]    — Numeric stat tiles (denormed alongside [about]
///                       so adding stats doesn't bloat [about]).
///   • [nav]           — Top nav links + the "Get the app" CTA.
///   • [footer]        — Brand tagline + 3 link columns + copyright.
///   • [storeBadges]   — App Store + Play Store hrefs (initially "#").
///   • [meta]          — <title>, description, OG tags, canonical URL.
///   • [contact]       — Email / phone / address / social.
@freezed
abstract class LandingContent with _$LandingContent {
  const LandingContent._();

  const factory LandingContent({
    required HeroSection hero,
    @Default(<InstrumentCard>[]) List<InstrumentCard> instruments,
    @Default(<FeatureItem>[]) List<FeatureItem> features,
    @Default(<PricingTier>[]) List<PricingTier> pricingTiers,
    @Default(<FaqItem>[]) List<FaqItem> faqs,
    required AboutSection about,
    @Default(<AboutStat>[]) List<AboutStat> aboutStats,
    required InstructorCallout instructorCallout,
    required NavSection nav,
    required FooterSection footer,
    required StoreBadges storeBadges,
    required MetaInfo meta,
    required ContactInfo contact,
    DateTime? updatedAt,
  }) = _LandingContent;

  /// Sensible defaults so the admin form starts in a sane state when
  /// the Firestore doc doesn't exist yet. Mirrors the static HTML
  /// fallback in `web/public/index.html` so the seeded site looks
  /// identical to the cold-cache fallback.
  factory LandingContent.initial() => const LandingContent(
        hero: HeroSection(
          eyebrow: 'Online classical lessons',
          title: 'Master guitar, piano, and violin with concert-level instructors.',
          subtitle:
              'iLearnIt brings world-class classical musicians into your '
              'living room. Stream structured courses, download sheet '
              'music and exercises, and practice on your own schedule.',
          ctaPrimaryLabel: 'Start learning today',
          ctaPrimaryHref: '#download',
          ctaSecondaryLabel: 'Browse instruments',
          ctaSecondaryHref: '#instruments',
          imageUrl: '',
        ),
        instruments: [
          InstrumentCard(
            slug: 'guitar',
            title: 'Guitar',
            description:
                'Classical, Spanish, fingerstyle and Renaissance lute '
                'repertoire from Sor to Villa-Lobos.',
          ),
          InstrumentCard(
            slug: 'piano',
            title: 'Piano',
            description:
                'Bach, Chopin, Beethoven, Liszt — deep interpretive '
                'analysis from concert-stage pianists.',
          ),
          InstrumentCard(
            slug: 'violin',
            title: 'Violin',
            description:
                'Bach Partitas to Paganini Caprices — Russian school, '
                'baroque, and contemporary repertoire.',
          ),
        ],
        about: AboutSection(
          eyebrow: 'About iLearnIt',
          title: 'Music education without the conservatory price tag.',
          paragraph1:
              'We started iLearnIt because we believed great classical '
              "instruction shouldn't depend on living in a major city. We "
              'bring concert-stage instructors — Bach specialists, '
              'Russian-school violinists, flamenco-classical guitarists — '
              'directly into your practice room.',
          paragraph2:
              'Every course is filmed in studio, structured into clear '
              'sections, and paired with downloadable scores and exercises.',
          paragraph2LinkLabel: 'Read our full story →',
          paragraph2LinkHref: '/about.html',
        ),
        aboutStats: [
          AboutStat(value: '10+', label: 'Concert instructors'),
          AboutStat(value: '100+', label: 'Structured courses'),
          AboutStat(value: '2,200+', label: 'Video & audio lessons'),
          AboutStat(value: '3', label: 'Instruments'),
        ],
        instructorCallout: InstructorCallout(
          eyebrow: 'Teach on iLearnIt',
          title: 'Share your craft with thousands of students.',
          subtitle:
              'Apply to teach a course. Once approved, the admin portal '
              'gives you the same toolkit our staff editors use — upload '
              'lectures, attach sheet music, and publish on your own '
              'schedule.',
          perks: [
            'A built-in audience of motivated music students.',
            'You set the price; we handle billing, platform support, and '
                'distribution.',
            'Manage courses, sections, and lectures from a single dashboard.',
            'Editorial team available for feedback on pacing and recording.',
          ],
          ctaLabel: 'Become an instructor',
          ctaHref: 'https://admin.ilearnit.info/login',
          secondaryCtaLabel: 'Read the instructor agreement',
          secondaryCtaHref: '/about.html#instructor-agreement',
        ),
        nav: NavSection(
          links: [
            NavLink(label: 'Instruments', href: '#instruments'),
            NavLink(label: 'Features', href: '#features'),
            NavLink(label: 'Pricing', href: '#pricing'),
            NavLink(label: 'FAQ', href: '#faq'),
            NavLink(label: 'About', href: '/about.html'),
          ],
          ctaLabel: 'Get the app',
          ctaHref: '#download',
        ),
        footer: FooterSection(
          tagline:
              'Online classical music lessons — guitar, piano, violin. '
              'Concert-level instructors, lifetime access.',
          columns: [
            FooterColumn(
              heading: 'Product',
              links: [
                NavLink(label: 'Instruments', href: '#instruments'),
                NavLink(label: 'Pricing', href: '#pricing'),
                NavLink(label: 'Download', href: '#download'),
              ],
            ),
            FooterColumn(
              heading: 'Company',
              links: [
                NavLink(label: 'About', href: '/about.html'),
                NavLink(label: 'Contact', href: '/contact.html'),
                NavLink(label: 'Help center', href: '/help.html'),
              ],
            ),
            FooterColumn(
              heading: 'Legal',
              links: [
                NavLink(label: 'Privacy policy', href: '/privacy.html'),
                NavLink(label: 'Terms of service', href: '/terms.html'),
              ],
            ),
          ],
          copyrightSuffix: 'iLearnIt. All rights reserved.',
          credit: 'Built for musicians, with musicians.',
        ),
        storeBadges: StoreBadges(
          appStoreHref: '#',
          playStoreHref: '#',
        ),
        meta: MetaInfo(
          pageTitle:
              'iLearnIt — Classical music lessons from world-class instructors',
          description:
              'Online classical music lessons & courses for guitar, piano, '
              'and violin — taught by concert artists. Stream on iOS and '
              'Android.',
          ogTitle:
              'iLearnIt — Classical music lessons & courses',
          ogDescription:
              'Online classical lessons for guitar, piano, and violin. '
              'Stream the full curriculum on iOS and Android.',
          ogImageUrl: 'https://ilearnit.info/assets/img/og-cover.png',
          canonicalUrl: 'https://ilearnit.info/',
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

// ─────────────────────────── Hero ───────────────────────────

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

// ─────────────────────────── Instruments ─────────────────────

/// One card in the instruments grid. The [slug] is rendered on the
/// `<div class="instrument-card {slug}">` so existing CSS for the
/// three instrument tints (`.guitar` / `.piano` / `.violin`) keeps
/// working. Editors can rename the visible title / description without
/// touching CSS.
@freezed
abstract class InstrumentCard with _$InstrumentCard {
  const factory InstrumentCard({
    @Default('guitar') String slug,
    @Default('') String title,
    @Default('') String description,
  }) = _InstrumentCard;
}

// ─────────────────────────── Features ────────────────────────

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

// ─────────────────────────── Pricing ─────────────────────────

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

// ─────────────────────────── FAQ ─────────────────────────────

@freezed
abstract class FaqItem with _$FaqItem {
  const factory FaqItem({
    @Default('') String question,
    @Default('') String answer,
  }) = _FaqItem;
}

// ─────────────────────────── About ───────────────────────────

@freezed
abstract class AboutSection with _$AboutSection {
  const factory AboutSection({
    @Default('') String eyebrow,
    @Default('') String title,
    @Default('') String paragraph1,
    @Default('') String paragraph2,
    @Default('') String paragraph2LinkLabel,
    @Default('') String paragraph2LinkHref,
  }) = _AboutSection;
}

@freezed
abstract class AboutStat with _$AboutStat {
  const factory AboutStat({
    @Default('') String value,
    @Default('') String label,
  }) = _AboutStat;
}

// ─────────────────────────── Become an instructor ──────────

/// Marketing-side callout that funnels teachers into the admin
/// portal's `/apply` flow. The primary CTA's [ctaHref] should target
/// the admin login page (or the public landing page describing the
/// program); after they sign in, the admin router redirects students
/// to `/apply` automatically.
///
/// [perks] is editor-controlled — bullet copy that promotes the
/// program (revenue split, support, audience size). Entirely optional
/// — an empty list hides the bullet block while keeping the section.
@freezed
abstract class InstructorCallout with _$InstructorCallout {
  const factory InstructorCallout({
    @Default('') String eyebrow,
    @Default('') String title,
    @Default('') String subtitle,
    @Default(<String>[]) List<String> perks,
    @Default('Become an instructor') String ctaLabel,
    @Default('/admin') String ctaHref,
    @Default('') String secondaryCtaLabel,
    @Default('') String secondaryCtaHref,
  }) = _InstructorCallout;
}

// ─────────────────────────── Nav / Footer chrome ─────────────

@freezed
abstract class NavLink with _$NavLink {
  const factory NavLink({
    @Default('') String label,
    @Default('#') String href,
  }) = _NavLink;
}

@freezed
abstract class NavSection with _$NavSection {
  const factory NavSection({
    @Default(<NavLink>[]) List<NavLink> links,
    @Default('Get the app') String ctaLabel,
    @Default('#download') String ctaHref,
  }) = _NavSection;
}

@freezed
abstract class FooterColumn with _$FooterColumn {
  const factory FooterColumn({
    @Default('') String heading,
    @Default(<NavLink>[]) List<NavLink> links,
  }) = _FooterColumn;
}

@freezed
abstract class FooterSection with _$FooterSection {
  const factory FooterSection({
    @Default('') String tagline,
    @Default(<FooterColumn>[]) List<FooterColumn> columns,
    @Default('iLearnIt. All rights reserved.') String copyrightSuffix,
    @Default('Built for musicians, with musicians.') String credit,
  }) = _FooterSection;
}

@freezed
abstract class StoreBadges with _$StoreBadges {
  const factory StoreBadges({
    @Default('#') String appStoreHref,
    @Default('#') String playStoreHref,
  }) = _StoreBadges;
}

// ─────────────────────────── SEO / page metadata ─────────────

/// Edits to [MetaInfo] are applied client-side by `cms.js` after the
/// Firestore fetch resolves. That's fine for browsers and JS-rendering
/// crawlers (Googlebot / Bingbot), but some legacy bots only read the
/// static HTML — keep `web/public/index.html` baseline meta tags up
/// to date as a fallback. Long-term, this section is best paired with
/// a Cloud Function or Cloud Build step that pre-renders the doc into
/// the static HTML on each save.
@freezed
abstract class MetaInfo with _$MetaInfo {
  const factory MetaInfo({
    @Default('') String pageTitle,
    @Default('') String description,
    @Default('') String ogTitle,
    @Default('') String ogDescription,
    @Default('') String ogImageUrl,
    @Default('') String canonicalUrl,
  }) = _MetaInfo;
}

// ─────────────────────────── Contact ─────────────────────────

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
