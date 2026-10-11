import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_view_model.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';

import '../support/fakes.dart';

/// Firestore stand-in that records every write. With [oldRules] it rejects
/// any create that holds a field outside the four core ones.
class _RecordingFirestore extends FirestoreService {
  _RecordingFirestore({this.oldRules = false, this.failWith});

  final bool oldRules;
  final AuthFailure? failWith;
  final writes = <Map<String, Object?>>[];

  @override
  Object serverTimestamp() => 'now';

  @override
  Future<void> setDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async {
    if (failWith != null) throw AuthException(failWith!);
    if (oldRules &&
        !{'role', 'fullName', 'email', 'createdAt'}.containsAll(data.keys)) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    writes.add(data);
  }
}

void main() {
  group('UserRepository.createProfile', () {
    Future<void> create(UserRepository repo) => repo.createProfile(
      uid: 'u1',
      role: AccountRole.investor,
      fullName: 'Sara Alswailem',
      email: 'sara@example.com',
      phone: '512345678',
      city: 'Riyadh',
      bio: 'Backing early teams.',
      sectorsOfInterest: const ['Fintech', 'SportsTech'],
    );

    test('stores phone, city, bio and sectors with the core fields', () async {
      final firestore = _RecordingFirestore();
      await create(UserRepository(firestore: firestore));

      expect(firestore.writes, hasLength(1));
      expect(firestore.writes.single, {
        UserFields.role: 'investor',
        UserFields.fullName: 'Sara Alswailem',
        UserFields.email: 'sara@example.com',
        UserFields.createdAt: 'now',
        UserFields.phone: '512345678',
        UserFields.city: 'Riyadh',
        UserFields.bio: 'Backing early teams.',
        UserFields.sectorsOfInterest: ['Fintech', 'SportsTech'],
      });
    });

    test('an empty bio is not stored', () async {
      final firestore = _RecordingFirestore();
      await UserRepository(firestore: firestore).createProfile(
        uid: 'u1',
        role: AccountRole.founder,
        fullName: 'Sara Alswailem',
        email: 'sara@example.com',
        phone: '512345678',
        bio: '  ',
      );

      expect(firestore.writes.single.containsKey(UserFields.bio), isFalse);
    });

    test('falls back to the four core fields when the rules are old', () async {
      final firestore = _RecordingFirestore(oldRules: true);
      await create(UserRepository(firestore: firestore));

      expect(firestore.writes, hasLength(1));
      expect(firestore.writes.single.keys.toSet(), {
        UserFields.role,
        UserFields.fullName,
        UserFields.email,
        UserFields.createdAt,
      });
    });

    test('other failures are not retried', () async {
      final firestore = _RecordingFirestore(failWith: AuthFailure.network);

      await expectLater(
        create(UserRepository(firestore: firestore)),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.network,
          ),
        ),
      );
      expect(firestore.writes, isEmpty);
    });
  });

  group('AuthRepository.signUp saves the profile', () {
    late FakeAuthService auth;
    late FakeUserRepository users;
    late AuthRepository repo;

    setUp(() {
      auth = FakeAuthService();
      users = FakeUserRepository();
      repo = AuthRepository(authService: auth, userRepository: users);
    });

    Future<SignupResult> signUp({File? photo}) => repo.signUp(
      fullName: 'Mohammed Ahmed',
      email: 'a@b.co',
      password: 'Startup1!',
      role: AccountRole.founder,
      phone: '512345678',
      city: 'Jeddah',
      bio: 'Hello',
      sectorsOfInterest: const ['HealthTech', 'SportsTech'],
      photo: photo,
    );

    test('phone, city, bio and sectors reach the profile', () async {
      await signUp();

      final profile = users.profiles['uid1']!;
      expect(profile.phone, '512345678');
      expect(profile.city, 'Jeddah');
      expect(profile.bio, 'Hello');
      expect(profile.sectorsOfInterest, ['HealthTech', 'SportsTech']);
      expect(users.photoUploads, isEmpty); // the photo is optional
    });

    test('uploads the chosen photo while still signed in', () async {
      await signUp(photo: File('photo.jpg'));

      expect(users.photoUploads, ['uid1']);
      expect(users.profiles['uid1']?.photoUrl, isNotNull);
      // Uploaded before the session was closed.
      expect(auth.calls.last, 'signOut');
    });

    test('a failed photo upload does not fail the sign-up', () async {
      users.photoFails = AuthFailure.network;

      final result = await signUp(photo: File('photo.jpg'));

      expect(result.verificationEmailSent, isTrue);
      expect(users.profiles['uid1'], isNotNull);
      expect(auth.calls, ['createAccount', 'sendVerification', 'signOut']);
    });
  });

  group('SignupViewModel', () {
    test('passes bio, sectors (with Other) and the photo on', () async {
      final repo = FakeAuthRepository();
      final vm = SignupViewModel(authRepository: repo);
      final photo = File('photo.jpg');

      final result = await vm.submit(
        fullName: ' Mohammed Ahmed ',
        email: 'a@b.co',
        phone: '512345678',
        password: 'Startup1!',
        confirmPassword: 'Startup1!',
        city: 'Riyadh',
        sectors: const ['Fintech', 'SportsTech'],
        role: AccountRole.investor,
        bio: ' Angel investor ',
        photo: photo,
      );

      expect(result, isNotNull);
      expect(repo.lastSignUp, {
        'phone': '512345678',
        'city': 'Riyadh',
        'bio': 'Angel investor',
        'sectors': 'Fintech,SportsTech',
      });
      expect(repo.lastSignUpPhoto, photo);
    });

    test('works without a photo or a bio', () async {
      final repo = FakeAuthRepository();
      final vm = SignupViewModel(authRepository: repo);

      final result = await vm.submit(
        fullName: 'Mohammed Ahmed',
        email: 'a@b.co',
        phone: '512345678',
        password: 'Startup1!',
        confirmPassword: 'Startup1!',
        city: 'Riyadh',
        sectors: const ['Fintech'],
        role: AccountRole.founder,
      );

      expect(result, isNotNull);
      expect(repo.lastSignUpPhoto, isNull);
      expect(repo.lastSignUp?['bio'], '');
    });
  });
}
