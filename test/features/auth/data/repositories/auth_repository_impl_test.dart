// Unit tests for `AuthRepositoryImpl`.
//
// Coverage focuses on the four scenarios most likely to bite us in
// production:
//
//   1. Success           — datasource returns a model, repo maps to entity.
//   2. Network error     — NetworkInfo says offline, repo short-circuits
//                          to `Failure.network` BEFORE touching the
//                          datasource.
//   3. Parsing error     — datasource throws a `FormatException`-style
//                          error; `mapToFailure` funnels it into
//                          `Failure.unexpected`.
//   4. Empty response    — datasource throws an `AuthException` carrying
//                          "no user" semantics; surfaces as
//                          `Failure.auth`.
//
// We don't reach Firebase. The repo's `_persistToken` helper reads
// `_remote.currentFirebaseUser` — we stub it to `null` so the helper
// no-ops, sidestepping the need to mock `firebase_auth.User`.

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ilearnit/core/error/exceptions.dart';
import 'package:ilearnit/core/error/failure.dart';
import 'package:ilearnit/core/network/network_info.dart';
import 'package:ilearnit/core/storage/secure_storage_service.dart';
import 'package:ilearnit/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ilearnit/features/auth/data/models/user_model.dart';
import 'package:ilearnit/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ilearnit/features/auth/domain/entities/user_entity.dart';

// ---------- Mocks -----------------------------------------------------------

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockNetwork extends Mock implements NetworkInfo {}

class _MockStorage extends Mock implements SecureStorageService {}

// ---------- Helpers ---------------------------------------------------------

const _email = 'alice@example.com';
const _password = 'hunter2-correct-horse';
const _displayName = 'Alice';

/// A representative `UserModel` returned by the remote datasource on
/// success. Hand-built so the tests don't depend on the
/// generated-fromJson code path.
final _aliceModel = UserModel(
  id: 'uid_alice',
  email: _email,
  displayName: _displayName,
  emailVerified: true,
);

