import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/features/login_and_signup/view_models/forgot_password_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/login_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_view_model.dart';
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
      String phone = '512345678',
      String password = 'Startup1!',
      String confirm = 'Startup1!',
      String? city = 'Riyadh',
      List<String> sectors = const ['Fintech'],
    }) =>
        vm.submit(
          fullName: name,
          email: email,
          phone: phone,
          password: password,
          confirmPassword: confirm,
          city: city,
          sectors: sectors,
          role: AccountRole.founder,
        );

    test('shows every field error at once and does not call Firebase', () async {
      final vm = SignupViewModel(authRepository: repo);

      final result = await submit(
        vm,
        name: '  ',
        email: 'nope',
        phone: '12',
        password: 'abc',
        confirm: '',
        city: null,
        sectors: const [],
      );

      expect(result, isNull);
      expect(vm.attempted, isTrue);
      expect(vm.fullNameError, AppStrings.fullNameRequired);
      expect(vm.emailError, AppStrings.emailInvalid);
      expect(vm.phoneError, AppStrings.phoneInvalid);
      expect(vm.passwordError, AppStrings.passwordTooShort);
      expect(vm.confirmPasswordError, AppStrings.confirmPasswordRequired);
      expect(vm.cityError, AppStrings.cityRequired);
      expect(vm.sectorsError, AppStrings.sectorsRequired);
      expect(repo.signUpCalls, 0);
    });

    test("editing a field clears only that field's error", () async {
      final vm = SignupViewModel(authRepository: repo);
      await submit(vm, name: '', email: 'nope');

      vm.clearError(SignupField.email);

      expect(vm.emailError, isNull);
      expect(vm.fullNameError, AppStrings.fullNameRequired);
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
    test('missing or malformed values are reported under their field, with no request', () async {
      final vm = LoginViewModel(authRepository: repo);

      expect(await vm.submit(email: '', password: 'x'), isNull);
      expect(vm.emailError, AppStrings.loginEmailInvalid);
      expect(vm.passwordError, isNull);
      expect(await vm.submit(email: 'a@b.co', password: ''), isNull);
      expect(vm.emailError, isNull);
      expect(vm.passwordError, AppStrings.loginPasswordRequired);
      expect(vm.formError, isNull);
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

    test('unverified email asks for the pop-up and allows resending', () async {
      repo.logInFails = AuthFailure.emailNotVerified;
      final vm = LoginViewModel(authRepository: repo);

      expect(await vm.submit(email: 'a@b.co', password: 'Startup1'), isNull);
      expect(vm.needsVerification, isTrue);
      expect(vm.verificationReminder, isTrue); // a reminder, not the first pop-up
      expect(vm.verificationEmail, 'a@b.co');
      expect(vm.formError, isNull);

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

  group('Verify your email pop-up (after sign up)', () {
    LoginViewModel make({required bool emailSent}) {
      final vm = LoginViewModel(authRepository: repo);
      vm.promptVerification(
        email: ' a@b.co ',
        password: 'Startup1!',
        emailSent: emailSent,
      );
      return vm;
    }

    test('warns when the first email could not be sent', () {
      final vm = make(emailSent: false);

      expect(vm.needsVerification, isTrue);
      expect(vm.verificationReminder, isFalse); // the first pop-up
      expect(vm.verificationEmail, 'a@b.co');
      expect(vm.resendMessage, AppStrings.checkEmailSendFailed);
      expect(vm.resendFailed, isTrue);
    });

    test('resend confirms success', () async {
      final vm = make(emailSent: true);

      await vm.resendVerification();

      expect(repo.resendCalls, 1);
      expect(vm.resendMessage, AppStrings.verificationSent);
      expect(vm.resendFailed, isFalse);
    });

    test('resend reports rate limiting', () async {
      repo.resendFails = AuthFailure.tooManyRequests;
      final vm = make(emailSent: true);

      await vm.resendVerification();

      expect(vm.resendMessage, AppStrings.tooManyRequests);
      expect(vm.resendFailed, isTrue);
    });

    test('closing the pop-up clears the state', () {
      final vm = make(emailSent: false);

      vm.dismissVerification();

      expect(vm.needsVerification, isFalse);
      expect(vm.resendMessage, isNull);
    });
  });
}
