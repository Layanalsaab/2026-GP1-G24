import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startsa/data_access/firebase_services/auth_service.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/for_you_cache.dart';
import 'package:startsa/data_access/repositories/not_interested_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';

import '../support/fakes.dart';

/// Firestore kept in a map (collection path -> document id -> data); reads
/// of the collections in [failing] throw.
class _MemoryFirestore extends FirestoreService {
  final Map<String, Map<String, Map<String, Object?>>> store = {};
  final Set<String> failing = {};

  @override
  Future<void> deleteDocument(String collection, String id) async {
    store[collection]?.remove(id);
  }

  @override
  Future<List<FirestoreDocument>> listCollection(
    String collection, {
    int limit = 100,
  }) async {
    if (failing.contains(collection)) throw StateError('offline');
    return [
      for (final e in (store[collection] ?? {}).entries)
        (id: e.key, data: Map<String, dynamic>.from(e.value)),
    ];
  }
}

void main() {
  late FakeAuthService auth;
  late FakeUserRepository users;
  late AuthRepository repo;
  late FakeStartupRepository startups;

  setUp(() {
    auth = FakeAuthService();
    users = FakeUserRepository();
    startups = FakeStartupRepository();
    StartupRepository.instance = startups;
    repo = AuthRepository(authService: auth, userRepository: users);
  });

  Future<AuthFailure> failureOf(Future<Object?> Function() action) async {
    try {
      await action();
    } on AuthException catch (e) {
      return e.failure;
    }
    fail('expected an AuthException');
  }

  AuthAccount verified() =>
      const AuthAccount(uid: 'uid1', email: 'a@b.co', emailVerified: true);

  group('signUp', () {
    Future<SignupResult> signUp() => repo.signUp(
      fullName: 'Mohammed Ahmed',
      email: 'a@b.co',
      password: 'Startup1',
      role: AccountRole.investor,
    );

    test(
      'creates the account and profile, sends verification, signs out',
      () async {
        final result = await signUp();

        expect(result.verificationEmailSent, isTrue);
        expect(users.profiles['uid1']?.role, AccountRole.investor);
        expect(users.profiles['uid1']?.fullName, 'Mohammed Ahmed');
        expect(auth.calls, ['createAccount', 'sendVerification', 'signOut']);
        expect(auth.signedIn, isNull);
      },
    );

    test('deletes the Auth account when the profile cannot be saved', () async {
      users.createFails = true;

      expect(await failureOf(signUp), AuthFailure.profileSaveFailed);
      expect(auth.calls, ['createAccount', 'delete']);
      expect(auth.signedIn, isNull);
      expect(users.profiles, isEmpty);
    });

    test('signs out even if deleting the Auth account fails', () async {
      users.createFails = true;
      auth.deleteFails = true;

      expect(await failureOf(signUp), AuthFailure.profileSaveFailed);
      expect(auth.calls, ['createAccount', 'delete', 'signOut']);
      expect(auth.signedIn, isNull);
    });

    test('reports an already-registered email and writes nothing', () async {
      auth.createFails = AuthFailure.emailInUse;

      expect(await failureOf(signUp), AuthFailure.emailInUse);
      expect(users.profiles, isEmpty);
    });

    test(
      'still succeeds if only the verification email fails to send',
      () async {
        auth.sendVerificationFails = AuthFailure.unknown;

        final result = await signUp();

        expect(result.verificationEmailSent, isFalse);
        expect(users.profiles['uid1'], isNotNull);
        expect(auth.signedIn, isNull);
      },
    );
  });

  group('logIn', () {
    setUp(() {
      users.profiles['uid1'] = const AppUser(
        uid: 'uid1',
        role: AccountRole.founder,
        fullName: 'Mohammed Ahmed',
        email: 'a@b.co',
      );
    });

    test('returns the profile for a verified user', () async {
      auth.account = verified();

      final user = await repo.logIn('a@b.co', 'Startup1');

      expect(user.role, AccountRole.founder);
      expect(auth.signedIn, isNotNull);
    });

    test('every wrong-credentials case becomes the same failure', () async {
      for (final code in [
        AuthFailure.invalidCredentials,
        AuthFailure.invalidEmail,
      ]) {
        auth.signInFails = code;
        expect(
          await failureOf(() => repo.logIn('a@b.co', 'x')),
          AuthFailure.invalidCredentials,
          reason: '$code',
        );
      }
    });

    test('blocks unverified users and signs them out', () async {
      auth.account = const AuthAccount(
        uid: 'uid1',
        email: 'a@b.co',
        emailVerified: false,
      );

      expect(
        await failureOf(() => repo.logIn('a@b.co', 'Startup1')),
        AuthFailure.emailNotVerified,
      );
      expect(auth.signedIn, isNull);
    });

    test('signs out when the profile is missing', () async {
      auth.account = verified();
      users.profiles.clear();

      expect(
        await failureOf(() => repo.logIn('a@b.co', 'Startup1')),
        AuthFailure.profileMissing,
      );
      expect(auth.signedIn, isNull);
    });

    test('signs out when the profile cannot be read', () async {
      auth.account = verified();
      users.getFails = AuthFailure.network;

      expect(
        await failureOf(() => repo.logIn('a@b.co', 'Startup1')),
        AuthFailure.network,
      );
      expect(auth.signedIn, isNull);
    });
  });

  group('resendVerification', () {
    test('sends the email and always signs out again', () async {
      auth.account = const AuthAccount(
        uid: 'uid1',
        email: 'a@b.co',
        emailVerified: false,
      );

      expect(
        await repo.resendVerification('a@b.co', 'Startup1'),
        ResendResult.sent,
      );
      expect(auth.calls, ['signIn', 'sendVerification', 'signOut']);
      expect(auth.signedIn, isNull);
    });

    test('does not send when already verified', () async {
      auth.account = verified();

      expect(
        await repo.resendVerification('a@b.co', 'Startup1'),
        ResendResult.alreadyVerified,
      );
      expect(auth.calls, ['signIn', 'signOut']);
    });

    test('signs out even when sending fails', () async {
      auth.sendVerificationFails = AuthFailure.tooManyRequests;

      expect(
        await failureOf(() => repo.resendVerification('a@b.co', 'Startup1')),
        AuthFailure.tooManyRequests,
      );
      expect(auth.signedIn, isNull);
    });
  });

  group('sendPasswordReset', () {
    test('does not reveal unregistered emails', () async {
      auth.resetFails =
          AuthFailure.invalidCredentials; // Firebase: "user not found"
      await repo.sendPasswordReset('nobody@example.com'); // must not throw
    });

    test('sends the reset email for a registered address', () async {
      await repo.sendPasswordReset('a@b.co');

      expect(auth.calls, ['sendReset']);
    });

    test('still reports network and rate-limit problems', () async {
      auth.resetFails = AuthFailure.network;
      expect(
        await failureOf(() => repo.sendPasswordReset('a@b.co')),
        AuthFailure.network,
      );

      auth.resetFails = AuthFailure.tooManyRequests;
      expect(
        await failureOf(() => repo.sendPasswordReset('a@b.co')),
        AuthFailure.tooManyRequests,
      );
    });
  });

  group('restoreSession', () {
    const profile = AppUser(
      uid: 'uid1',
      role: AccountRole.investor,
      fullName: 'Sara',
      email: 'a@b.co',
    );

    test('is null when nobody is signed in', () async {
      expect(await repo.restoreSession(), isNull);
    });

    test('returns the user when verified and has a profile', () async {
      auth.signedIn = verified();
      users.profiles['uid1'] = profile;

      expect((await repo.restoreSession())?.role, AccountRole.investor);
    });

    test('signs out an unverified user', () async {
      auth.signedIn = const AuthAccount(
        uid: 'uid1',
        email: 'a@b.co',
        emailVerified: false,
      );
      users.profiles['uid1'] = profile;

      expect(await repo.restoreSession(), isNull);
      expect(auth.signedIn, isNull);
    });

    test('signs out a verified user who has no profile', () async {
      auth.signedIn = verified();

      expect(await repo.restoreSession(), isNull);
      expect(auth.signedIn, isNull);
    });

    test('keeps the session when offline, but does not open it', () async {
      auth.signedIn = verified();
      auth.reloadFails = AuthFailure.network;

      expect(await repo.restoreSession(), isNull);
      expect(auth.signedIn, isNotNull);
    });
  });

  group('deleteAccount', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    /// Bookmarks s-a and Not interested s-b, saved and loaded for uid1.
    Future<(_MemoryFirestore, BookmarkRepository, NotInterestedRepository)>
    savedLists() async {
      final db = _MemoryFirestore()
        ..store['users/uid1/bookmarks'] = {'s-a': {}}
        ..store['users/uid1/notInterested'] = {'s-b': {}};
      final marks = BookmarkRepository(firestore: db);
      final hidden = NotInterestedRepository(firestore: db);
      await marks.load('uid1');
      await hidden.load('uid1');
      final oldMarks = BookmarkRepository.instance;
      final oldHidden = NotInterestedRepository.instance;
      BookmarkRepository.instance = marks;
      NotInterestedRepository.instance = hidden;
      addTearDown(() {
        BookmarkRepository.instance = oldMarks;
        NotInterestedRepository.instance = oldHidden;
      });
      return (db, marks, hidden);
    }

    test('a failed bookmark cleanup still deletes Not interested; both are '
        'forgotten', () async {
      final (db, marks, hidden) = await savedLists();
      expect(marks.keys.value, {'s-a'});
      expect(hidden.keys.value, {'s-b'});
      db.failing.add('users/uid1/bookmarks');
      auth.signedIn = verified();
      await repo.deleteAccount();
      expect(db.store['users/uid1/notInterested'], isEmpty);
      expect(marks.keys.value, isEmpty);
      expect(hidden.keys.value, isEmpty);
      expect(auth.calls, contains('delete'));
    });

    test('a failed Not interested cleanup is still forgotten', () async {
      final (db, marks, hidden) = await savedLists();
      db.failing.add('users/uid1/notInterested');
      auth.signedIn = verified();
      await repo.deleteAccount();
      expect(db.store['users/uid1/bookmarks'], isEmpty);
      expect(marks.keys.value, isEmpty);
      expect(hidden.keys.value, isEmpty);
      expect(auth.calls, contains('delete'));
    });

    test('the saved For You list is removed from the phone', () async {
      SharedPreferences.setMockInitialValues({
        'forYou.lastList.uid1': ['s-a'],
        'forYou.lastList.u2': ['s-b'],
      });
      auth.signedIn = verified();
      await repo.deleteAccount();
      expect(await ForYouCache().read('uid1'), isEmpty);
      expect(await ForYouCache().read('u2'), ['s-b']);
    });

    test('a fresh sign-in deletes without asking for the password', () async {
      auth.signedIn = verified();
      await repo.deleteAccount();
      expect(auth.calls, isNot(contains('reauth')));
      expect(auth.calls, contains('delete'));
      expect(users.deletedProfiles, contains('uid1'));
      // The startups were closed for their teams or deleted first.
      expect(startups.closedAllMine, isTrue);
    });

    test('the founder\'s choice for each startup is followed', () async {
      auth.signedIn = verified();
      const fates = {
        'a': StartupFate.delete(),
        'b': StartupFate.close(nextFounder: 'u2'),
      };
      await repo.deleteAccount(password: 'Startup1', fates: fates);
      expect(startups.settledFates, fates);
      expect(auth.calls, contains('delete'));
    });

    test('when closing the startups fails, nothing is deleted', () async {
      auth.signedIn = verified();
      startups.closeAllFails = AuthFailure.network;
      expect(await failureOf(() => repo.deleteAccount()), AuthFailure.network);
      expect(auth.calls, isNot(contains('delete')));
      expect(users.deletedProfiles, isEmpty);
    });

    test('an old sign-in removes nothing and asks for the password', () async {
      auth.signedIn = verified();
      auth.recentlySignedIn = false;
      expect(
        await failureOf(() => repo.deleteAccount()),
        AuthFailure.requiresRecentLogin,
      );
      expect(auth.calls, isNot(contains('delete')));
      expect(users.deletedProfiles, isEmpty);
      await repo.deleteAccount(password: 'Startup1');
      expect(auth.calls, contains('reauth'));
      expect(auth.calls, contains('delete'));
    });
  });
}
