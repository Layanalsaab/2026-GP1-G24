import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/account_strings.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/data_access/firebase_services/auth_service.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/features/profiles/view_models/account_view_model.dart';
import 'package:startsa/features/profiles/view_models/change_password_view_model.dart';
import 'package:startsa/features/profiles/view_models/delete_account_view_model.dart';
import 'package:startsa/features/profiles/view_models/edit_account_view_model.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';

import '../../support/fakes.dart';

void main() {
  const founder = AppUser(
    uid: 'uid1',
    role: AccountRole.founder,
    fullName: 'Reem Al-Harbi',
    email: 'reem@example.com',
    onboardingCompleted: true,
    city: 'Riyadh',
    bio: 'Nurse turned founder.',
  );

  Matcher failsWith(AuthFailure failure) => throwsA(
        isA<AuthException>().having((e) => e.failure, 'failure', failure),
      );

  group('AccountViewModel', () {
    test('reload shows the latest saved profile', () async {
      final users = FakeUserRepository();
      users.profiles['uid1'] = founder.copyWith(fullName: 'Reem A.');
      final vm = AccountViewModel(user: founder, userRepository: users);

      await vm.reload();

      expect(vm.user.fullName, 'Reem A.');
    });

    test('reload keeps the current details when loading fails', () async {
      final users = FakeUserRepository()..getFails = AuthFailure.network;
      final vm = AccountViewModel(user: founder, userRepository: users);

      await vm.reload();

      expect(vm.user.fullName, 'Reem Al-Harbi');
    });

    test('a reload that finishes after an edit keeps the edit', () async {
      final users = FakeUserRepository();
      users.profiles['uid1'] = founder; // the older saved version
      final slow = Completer<void>();
      users.getProfileGate = slow.future;
      final vm = AccountViewModel(user: founder, userRepository: users);

      final reloading = vm.reload();
      vm.updateUser(founder.copyWith(fullName: 'Reem Edited'));
      slow.complete();
      await reloading;

      expect(vm.user.fullName, 'Reem Edited');
    });
  });

  group('EditAccountViewModel', () {
    late FakeUserRepository users;

    setUp(() => users = FakeUserRepository());

    test('starts with the saved city', () {
      final vm = EditAccountViewModel(user: founder, userRepository: users);

      expect(vm.city, 'Riyadh');
    });

    test('an empty name shows an error and saves nothing', () async {
      final vm = EditAccountViewModel(user: founder, userRepository: users);

      final result = await vm.submit(fullName: '   ', bio: '');

      expect(result, isNull);
      expect(vm.fullNameError, AppStrings.fullNameRequired);
      expect(users.profileUpdates, 0);
    });

    test('saves trimmed values and returns the updated user', () async {
      final vm = EditAccountViewModel(user: founder, userRepository: users);
      vm.selectCity('Jeddah');

      final result = await vm.submit(
        fullName: '  Reem Alharbi ',
        bio: ' Building home care. ',
      );

      expect(users.savedProfile, {
        'fullName': 'Reem Alharbi',
        'bio': 'Building home care.',
        'city': 'Jeddah',
      });
      expect(result?.fullName, 'Reem Alharbi');
      expect(result?.city, 'Jeddah');
      expect(result?.bio, 'Building home care.');
      expect(result?.email, 'reem@example.com'); // the email never changes
      expect(vm.isLoading, isFalse);
    });

    test('a network problem shows the network message', () async {
      users.updateFails = AuthFailure.network;
      final vm = EditAccountViewModel(user: founder, userRepository: users);

      expect(await vm.submit(fullName: 'Reem', bio: ''), isNull);
      expect(vm.formError, AppStrings.networkError);
    });

    test('any other failure shows the save-failed message', () async {
      users.updateFails = AuthFailure.unknown;
      final vm = EditAccountViewModel(user: founder, userRepository: users);

      expect(await vm.submit(fullName: 'Reem', bio: ''), isNull);
      expect(vm.formError, AccountStrings.saveFailed);
    });
  });

  group('ChangePasswordViewModel', () {
    late FakeAuthRepository repo;

    setUp(() => repo = FakeAuthRepository());

    Future<bool> submit(
      ChangePasswordViewModel vm, {
      String current = 'OldPass1',
      String next = 'NewPass1',
      String confirm = 'NewPass1',
    }) =>
        vm.submit(
          currentPassword: current,
          newPassword: next,
          confirmPassword: confirm,
        );

    test('shows every field error at once and changes nothing', () async {
      final vm = ChangePasswordViewModel(authRepository: repo);

      expect(await submit(vm, current: '', next: 'abc', confirm: ''), isFalse);
      expect(vm.currentPasswordError, AccountStrings.currentPasswordRequired);
      expect(vm.newPasswordError, AppStrings.passwordTooShort);
      expect(vm.confirmPasswordError, AppStrings.confirmPasswordRequired);
      expect(repo.changePasswordCalls, 0);
    });

    test('the new password must be different from the current one', () async {
      final vm = ChangePasswordViewModel(authRepository: repo);

      await submit(vm, next: 'OldPass1', confirm: 'OldPass1');

      expect(vm.newPasswordError, AccountStrings.samePassword);
      expect(repo.changePasswordCalls, 0);
    });

    test('reports a mismatched confirmation', () async {
      final vm = ChangePasswordViewModel(authRepository: repo);

      await submit(vm, confirm: 'Other123');

      expect(vm.confirmPasswordError, AppStrings.passwordsDontMatch);
      expect(repo.changePasswordCalls, 0);
    });

    test('a wrong current password is shown under that field', () async {
      repo.changePasswordFails = AuthFailure.invalidCredentials;
      final vm = ChangePasswordViewModel(authRepository: repo);

      expect(await submit(vm), isFalse);
      expect(vm.currentPasswordError, AccountStrings.currentPasswordIncorrect);
      expect(vm.isLoading, isFalse);
    });

    test('succeeds with valid input', () async {
      final vm = ChangePasswordViewModel(authRepository: repo);

      expect(await submit(vm), isTrue);
      expect(repo.changePasswordCalls, 1);
      expect(vm.currentPasswordError, isNull);
      expect(vm.formError, isNull);
    });
  });

  group('DeleteAccountViewModel', () {
    late FakeAuthRepository repo;

    setUp(() => repo = FakeAuthRepository());

    test('an empty password is refused without calling Firebase', () async {
      final vm = DeleteAccountViewModel(authRepository: repo);

      expect(await vm.submit(''), isFalse);
      expect(vm.passwordError, AccountStrings.passwordRequired);
      expect(repo.deleteAccountCalls, 0);
    });

    test('a wrong password shows an error', () async {
      repo.deleteAccountFails = AuthFailure.invalidCredentials;
      final vm = DeleteAccountViewModel(authRepository: repo);

      expect(await vm.submit('Wrong123'), isFalse);
      expect(vm.passwordError, AccountStrings.passwordIncorrect);
    });

    test('a network problem shows the network message', () async {
      repo.deleteAccountFails = AuthFailure.network;
      final vm = DeleteAccountViewModel(authRepository: repo);

      expect(await vm.submit('OldPass1'), isFalse);
      expect(vm.formError, AppStrings.networkError);
    });

    test('the right password deletes the account', () async {
      final vm = DeleteAccountViewModel(authRepository: repo);

      expect(await vm.submit('OldPass1'), isTrue);
      expect(repo.deleteAccountCalls, 1);
    });
  });

  group('AuthRepository account actions', () {
    late FakeAuthService auth;
    late FakeUserRepository users;
    late AuthRepository repo;

    setUp(() {
      auth = FakeAuthService()
        ..signedIn = const AuthAccount(
          uid: 'uid1',
          email: 'reem@example.com',
          emailVerified: true,
        );
      users = FakeUserRepository()..profiles['uid1'] = founder;
      repo = AuthRepository(authService: auth, userRepository: users);
    });

    test('changePassword checks the current password, then updates it', () async {
      await repo.changePassword(
        currentPassword: 'OldPass1',
        newPassword: 'NewPass1',
      );

      expect(auth.calls, ['reauth', 'updatePassword']);
      expect(auth.updatedPassword, 'NewPass1');
    });

    test('a wrong current password changes nothing', () async {
      auth.reauthFails = AuthFailure.invalidCredentials;

      await expectLater(
        repo.changePassword(currentPassword: 'Wrong123', newPassword: 'NewPass1'),
        failsWith(AuthFailure.invalidCredentials),
      );
      expect(auth.calls, ['reauth']);
      expect(auth.updatedPassword, isNull);
    });

    test('deleteAccount deletes the profile, then the login, and signs out', () async {
      await repo.deleteAccount('OldPass1');

      expect(users.deletedProfiles, ['uid1']);
      expect(users.profiles, isEmpty);
      expect(auth.calls, ['reauth', 'delete', 'signOut']);
      expect(auth.signedIn, isNull);
    });

    test('a wrong password deletes nothing', () async {
      auth.reauthFails = AuthFailure.invalidCredentials;

      await expectLater(
        repo.deleteAccount('Wrong123'),
        failsWith(AuthFailure.invalidCredentials),
      );
      expect(users.deletedProfiles, isEmpty);
      expect(auth.calls, ['reauth']);
    });

    test('if the profile cannot be deleted, the login is kept', () async {
      users.deleteProfileFails = AuthFailure.network;

      await expectLater(
        repo.deleteAccount('OldPass1'),
        failsWith(AuthFailure.network),
      );
      expect(auth.calls, ['reauth']); // no 'delete'
      expect(auth.signedIn, isNotNull);
    });

    test('nobody signed in: fails without deleting anything', () async {
      auth.signedIn = null;

      await expectLater(
        repo.deleteAccount('OldPass1'),
        failsWith(AuthFailure.unknown),
      );
      expect(users.deletedProfiles, isEmpty);
      expect(auth.calls, isEmpty);
    });
  });
}
