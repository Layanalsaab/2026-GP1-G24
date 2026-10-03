import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/features/login_and_signup/view_models/check_email_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/forgot_password_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/login_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_view_model.dart';
import 'package:startsa/features/profiles/view_models/founder_onboarding_view_model.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';

import '../../support/fakes.dart';

void main() {
  late FakeAuthRepository repo;

  setUp(() => repo = FakeAuthRepository());

  group('SignupViewModel', () {
    Future<SignupResult?> submit(
      SignupViewModel vm, {
      String name = 'Mohammed Ahmed',
      String email = 'a@b.co',
      String password = 'Startup1',
      String confirm = 'Startup1',
    }) =>
        vm.submit(
          fullName: name,
          email: email,
          password: password,
          confirmPassword: confirm,
          role: AccountRole.founder,
        );

    test('shows every field error at once and does not call Firebase', () async {
      final vm = SignupViewModel(authRepository: repo);

      final result = await submit(vm, name: '  ', email: 'nope', password: 'abc', confirm: '');

      expect(result, isNull);
      expect(vm.fullNameError, AppStrings.fullNameRequired);
      expect(vm.emailError, AppStrings.emailInvalid);
      expect(vm.passwordError, AppStrings.passwordTooShort);
      expect(vm.confirmPasswordError, AppStrings.confirmPasswordRequired);
      expect(repo.signUpCalls, 0);
    });

    test('reports mismatched passwords under the confirm field', () async {
      final vm = SignupViewModel(authRepository: repo);

      await submit(vm, confirm: 'Different1');

      expect(vm.confirmPasswordError, AppStrings.passwordsDontMatch);
      expect(vm.passwordError, isNull);
      expect(repo.signUpCalls, 0);
    });

    test('succeeds with valid input', () async {
      final vm = SignupViewModel(authRepository: repo);

      final result = await submit(vm);

      expect(result?.verificationEmailSent, isTrue);
      expect(repo.signUpCalls, 1);
      expect(vm.isLoading, isFalse);
      expect(vm.formError, isNull);
    });

    test('shows the duplicate-email message under the email field', () async {
      repo.signUpFails = AuthFailure.emailInUse;
      final vm = SignupViewModel(authRepository: repo);

      expect(await submit(vm), isNull);
      expect(vm.emailError, AppStrings.emailInUse);
    });

    test('shows a form error when the profile could not be saved', () async {
      repo.signUpFails = AuthFailure.profileSaveFailed;
      final vm = SignupViewModel(authRepository: repo);

      await submit(vm);

      expect(vm.formError, AppStrings.profileSaveFailed);
    });

    test('ignores a second tap while loading', () async {
      final gate = Completer<void>();
      repo.gate = gate.future;
      final vm = SignupViewModel(authRepository: repo);

      final first = submit(vm);
      await Future<void>.delayed(Duration.zero);
      expect(vm.isLoading, isTrue);
      final second = await submit(vm);

      expect(second, isNull);
      expect(repo.signUpCalls, 1);

      gate.complete();
      await first;
      expect(vm.isLoading, isFalse);
    });
  });

  group('LoginViewModel', () {
    test('missing email or password gets the generic message without a request', () async {
      final vm = LoginViewModel(authRepository: repo);

      expect(await vm.submit(email: '', password: 'x'), isNull);
      expect(vm.formError, AppStrings.incorrectCredentials);
      expect(await vm.submit(email: 'a@b.co', password: ''), isNull);
      expect(vm.formError, AppStrings.incorrectCredentials);
      expect(repo.logInCalls, 0);
    });

    test('wrong email and wrong password look identical', () async {
      final vm = LoginViewModel(authRepository: repo);
      repo.logInFails = AuthFailure.invalidCredentials;

      await vm.submit(email: 'a@b.co', password: 'wrong');
      final wrongPassword = vm.formError;
      repo.logInFails = AuthFailure.invalidEmail;
      await vm.submit(email: 'nobody@b.co', password: 'wrong');

      expect(wrongPassword, AppStrings.incorrectCredentials);
      expect(vm.formError, AppStrings.incorrectCredentials);
      expect(vm.needsVerification, isFalse);
    });

    test('returns the user on success', () async {
      final vm = LoginViewModel(authRepository: repo);

      final user = await vm.submit(email: ' a@b.co ', password: 'Startup1');

      expect(user?.role, AccountRole.founder);
      expect(vm.formError, isNull);
    });

    test('unverified email shows the message and allows resending', () async {
      repo.logInFails = AuthFailure.emailNotVerified;
      final vm = LoginViewModel(authRepository: repo);

      expect(await vm.submit(email: 'a@b.co', password: 'Startup1'), isNull);
      expect(vm.needsVerification, isTrue);
      expect(vm.formError, AppStrings.verifyEmailFirst);

      await vm.resendVerification();

      expect(repo.resendCalls, 1);
      expect(vm.resendMessage, AppStrings.verificationSent);
      expect(vm.resendFailed, isFalse);
    });

    test('resend is unavailable until verification is actually needed', () async {
      final vm = LoginViewModel(authRepository: repo);

      await vm.resendVerification();

      expect(repo.resendCalls, 0);
    });

    test('ignores a second tap while loading', () async {
      final gate = Completer<void>();
      repo.gate = gate.future;
      final vm = LoginViewModel(authRepository: repo);

      final first = vm.submit(email: 'a@b.co', password: 'Startup1');
      await Future<void>.delayed(Duration.zero);
      await vm.submit(email: 'a@b.co', password: 'Startup1');

      expect(repo.logInCalls, 1);
      gate.complete();
      await first;
    });

    test('network problems are reported as such', () async {
      repo.logInFails = AuthFailure.network;
      final vm = LoginViewModel(authRepository: repo);

      await vm.submit(email: 'a@b.co', password: 'Startup1');

      expect(vm.formError, AppStrings.networkError);
    });
  });

  group('ForgotPasswordViewModel', () {
    test('validates the email before sending', () async {
      final vm = ForgotPasswordViewModel(authRepository: repo);

      await vm.submit('not-an-email');

      expect(vm.emailError, AppStrings.emailInvalid);
      expect(repo.resetCalls, 0);
      expect(vm.successMessage, isNull);
    });

    test('invalid email format: shows an error and sends nothing', () async {
      final vm = ForgotPasswordViewModel(authRepository: repo);

      for (final bad in ['', 'not-an-email', 'name@', '@example.com']) {
        await vm.submit(bad);
        expect(vm.emailError, isNotNull, reason: bad);
        expect(vm.successMessage, isNull, reason: bad);
      }
      expect(repo.resetCalls, 0);
    });

    test('shows the same message for any valid email', () async {
      final vm = ForgotPasswordViewModel(authRepository: repo);

      await vm.submit('registered@example.com');
      final first = vm.successMessage;
      await vm.submit('stranger@example.com');

      expect(first, AppStrings.resetLinkMessage);
      expect(vm.successMessage, AppStrings.resetLinkMessage);
      expect(vm.emailError, isNull);
      expect(repo.resetCalls, 2);
    });

    test('does not claim success when offline', () async {
      repo.resetFails = AuthFailure.network;
      final vm = ForgotPasswordViewModel(authRepository: repo);

      await vm.submit('a@b.co');

      expect(vm.successMessage, isNull);
      expect(vm.formError, AppStrings.networkError);
    });
  });

  group('CheckEmailViewModel', () {
    test('warns when the first email could not be sent', () {
      final vm = CheckEmailViewModel(
        email: 'a@b.co',
        password: 'Startup1',
        verificationEmailSent: false,
        authRepository: repo,
      );

      expect(vm.message, AppStrings.checkEmailSendFailed);
      expect(vm.messageIsError, isTrue);
    });

    test('resend confirms success', () async {
      final vm = CheckEmailViewModel(
        email: 'a@b.co',
        password: 'Startup1',
        verificationEmailSent: true,
        authRepository: repo,
      );

      await vm.resend();

      expect(repo.resendCalls, 1);
      expect(vm.message, AppStrings.verificationSent);
      expect(vm.messageIsError, isFalse);
    });

    test('resend reports rate limiting', () async {
      repo.resendFails = AuthFailure.tooManyRequests;
      final vm = CheckEmailViewModel(
        email: 'a@b.co',
        password: 'Startup1',
        verificationEmailSent: true,
        authRepository: repo,
      );

      await vm.resend();

      expect(vm.message, AppStrings.tooManyRequests);
      expect(vm.messageIsError, isTrue);
    });
  });

  group('FounderOnboardingViewModel', () {
    late FakeUserRepository users;

    setUp(() => users = FakeUserRepository());

    FounderOnboardingViewModel make() =>
        FounderOnboardingViewModel(userId: 'uid1', userRepository: users);

    test('refuses to save until all three answers are chosen', () async {
      final vm = make()..selectSector('Fintech');

      expect(await vm.submit(), isFalse);
      expect(vm.error, AppStrings.onboardingIncomplete);
      expect(users.onboardingSaves, 0);
    });

    test('saves the chosen answers', () async {
      final vm = make()
        ..selectSector('HealthTech')
        ..selectStage('Pre-seed')
        ..selectCity('Riyadh');

      expect(await vm.submit(), isTrue);
      expect(users.savedOnboarding, {
        'sector': 'HealthTech',
        'stage': 'Pre-seed',
        'city': 'Riyadh',
      });
      expect(vm.error, isNull);
    });

    test('keeps the answers and shows an error when saving fails', () async {
      users.onboardingFails = AuthFailure.unknown;
      final vm = make()
        ..selectSector('HealthTech')
        ..selectStage('Seed')
        ..selectCity('Jeddah');

      expect(await vm.submit(), isFalse);
      expect(vm.error, AppStrings.onboardingSaveFailed);
      expect(vm.sector, 'HealthTech');
      expect(vm.isLoading, isFalse);
    });

    test('reports being offline', () async {
      users.onboardingFails = AuthFailure.network;
      final vm = make()
        ..selectSector('HealthTech')
        ..selectStage('Seed')
        ..selectCity('Jeddah');

      await vm.submit();

      expect(vm.error, AppStrings.networkError);
    });

    test('changing an answer clears the error', () async {
      final vm = make();
      await vm.submit();
      expect(vm.error, isNotNull);

      vm.selectCity('Dammam');

      expect(vm.error, isNull);
    });
  });
}
