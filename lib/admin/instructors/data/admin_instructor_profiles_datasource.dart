import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../features/instructors/data/models/instructor_model.dart';
import 'instructor_backfill_report.dart';

/// Admin write methods for the public-facing `instructors` collection.
///
/// **Schema invariant (post-refactor 2026-06).** Every
/// `instructors/{id}` doc id equals a Firebase Auth UID. The
/// `instructors/{uid}` doc is the public-facing complement to
/// `users/{uid}` (private auth + role). The consumer side reads via
/// `InstructorsDataSource` as a direct point read — no bridge field,
/// no fallback query.
///
/// Legacy auto-id docs from the pre-refactor era are handled by
/// [migrateLegacyProfiles]: it copies each `instructors/{auto-id}` to
/// `instructors/{userId}` (or resolves via email / displayName match
/// if userId was never set) and deletes the original.
class AdminInstructorProfilesDataSource {
  AdminInstructorProfilesDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.instructors);

  // ----- Reads -------------------------------------------------------

  Stream<List<InstructorModel>> watchAll() => _col
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(InstructorModel.fromDoc).toList());

  Stream<InstructorModel?> watchById(String id) =>
      _col.doc(id).snapshots().map(
            (d) => d.exists ? InstructorModel.fromDoc(d) : null,
          );

  // ----- Writes ------------------------------------------------------

  /// Create a new instructor profile.
  ///
  /// The model's `id` must be the auth UID of the user the profile
  /// belongs to. For guest instructors (no real auth user), generate a
  /// random uid at the call site — the model is shape-agnostic about
  /// what id you pick, as long as it's stable.
  Future<String> create(InstructorModel m) async {
    if (m.id.isEmpty) {
      throw ArgumentError(
        'InstructorModel.id must be set to the auth UID before create.',
      );
    }
    await _col.doc(m.id).set(
          _toPayload(m, joinedAt: m.joinedAt ?? DateTime.now()),
        );
    return m.id;
  }

  /// One-click promotion: ensure an `instructors/{uid}` profile exists
  /// seeded from a user doc. Idempotent at the doc-id level —
  /// re-running on the same uid just refreshes the displayName / email
  /// / photoUrl fields without disturbing bio / tagline / social links
  /// (which the admin may have already populated).
  Future<String> createFromUser({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
  }) async {
    if (uid.isEmpty) {
      throw ArgumentError('uid must not be empty');
    }

    final ref = _col.doc(uid);
    final snap = await ref.get();
    final payload = <String, dynamic>{
      'name': displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : (email?.trim() ?? ''),
      'photoUrl': photoUrl ?? '',
    };
    if (email != null && email.trim().isNotEmpty) {
      payload['email'] = email.trim();
      payload['emailLower'] = email.trim().toLowerCase();
    }

    if (!snap.exists) {
      // First write — seed sensible defaults so the consumer detail
      // page renders cleanly the moment the profile goes live.
      payload.addAll({
        'bio': '',
        'rating': 0.0,
        'reviewCount': 0,
        'studentCount': 0,
        'specialties': <String>[],
        'featuredCourseIds': <String>[],
        'joinedAt': FieldValue.serverTimestamp(),
      });
    }
    await ref.set(payload, SetOptions(merge: true));
    return uid;
  }

  Future<void> update(InstructorModel m) =>
      _col.doc(m.id).set(_toPayload(m), SetOptions(merge: true));

  Future<void> delete(String id) => _col.doc(id).delete();

  // ----- Sync --------------------------------------------------------

  /// Walks every user with `role == 'instructor'` and ensures each has
  /// an `instructors/{uid}` profile. Idempotent — already-linked users
  /// just get their name / email / photoUrl refreshed, no clobber of
  /// admin-curated fields.
  ///
  /// This is the bulk version of the per-row "Create profile" button.
  Future<InstructorBackfillReport> syncProfilesForAllInstructors() async {
    final users = _firestore.collection('users');
    final usersSnap =
        await users.where('role', isEqualTo: 'instructor').get();
    // Existing profiles by id (which IS the uid post-refactor).
    final profSnap = await _col.get();
    final existing = <String>{for (final d in profSnap.docs) d.id};

    final rows = <InstructorBackfillRow>[];
    for (final userDoc in usersSnap.docs) {
      final uid = userDoc.id;
      final data = userDoc.data();
      final displayName = (data['displayName'] as String?) ?? '';
      final email = (data['email'] as String?) ?? '';
      final photoUrl = (data['photoUrl'] as String?) ?? '';
      final displayLabel = displayName.isNotEmpty ? displayName : email;

      final alreadyHad = existing.contains(uid);
      try {
        await createFromUser(
          uid: uid,
          displayName: displayName,
          email: email,
          photoUrl: photoUrl,
        );
        rows.add(InstructorBackfillRow(
          instructorId: uid,
          instructorName: displayLabel,
          outcome: alreadyHad
              ? InstructorBackfillOutcome.alreadyLinked
              : InstructorBackfillOutcome.matchedByEmail,
          linkedUserId: uid,
          notes: alreadyHad
              ? 'Profile already existed — refreshed display fields.'
              : 'Created instructors/$uid from user.',
        ));
      } catch (e) {
        rows.add(InstructorBackfillRow(
          instructorId: uid,
          instructorName: displayLabel,
          outcome: InstructorBackfillOutcome.errored,
          notes: 'Failed: $e',
        ));
      }
    }

    return InstructorBackfillReport(
      scanned: usersSnap.docs.length,
      rows: rows,
    );
  }

  // ----- Legacy migration --------------------------------------------

  /// One-shot migration for instructor docs that were created before
  /// the `instructors/{uid}` schema invariant existed. For each legacy
  /// doc:
  ///
  ///   1. If `userId` is set, copy the doc to `instructors/{userId}`
  ///      and delete the original (unless it's already at the right
  ///      key).
  ///   2. If `userId` is unset, try to resolve via email match in
  ///      `users`. Same one-shot copy + delete on a unique hit.
  ///   3. Otherwise, fall back to a strict displayName match.
  ///   4. Anything still unresolved is left in place with an
  ///      `ambiguous` / `noMatch` row in the report so the admin can
  ///      fix manually.
  ///
  /// Safe to re-run — already-migrated docs (where doc.id is a known
  /// uid) are reported as `alreadyLinked` and skipped.
  Future<InstructorBackfillReport> migrateLegacyProfiles() async {
    final users = _firestore.collection('users');
    final snap = await _col.get();
    final rows = <InstructorBackfillRow>[];

    for (final doc in snap.docs) {
      final data = doc.data();
      final id = doc.id;
      final legacyUserId = (data['userId'] as String?)?.trim() ?? '';
      final name = (data['name'] as String?) ?? '';
      final email = (data['email'] as String?) ?? '';

      // Case A — already in the canonical shape: doc id == legacy
      // userId field, OR the doc id directly matches a user uid.
      if (legacyUserId == id && id.isNotEmpty) {
        rows.add(InstructorBackfillRow(
          instructorId: id,
          instructorName: name,
          outcome: InstructorBackfillOutcome.alreadyLinked,
          linkedUserId: id,
          notes: 'Already canonical.',
        ));
        continue;
      }

      // Resolve target uid: prefer legacy userId, then email, then
      // displayName.
      String? targetUid;
      String matchNote;

      if (legacyUserId.isNotEmpty) {
        targetUid = legacyUserId;
        matchNote = 'Migrated via legacy userId field.';
      } else if (email.trim().isNotEmpty) {
        final trimmed = email.trim();
        final lower = trimmed.toLowerCase();
        var q =
            await users.where('email', isEqualTo: trimmed).limit(2).get();
        if (q.docs.isEmpty && lower != trimmed) {
          q = await users.where('email', isEqualTo: lower).limit(2).get();
        }
        if (q.docs.length == 1) {
          targetUid = q.docs.first.id;
          matchNote = 'Migrated via email match.';
        } else if (q.docs.length > 1) {
          rows.add(InstructorBackfillRow(
            instructorId: id,
            instructorName: name,
            outcome: InstructorBackfillOutcome.ambiguous,
            notes:
                'Email "$trimmed" matched ${q.docs.length} users — resolve manually.',
          ));
          continue;
        } else {
          // Fall through to name match.
          matchNote = '';
        }
      } else {
        matchNote = '';
      }

      if (targetUid == null && name.trim().isNotEmpty) {
        final nameTrim = name.trim();
        final q2 =
            await users.where('displayName', isEqualTo: nameTrim).limit(2).get();
        if (q2.docs.length == 1) {
          targetUid = q2.docs.first.id;
          matchNote = 'Migrated via displayName match.';
        } else if (q2.docs.length > 1) {
          rows.add(InstructorBackfillRow(
            instructorId: id,
            instructorName: name,
            outcome: InstructorBackfillOutcome.ambiguous,
            notes:
                'Name "$nameTrim" matched ${q2.docs.length} users — resolve manually.',
          ));
          continue;
        }
      }

      if (targetUid == null) {
        rows.add(InstructorBackfillRow(
          instructorId: id,
          instructorName: name,
          outcome: InstructorBackfillOutcome.noMatch,
          notes:
              'Could not resolve a target uid. Set email or displayName, then re-run.',
        ));
        continue;
      }

      // Already at the target uid? Skip the copy step.
      if (targetUid == id) {
        rows.add(InstructorBackfillRow(
          instructorId: id,
          instructorName: name,
          outcome: InstructorBackfillOutcome.alreadyLinked,
          linkedUserId: id,
          notes: 'Doc already at the canonical key.',
        ));
        continue;
      }

      try {
        // Strip the legacy `userId` field — it's redundant under the
        // new schema (id IS the uid).
        final cleanedPayload = Map<String, dynamic>.from(data)
          ..remove('userId');
        await _col.doc(targetUid).set(
              cleanedPayload,
              SetOptions(merge: true),
            );
        await _col.doc(id).delete();
        rows.add(InstructorBackfillRow(
          instructorId: targetUid,
          instructorName: name,
          outcome: InstructorBackfillOutcome.matchedByEmail,
          linkedUserId: targetUid,
          notes: matchNote,
        ));
      } catch (e) {
        rows.add(InstructorBackfillRow(
          instructorId: id,
          instructorName: name,
          outcome: InstructorBackfillOutcome.errored,
          notes: 'Failed to copy/delete: $e',
        ));
      }
    }

    return InstructorBackfillReport(scanned: snap.docs.length, rows: rows);
  }

  // ----- Helpers -----------------------------------------------------

  /// Hand-rolled serialiser — we drop the `id` field (it's the doc id),
  /// and stamp `joinedAt` as a server Timestamp on create.
  Map<String, dynamic> _toPayload(
    InstructorModel m, {
    DateTime? joinedAt,
  }) {
    return {
      if (m.email != null && m.email!.isNotEmpty) ...{
        'email': m.email,
        'emailLower': m.email!.trim().toLowerCase(),
      },
      'name': m.name,
      'photoUrl': m.photoUrl,
      'bio': m.bio,
      if (m.tagline != null) 'tagline': m.tagline,
      if (m.primaryInstrument != null)
        'primaryInstrument': m.primaryInstrument,
      'specialties': m.specialties,
      if (m.yearsExperience != null) 'yearsExperience': m.yearsExperience,
      if (m.country != null) 'country': m.country,
      'rating': m.rating,
      'reviewCount': m.reviewCount,
      'studentCount': m.studentCount,
      'featuredCourseIds': m.featuredCourseIds,
      if (m.websiteUrl != null) 'websiteUrl': m.websiteUrl,
      if (m.facebookUrl != null) 'facebookUrl': m.facebookUrl,
      if (m.twitterUrl != null) 'twitterUrl': m.twitterUrl,
      if (m.youtubeUrl != null) 'youtubeUrl': m.youtubeUrl,
      if (m.instagramUrl != null) 'instagramUrl': m.instagramUrl,
      if (joinedAt != null) 'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}