void main() {
  late _MockRemote remote;
  late _MockNetwork network;
  late _MockStorage storage;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    network = _MockNetwork();
    storage = _MockStorage();
    repo = AuthRepositoryImpl(
      remote: remote,
      network: network,
      storage: storage,
    );

    // Default stubs reused across most tests. Individual tests
    // override these when they want specific behaviour.
    when(() => network.isConnected).thenAnswer((_) async => true);
    // No firebase user → `_persistToken` skips the keychain write,
    // so we don't need to mock `User.getIdToken()`.
    when(() => remote.currentFirebaseUser).thenReturn(null);
    when(() => storage.writeAccessToken(any())).thenAnswer((_) async {});
  });

  // -----------------------------------------------------------------------
  // login()
  // -----------------------------------------------------------------------
  group('login()', () {
    test('returns Right(UserEntity) on success', () async {
      when(() => remote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => _aliceModel);

      final result = await repo.login(email: _email, password: _password);

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right but got Left($l)'),
        (entity) {
          expect(entity, isA<UserEntity>());
          expect(entity.id, 'uid_alice');
          expect(entity.email, _email);
          expect(entity.displayName, _displayName);
          expect(entity.emailVerified, isTrue);
        },
      );
      verify(() => network.isConnected).called(1);
      verify(() => remote.login(email: _email, password: _password)).called(1);
    });

    test(
        'returns Left(NetworkFailure) and skips datasource when offline',
        () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repo.login(email: _email, password: _password);

      // Fold-based assertion instead of `equals(Left(...))` —
      // `dartz`'s `Either` doesn't always override `==`, so direct
      // equality on `Left(...)` can spuriously fail.
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.displayMessage, 'No internet connection.');
        },
        (_) => fail('expected Left(NetworkFailure)'),
      );
      // Critical: the network gate is BEFORE the datasource call.
      // Verifying `verifyNever` catches a regression where someone
      // moves the gate after the call (would still work in dev with
      // an emulator, but would silently fail on a real flight-mode
      // device).
      verifyNever(() => remote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
      verifyNever(() => storage.writeAccessToken(any()));
    });

    test(
        'returns Left(UnexpectedFailure) when the datasource throws on parse',
        () async {
      final parseError = const FormatException(
        'Unexpected end of input — Firestore returned empty bytes',
      );
      when(() => remote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(parseError);

      final result = await repo.login(email: _email, password: _password);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          // `mapToFailure` doesn't have a special case for
          // FormatException, so it falls through to the unexpected
          // bucket — by design.
          expect(failure, isA<UnexpectedFailure>());
          expect(
            failure.displayMessage,
            contains('Unexpected end of input'),
          );
        },
        (_) => fail('expected Left(UnexpectedFailure)'),
      );
      verifyNever(() => storage.writeAccessToken(any()));
    });

    test(
        'returns Left(AuthFailure) when the datasource signals an empty '
        'auth response', () async {
      // The repository's `login` path expects `_remote.login` to
      // throw `AuthException('Login returned no user.')` when
      // Firebase Auth returns a credential without a `User` — see
      // `auth_remote_datasource.dart`.
      final emptyResponse = AuthException(message: 'Login returned no user.');
      when(() => remote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(emptyResponse);

      final result = await repo.login(email: _email, password: _password);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.displayMessage, 'Login returned no user.');
        },
        (_) => fail('expected Left(AuthFailure)'),
      );
    });
  });

  // -----------------------------------------------------------------------
  // signup()  — same four scenarios, smaller assertions.
  // -----------------------------------------------------------------------
  group('signup()', () {
    test('returns Right(UserEntity) on success', () async {
      when(() => remote.signup(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenAnswer((_) async => _aliceModel);

      final result = await repo.signup(
        email: _email,
        password: _password,
        displayName: _displayName,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right but got Left($l)'),
        (entity) => expect(entity.id, 'uid_alice'),
      );
    });

    test('returns Left(NetworkFailure) when offline', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repo.signup(
        email: _email,
        password: _password,
        displayName: _displayName,
      );

      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('expected Left(NetworkFailure)'),
      );
      verifyNever(() => remote.signup(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ));
    });

    test('returns Left(UnexpectedFailure) on parse error', () async {
      when(() => remote.signup(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenThrow(const FormatException('bad JSON payload'));

      final result = await repo.signup(
        email: _email,
        password: _password,
        displayName: _displayName,
      );

      result.fold(
        (failure) {
          expect(failure, isA<UnexpectedFailure>());
          expect(failure.displayMessage, contains('bad JSON payload'));
        },
        (_) => fail('expected Left(UnexpectedFailure)'),
      );
    });

    test('returns Left(AuthFailure) on empty response from server', () async {
      when(() => remote.signup(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenThrow(
        AuthException(message: 'Signup returned no user.'),
      );

      final result = await repo.signup(
        email: _email,
        password: _password,
        displayName: _displayName,
      );

      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.displayMessage, 'Signup returned no user.');
        },
        (_) => fail('expected Left(AuthFailure)'),
      );
    });
  });

  // -----------------------------------------------------------------------
  // currentUser()  — the "empty response" case is the load-bearing one.
  // -----------------------------------------------------------------------
  group('currentUser()', () {
    test('returns UserEntity from the Firestore user doc on success',
        () async {
      final fakeUser = _StubFirebaseUser('uid_alice');
      when(() => remote.currentFirebaseUser).thenReturn(fakeUser);
      when(() => remote.fetchUserDoc('uid_alice'))
          .thenAnswer((_) async => _aliceModel);

      final entity = await repo.currentUser();

      expect(entity, isNotNull);
      expect(entity!.id, 'uid_alice');
      expect(entity.email, _email);
    });

    test('returns null when no Firebase user is signed in', () async {
      when(() => remote.currentFirebaseUser).thenReturn(null);

      final entity = await repo.currentUser();

      expect(entity, isNull);
      // `fetchUserDoc` MUST NOT be called — that would be an extra
      // Firestore read for every cold-launch guest browse.
      verifyNever(() => remote.fetchUserDoc(any()));
    });

    test(
        'returns null when a Firebase user exists but the doc fetch '
        'returns null (empty response)', () async {
      final fakeUser = _StubFirebaseUser('uid_orphan');
      when(() => remote.currentFirebaseUser).thenReturn(fakeUser);
      when(() => remote.fetchUserDoc('uid_orphan'))
          .thenAnswer((_) async => null);

      final entity = await repo.currentUser();

      // Per `AuthRepositoryImpl.currentUser`, a missing Firestore
      // doc resolves to null rather than synthesising an entity
      // from the bare Firebase user. Keeps callers from rendering
      // an authenticated UI for a user whose Firestore-side state
      // (role, etc.) hasn't been written yet.
      expect(entity, isNull);
    });
  });
}

// ---------- Minimal `User` stub --------------------------------------------
//
// `firebase_auth.User` is a concrete class with many getters. We only
// need `uid` for these tests; the rest is unused. A subclass over
// `Mock` keeps mocktail's stub plumbing intact without forcing every
// call site to register fallback values.

class _StubFirebaseUser extends Mock implements User {
  _StubFirebaseUser(this._uid);
  final String _uid;

  @override
  String get uid => _uid;
}
