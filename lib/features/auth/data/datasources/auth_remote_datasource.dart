import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
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
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

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
}
