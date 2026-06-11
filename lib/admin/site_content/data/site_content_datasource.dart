import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/landing_content_model.dart';

/// Reads + writes the landing-page CMS doc at
/// `site_content/landing`.
///
/// Public reads (the static landing site) come through the web SDK
/// using the same path — Firestore rules grant `allow read: if true`.
/// Writes are admin-only.
class SiteContentDataSource {
  SiteContentDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('site_content').doc('landing');

  /// Live read for the admin editor — picks up other editors' saves
  /// without needing a refresh.
  Stream<LandingContentModel?> watch() =>
      _doc.snapshots().map((snap) {
        if (!snap.exists) return null;
        return LandingContentModel.fromDoc(snap);
      });

  Future<LandingContentModel?> fetchOnce() async {
    final snap = await _doc.get();
    if (!snap.exists) return null;
    return LandingContentModel.fromDoc(snap);
  }

  /// Save the entire doc. The merge: false approach is intentional —
  /// the editor always sends the full state so removed FAQ items
  /// actually disappear from Firestore (a merge would leave orphaned
  /// list entries when arrays are passed).
  ///
  /// We build the map manually rather than relying on
  /// `model.toJson()` because freezed's nested-`toJson` inference
  /// occasionally leaves child models as raw Dart objects in the
  /// output (Firestore then rejects with "Unsupported field value: a
  /// custom _HeroSectionModel object"). Calling `.toJson()` on each
  /// piece guarantees plain Maps reach Firestore.
  Future<void> save(LandingContentModel model) async {
    // Same freezed/json_serializable gotcha that the top-level fields
    // already work around: `nav.toJson()` and `footer.toJson()` return
    // a Map whose nested LIST fields are still raw model objects
    // (Firestore then rejects with "Unsupported field value: a custom
    // _NavLinkModel object"). Build those sub-maps manually so every
    // list-of-Model gets explicitly serialized via `.toJson()`.
    //
    // Same precaution as `pricingTiers.map((p) => p.toJson())` at the
    // top level — applied one nesting deeper for nav.links + each
    // footer column's links.
    final json = <String, dynamic>{
      'hero': model.hero.toJson(),
      'instruments':
          model.instruments.map((i) => i.toJson()).toList(),
      'features': model.features.map((f) => f.toJson()).toList(),
      'pricingTiers':
          model.pricingTiers.map((p) => p.toJson()).toList(),
      'faqs': model.faqs.map((f) => f.toJson()).toList(),
      'about': model.about.toJson(),
      'aboutStats':
          model.aboutStats.map((s) => s.toJson()).toList(),
      'nav': {
        ...model.nav.toJson(),
        'links': model.nav.links.map((l) => l.toJson()).toList(),
      },
      'footer': {
        ...model.footer.toJson(),
        'columns': model.footer.columns
            .map((col) => {
                  ...col.toJson(),
                  'links':
                      col.links.map((l) => l.toJson()).toList(),
                })
            .toList(),
      },
      'storeBadges': model.storeBadges.toJson(),
      'meta': model.meta.toJson(),
      'contact': model.contact.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _doc.set(json);
  }
}
