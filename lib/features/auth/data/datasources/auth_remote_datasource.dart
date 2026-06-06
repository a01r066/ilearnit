import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Stream<User?> authStateChanges();
  User? get currentFirebaseUser;

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> signup({
    required String email,
    required String password,
    required String displayName,
  });

  /// See [AuthRepository.signInWithGoogle].
  Future<UserModel> signInWithGoogle();

  /// See [AuthRepository.signInWithApple]. iOS only.
  Future<UserModel> signInWithApple();

  Future<void> logout();
  Future<void> sendPasswordReset({required String email});

  Future<UserModel?> fetchUserDoc(String uid);

  /// Re-auth the current user with their password. Throws [AuthException]
  /// on `wrong-password`, `too-many-requests`, etc.
  Future<void> reauthenticateWithPassword({required String password});

  /// Re-auth the current user by re-running Google sign-in and feeding
  /// the credential through `reauthenticateWithCredential`.
  Future<void> reauthenticateWithGoogle();

  /// Re-auth the current user by re-running Apple sign-in.
  Future<void> reauthenticateWithApple();

  /// Invoke the `deleteAccount` callable Cloud Function. Throws on
  /// `requires-recent-login` so the UI can route the user back through
  /// re-auth.
  Future<void> deleteAccount();

  /// Partial Firestore update for the current user. See
  /// [AuthRepository.updateProfile].
  Future<void> updateProfile({
    String? primaryInstrument,
    String? skillLevel,
    String? displayName,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
    FirebaseFunctions? functions,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentFirebaseUser => _auth.currentUser;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw AuthException(message: 'Login returned no user.');
    }
    final doc = await fetchUserDoc(user.uid);
    return doc ?? UserModel.fromFirebase(user);
  }

  @override
  Future<UserModel> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw AuthException(message: 'Signup returned no user.');
    }
    await user.updateDisplayName(displayName);

    final model = UserModel(
      id: user.uid,
      email: user.email ?? email,
      displayName: displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      createdAt: DateTime.now(),
    );
    await _users.doc(user.uid).set(model.toJson());
    return model;
  }

  // ---------- Google -------------------------------------------------------

  @override
  Future<UserModel> signInWithGoogle() async {
    // On web, the `google_sign_in` plugin requires extra setup (Google
    // Identity Services + Web Client ID meta tag). It's simpler — and
    // future-proof against Google's UI deprecations — to delegate to
    // Firebase's own `signInWithPopup` on web.
    if (kIsWeb) {
      return _signInWithGoogleWeb();
    }
    return _signInWithGoogleNative();
  }

  Future<UserModel> _signInWithGoogleNative() async {
    final GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } catch (e) {
      throw AuthException(
        message: 'Google sign-in failed.',
        code: e.toString().contains('canceled') ||
                e.toString().contains('cancelled')
            ? AuthCancellation.code
            : null,
      );
    }
    if (account == null) {
      // User dismissed the picker.
      throw AuthException(
        message: 'Sign-in cancelled.',
        code: AuthCancellation.code,
      );
    }

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw AuthException(message: 'Google sign-in returned no user.');
    }
    return _upsertSocialUser(user);
  }

  Future<UserModel> _signInWithGoogleWeb() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');
    try {
      final result = await _auth.signInWithPopup(provider);
      final user = result.user;
      if (user == null) {
        throw AuthException(message: 'Google sign-in returned no user.');
      }
      return _upsertSocialUser(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'user-cancelled') {
        throw AuthException(
          message: 'Sign-in cancelled.',
          code: AuthCancellation.code,
        );
      }
      throw AuthException(
        message: e.message ?? 'Google sign-in failed.',
        code: e.code,
      );
    }
  }

  // ---------- Apple --------------------------------------------------------

  @override
  Future<UserModel> signInWithApple() async {
    if (kIsWeb) {
      return _signInWithAppleWeb();
    }
    // Native: iOS + macOS only (Android falls through to the web flow if you
    // ever wire that up — see `docs/social_auth_setup.md`).
    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.iOS &&
        platform != TargetPlatform.macOS) {
      throw AuthException(
        message: 'Sign in with Apple is only available on Apple devices.',
        code: 'unsupported-platform',
      );
    }
    return _signInWithAppleNative();
  }

  Future<UserModel> _signInWithAppleNative() async {
    // Apple requires a one-shot nonce; we send the SHA-256 hash up and pass
    // the raw nonce back to Firebase so the two can be cross-checked.
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final AuthorizationCredentialAppleID appleCredential;
    try {
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException(
          message: 'Sign-in cancelled.',
          code: AuthCancellation.code,
        );
      }
      throw AuthException(message: e.message, code: e.code.name);
    }

    final oauth = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final result = await _auth.signInWithCredential(oauth);
    final user = result.user;
    if (user == null) {
      throw AuthException(message: 'Apple sign-in returned no user.');
    }

    // Apple only returns the display name on the *first* authorization. If we
    // have one and Firebase doesn't, persist it back.
    final composedName = [
      appleCredential.givenName,
      appleCredential.familyName,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim();
    if (composedName.isNotEmpty &&
        (user.displayName == null || user.displayName!.isEmpty)) {
      await user.updateDisplayName(composedName);
    }

    return _upsertSocialUser(user);
  }

  /// Web flow — Apple-on-web uses Firebase's `signInWithPopup` with the
  /// `apple.com` OAuth provider. Requires a Service ID + return URL
  /// configured in Apple Developer Console (see
  /// `docs/social_auth_setup.md`).
  Future<UserModel> _signInWithAppleWeb() async {
    final provider = OAuthProvider('apple.com')
      ..addScope('email')
      ..addScope('name');
    try {
      final result = await _auth.signInWithPopup(provider);
      final user = result.user;
      if (user == null) {
        throw AuthException(message: 'Apple sign-in returned no user.');
      }
      return _upsertSocialUser(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'user-cancelled') {
        throw AuthException(
          message: 'Sign-in cancelled.',
          code: AuthCancellation.code,
        );
      }
      throw AuthException(
        message: e.message ?? 'Apple sign-in failed.',
        code: e.code,
      );
    }
  }

  // ---------- Shared helpers -----------------------------------------------

  /// Create or refresh the Firestore `users/{uid}` doc after a social
  /// sign-in. Existing docs are preserved (we only fill in missing fields).
  Future<UserModel> _upsertSocialUser(User user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();

    if (snap.exists) {
      // Refresh photo/displayName if the social provider gives us better data
      // than what we previously stored.
      final existing = UserModel.fromDoc(snap);
      final merged = existing.copyWith(
        displayName: existing.displayName ?? user.displayName,
        photoUrl: existing.photoUrl ?? user.photoURL,
        emailVerified: user.emailVerified,
      );
      if (merged != existing) {
        await ref.set(merged.toJson(), SetOptions(merge: true));
      }
      return merged;
    }

    final model = UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      createdAt: DateTime.now(),
    );
    await ref.set(model.toJson());
    return model;
  }

  @override
  Future<void> logout() async {
    // Sign out of providers too, so a subsequent tap reopens the picker.
    // On web we only sign out of Firebase — the popup flow doesn't hold
    // any plugin-level session.
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut().catchError((Object _) => null);
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<UserModel?> fetchUserDoc(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromDoc(snap);
  }

  // ---------- Nonce helpers (Apple) ----------------------------------------

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  // ---------- Re-auth + delete --------------------------------------------

  /// Returns the currently signed-in Firebase user or throws an
  /// [AuthException] if none is present. Centralises the null-check so the
  /// re-auth and delete flows can read concisely.
  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException(
        message: 'You are not signed in.',
        code: 'no-current-user',
      );
    }
    return user;
  }

  @override
  Future<void> reauthenticateWithPassword({required String password}) async {
    final user = _requireUser();
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw AuthException(
        message: 'Your account has no email — try Google or Apple re-auth.',
        code: 'no-email',
      );
    }
    try {
      final cred = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Re-authentication failed.',
        code: e.code,
      );
    }
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    final user = _requireUser();

    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      await user.reauthenticateWithPopup(provider);
      return;
    }

    // Run the native picker but feed the resulting credential through
    // reauthenticateWithCredential rather than signInWithCredential. This
    // preserves the existing uid; signing in would replace it.
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      throw AuthException(
        message: 'Re-authentication cancelled.',
        code: AuthCancellation.code,
      );
    }
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  @override
  Future<void> reauthenticateWithApple() async {
    final user = _requireUser();

    if (kIsWeb) {
      final provider = OAuthProvider('apple.com')
        ..addScope('email')
        ..addScope('name');
      await user.reauthenticateWithPopup(provider);
      return;
    }

    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.iOS && platform != TargetPlatform.macOS) {
      throw AuthException(
        message: 'Sign in with Apple is only available on Apple devices.',
        code: 'unsupported-platform',
      );
    }

    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);
    final AuthorizationCredentialAppleID appleCredential;
    try {
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException(
          message: 'Re-authentication cancelled.',
          code: AuthCancellation.code,
        );
      }
      throw AuthException(message: e.message, code: e.code.name);
    }

    final oauth = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
    await user.reauthenticateWithCredential(oauth);
  }

  @override
  Future<void> deleteAccount() async {
    _requireUser();
    try {
      final callable = _functions.httpsCallable('deleteAccount');
      await callable.call<Map<String, dynamic>>();
    } on FirebaseFunctionsException catch (e) {
      // `unauthenticated` should never bubble up — we just confirmed the
      // user exists above — but treat it explicitly anyway.
      throw AuthException(
        message: e.message ?? 'Account deletion failed.',
        code: e.code,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Account deletion failed.',
        code: e.code,
      );
    }

    // The server already deleted the auth user, but the client SDK still
    // holds a stale token. Force a local sign-out so subsequent navigation
    // sees `currentUser == null`.
    await _auth.signOut().catchError((Object _) => null);
  }

  @override
  Future<void> updateProfile({
    String? primaryInstrument,
    String? skillLevel,
    String? displayName,
  }) async {
    final user = _requireUser();
    final payload = <String, dynamic>{};
    if (primaryInstrument != null) {
      payload['primaryInstrument'] = primaryInstrument;
    }
    if (skillLevel != null) payload['skillLevel'] = skillLevel;
    if (displayName != null) payload['displayName'] = displayName;
    if (payload.isEmpty) return;

    // Merge so we don't have to read-then-write the rest of the doc.
    await _users.doc(user.uid).set(payload, SetOptions(merge: true));

    // Mirror displayName onto the Firebase Auth record so getDisplayName()
    // calls elsewhere see the updated value without a Firestore read.
    if (displayName != null && displayName != user.displayName) {
      try {
        await user.updateDisplayName(displayName);
      } catch (_) {
        // Auth update is best-effort; the Firestore doc is the source of
        // truth for everything that matters in our UI.
      }
    }
  }
}
