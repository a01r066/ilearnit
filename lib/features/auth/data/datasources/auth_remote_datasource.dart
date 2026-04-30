import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
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

  Future<void> logout();
  Future<void> sendPasswordReset({required String email});

  Future<UserModel?> fetchUserDoc(String uid);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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

  @override
  Future<void> logout() => _auth.signOut();

  @override
  Future<void> sendPasswordReset({required String email}) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<UserModel?> fetchUserDoc(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromDoc(snap);
  }
}
