import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/validation_strings.dart';
import 'package:startsa/data_access/device_services/profile_photo_picker_service.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/features/login_and_signup/view_models/forgot_password_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/investor_onboarding_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/login_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_flow.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/verify_email_view_model.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';

import '../../support/auth_fakes.dart';
import '../../support/fakes.dart';

void _fillValid(SignupViewModel vm, {String email = 'sara@gmail.com'}) {
  vm.name.text = 'Sara Alswailem';
  vm.email.text = email;
  vm.phone.text = '55 123 4567';
  vm.password.text = 'Sara@1234';
  vm.confirm.text = 'Sara@1234';
  vm.setCity('Riyadh');
  if (vm.isFounder) {
    vm.toggleSector('HealthTech');
  } else {
    vm.value.text = 'Introductions to venture capital firms.';
    vm.gain.text = 'Early access to good startups.';
  }
}

void main() {
  group('SignupViewModel', () {
    late FakeAuthRepository auth;
    late FakePhotoPicker picker;

    SignupViewModel make(AccountRole role, {SignupFlow? flow}) =>
        SignupViewModel(
          role: role,
          flow: flow,
          authRepository: auth,
          photoPicker: picker,
        );

    setUp(() {
      auth = FakeAuthRepository();
      picker = FakePhotoPicker();
    });

    test('shows no errors before the first submit except a live email', () {
      final vm = make(AccountRole.founder);
      addTearDown(vm.dispose);
      expect(vm.nameError, isNull);
      expect(vm.emailError, isNull);
      vm.email.text = 'sara@gmail';
      expect(vm.emailError, ValidationStrings.emailLive);
      vm.confirm.text = 'x';
      expect(vm.confirmError, ValidationStrings.confirmMismatch);
    });

    test('founder submit with an empty form shows every error', () async {
      final vm = make(AccountRole.founder);
      addTearDown(vm.dispose);
      expect(await vm.submit(), isFalse);
      expect(vm.nameError, ValidationStrings.fullName);
      expect(vm.emailError, ValidationStrings.emailLive);
      expect(vm.phoneError, ValidationStrings.phoneRequired);
      expect(vm.cityError, ValidationStrings.city);
      expect(vm.sectorsError, ValidationStrings.sectors);
      expect(vm.gainError, isNull, reason: 'founders are not asked');
      expect(auth.signUpCalls, 0);
    });

    test('investor needs the "gain" text, not sectors', () async {
      final vm = make(AccountRole.investor);
      addTearDown(vm.dispose);
      _fillValid(vm);
      vm.gain.text = '  ';
      expect(await vm.submit(), isFalse);
      expect(vm.gainError, ValidationStrings.gainRequired);
      expect(vm.sectorsError, isNull);
    });

    test('"Other" sector needs its write-in', () async {
      final vm = make(AccountRole.founder);
      addTearDown(vm.dispose);
      _fillValid(vm);
      vm.toggleSector('Other');
      expect(await vm.submit(), isFalse);
      expect(vm.sectorsOtherError, ValidationStrings.otherChips('sector'));
      vm.sectorsOther.text = 'SportsTech';
      expect(vm.isValid, isTrue);
    });

    test('phone counts digits only and ignores the spaces', () {
      final vm = make(AccountRole.founder);
      addTearDown(vm.dispose);
      vm.phone.text = '55 123 4567';
      expect(vm.phoneValid, isTrue);
      vm.phone.text = '55 12';
      expect(vm.phoneValid, isFalse);
    });

    test(
      'a valid founder form creates the account and fills the flow',
      () async {
        final vm = make(AccountRole.founder);
        addTearDown(vm.dispose);
        _fillValid(vm);
        vm.linkedin.text = 'linkedin.com/in/sara';
        expect(await vm.submit(), isTrue);
        expect(auth.signUpCalls, 1);
        expect(auth.lastSignUp!['phone'], '551234567');
        expect(auth.lastSignUp!['city'], 'Riyadh');
        expect(auth.lastSignUp!['sectors'], 'HealthTech');
        expect(auth.lastSignUp!['linkedin'], 'linkedin.com/in/sara');
        expect(vm.flow.email, 'sara@gmail.com');
        expect(vm.flow.password, 'Sara@1234');
        expect(vm.flow.accountCreated, isTrue);
        expect(vm.flow.totalSteps, 6);
      },
    );

    test('an investor flow has 4 steps and saves the gain text', () async {
      final vm = make(AccountRole.investor);
      addTearDown(vm.dispose);
      _fillValid(vm);
      expect(await vm.submit(), isTrue);
      expect(vm.flow.totalSteps, 4);
      expect(auth.lastSignUp!['gain'], 'Early access to good startups.');
      expect(
        auth.lastSignUp!['valueOffered'],
        'Introductions to venture capital firms.',
      );
      expect(auth.lastSignUp!['sectors'], '');
    });

    test(
      'Continue again with the same details never makes a second account',
      () async {
        final flow = SignupFlow(role: AccountRole.founder);
        final first = make(AccountRole.founder, flow: flow);
        addTearDown(first.dispose);
        _fillValid(first);
        await first.submit();
        final second = make(AccountRole.founder, flow: flow);
        addTearDown(second.dispose);
        _fillValid(second);
        expect(await second.submit(), isTrue);
        expect(auth.signUpCalls, 1);
        expect(auth.discardCalls, 0);
      },
    );

    test('a changed email discards the unverified account first', () async {
      final flow = SignupFlow(role: AccountRole.founder);
      final first = make(AccountRole.founder, flow: flow);
      addTearDown(first.dispose);
      _fillValid(first);
      await first.submit();
      final second = make(AccountRole.founder, flow: flow);
      addTearDown(second.dispose);
      _fillValid(second, email: 'new@gmail.com');
      expect(await second.submit(), isTrue);
      expect(auth.discardCalls, 1);
      expect(auth.signUpCalls, 2);
      expect(flow.email, 'new@gmail.com');
    });

    test(
      'email already in use shows under the email and clears on edit',
      () async {
        auth.signUpFails = AuthFailure.emailInUse;
        final vm = make(AccountRole.founder);
        addTearDown(vm.dispose);
        _fillValid(vm);
        expect(await vm.submit(), isFalse);
        expect(vm.emailError, isNotNull);
        expect(vm.flow.accountCreated, isFalse);
        vm.email.text = 'other@gmail.com';
        expect(vm.emailError, isNull);
      },
    );

    test('an unverified account left by an earlier attempt is replaced, not "in use"', () async {
      auth.signUpFails = AuthFailure.emailInUse;
      auth.signUpFailsOnce = true;
      final vm = make(AccountRole.founder);
      addTearDown(vm.dispose);
      _fillValid(vm);
      expect(await vm.submit(), isTrue);
      expect(auth.discardCalls, 1);
      expect(auth.signUpCalls, 2);
      expect(vm.emailError, isNull);
    });

    test('a verified or other-password account stays "in use"', () async {
      auth.signUpFails = AuthFailure.emailInUse;
      auth.discardFails = AuthFailure.unknown;
      final vm = make(AccountRole.founder);
      addTearDown(vm.dispose);
      _fillValid(vm);
      expect(await vm.submit(), isFalse);
      expect(auth.discardCalls, 1);
      expect(vm.emailError, isNotNull);
    });

    test('a network failure is a form error, not a field error', () async {
      auth.signUpFails = AuthFailure.network;
      final vm = make(AccountRole.founder);
      addTearDown(vm.dispose);
      _fillValid(vm);
      expect(await vm.submit(), isFalse);
      expect(vm.formError, isNotNull);
      expect(vm.emailError, isNull);
    });

    test('photo toggles: pick, then remove', () async {
      final vm = make(AccountRole.founder);
      addTearDown(vm.dispose);
      picker.result = File('photo.jpg');
      expect(await vm.togglePhoto(), 'Photo added');
      expect(vm.photo, isNotNull);
      expect(await vm.togglePhoto(), 'Photo removed');
      expect(vm.photo, isNull);
    });

    test('cancelling the picker changes nothing; a failure explains', () async {
      final vm = make(AccountRole.founder);
      addTearDown(vm.dispose);
      expect(await vm.togglePhoto(), isNull);
      picker.failure = ProfilePhotoFailure.tooLarge;
      expect(await vm.togglePhoto(), contains('2 MB'));
    });
  });

  group('VerifyEmailViewModel', () {
    late FakeAuthRepository auth;
    late SignupFlow flow;

    setUp(() {
      auth = FakeAuthRepository();
      flow = SignupFlow(role: AccountRole.founder)
        ..email = 'sara@gmail.com'
        ..password = 'Sara@1234'
        ..accountCreated = true;
    });

    VerifyEmailViewModel make() {
      final vm = VerifyEmailViewModel(flow: flow, authRepository: auth);
      addTearDown(vm.dispose);
      return vm;
    }

    test('the email starts pre-filled with the sign-up email', () {
      expect(make().email.text, 'sara@gmail.com');
    });

    test('empty password -> "Enter your password", no network call', () async {
      final vm = make();
      expect(await vm.submit(), VerifyResult.invalid);
      expect(vm.passwordError, ValidationStrings.passwordRequired);
      expect(auth.logInCalls, 0);
    });

    test(
      'a different email -> "This isn’t the email you signed up with."',
      () async {
        final vm = make();
        vm.email.text = 'other@gmail.com';
        vm.password.text = 'Sara@1234';
        expect(await vm.submit(), VerifyResult.invalid);
        expect(vm.emailError, ValidationStrings.verifyWrongEmail);
        expect(auth.logInCalls, 0);
      },
    );

    test('malformed email shows the log-in email errors', () async {
      final vm = make();
      vm.email.text = '';
      vm.password.text = 'x';
      await vm.submit();
      expect(vm.emailError, ValidationStrings.emailRequired);
      vm.email.text = 'nope';
      await vm.submit();
      expect(vm.emailError, ValidationStrings.emailInvalid);
    });

    test('a wrong password says so under the field', () async {
      auth.logInFails = AuthFailure.invalidCredentials;
      final vm = make();
      vm.password.text = 'Wrong@123';
      expect(await vm.submit(), VerifyResult.wrongPassword);
      expect(vm.passwordError, ValidationStrings.passwordIncorrect);
      vm.password.text = 'Wrong@1234';
      expect(vm.passwordError, isNull);
    });

    test('an unverified account asks to open the link', () async {
      auth.logInFails = AuthFailure.emailNotVerified;
      final vm = make();
      vm.password.text = 'Sara@1234';
      expect(await vm.submit(), VerifyResult.notVerified);
    });

    test(
      'verified: returns the profile, never trusts a typed password',
      () async {
        final vm = make();
        vm.password.text = 'anything-the-server-accepts';
        expect(await vm.submit(), VerifyResult.verified);
        expect(vm.user, isNotNull);
        expect(auth.logInCalls, 1);
      },
    );

    test('network trouble is a form error', () async {
      auth.logInFails = AuthFailure.network;
      final vm = make();
      vm.password.text = 'Sara@1234';
      expect(await vm.submit(), VerifyResult.failed);
      expect(vm.formError, isNotNull);
    });

    test('resend uses the credentials kept from step 1', () async {
      final vm = make();
      expect(await vm.resend(), ResendOutcome.sent);
      auth.resendResult = ResendResult.alreadyVerified;
      expect(await vm.resend(), ResendOutcome.alreadyVerified);
      auth.resendFails = AuthFailure.tooManyRequests;
      expect(await vm.resend(), ResendOutcome.failed);
      expect(vm.formError, isNotNull);
      expect(auth.resendCalls, 3);
    });
  });

  group('LoginViewModel', () {
    late FakeAuthRepository auth;
    setUp(() => auth = FakeAuthRepository());

    LoginViewModel make() {
      final vm = LoginViewModel(authRepository: auth);
      addTearDown(vm.dispose);
      return vm;
    }

    test('empty form: both errors on submit, none before', () async {
      final vm = make();
      expect(vm.emailError, isNull);
      expect(await vm.submit(), isNull);
      expect(vm.emailError, ValidationStrings.emailRequired);
      expect(vm.passwordError, ValidationStrings.passwordRequired);
      expect(auth.logInCalls, 0);
    });

    test('malformed email -> "Enter a valid email address"', () async {
      final vm = make();
      vm.email.text = 'sara@';
      vm.password.text = 'x';
      await vm.submit();
      expect(vm.emailError, ValidationStrings.emailInvalid);
    });

    test('success returns the user', () async {
      final vm = make();
      vm.email.text = 'a@b.co';
      vm.password.text = 'Pass@123';
      final user = await vm.submit();
      expect(user?.uid, 'uid1');
    });

    test('wrong credentials: one message under the password', () async {
      auth.logInFails = AuthFailure.invalidCredentials;
      final vm = make();
      vm.email.text = 'a@b.co';
      vm.password.text = 'Pass@123';
      expect(await vm.submit(), isNull);
      expect(vm.passwordError, isNotNull);
      expect(vm.needsVerification, isFalse);
      vm.password.text = 'Pass@1234';
      expect(vm.passwordError, isNull);
    });

    test('unverified: needsVerification, then resend works', () async {
      auth.logInFails = AuthFailure.emailNotVerified;
      final vm = make();
      vm.email.text = 'a@b.co';
      vm.password.text = 'Pass@123';
      expect(await vm.submit(), isNull);
      expect(vm.needsVerification, isTrue);
      expect(vm.verificationEmail, 'a@b.co');
      expect(await vm.resend(), ResendOutcome.sent);
    });
  });

  group('ForgotPasswordViewModel', () {
    late FakeAuthRepository auth;
    setUp(() => auth = FakeAuthRepository());

    ForgotPasswordViewModel make([String email = '']) {
      final vm = ForgotPasswordViewModel(email: email, authRepository: auth);
      addTearDown(vm.dispose);
      return vm;
    }

    test('is pre-filled and rejects a bad email', () async {
      final vm = make('x');
      expect(vm.email.text, 'x');
      expect(await vm.submit(), isNull);
      expect(vm.emailError, ValidationStrings.emailInvalid);
      expect(auth.resetCalls, 0);
    });

    test('sends the link and returns the address', () async {
      final vm = make();
      vm.email.text = ' a@b.co ';
      expect(await vm.submit(), 'a@b.co');
      expect(auth.resetCalls, 1);
    });

    test('a network failure is a form error', () async {
      auth.resetFails = AuthFailure.network;
      final vm = make('a@b.co');
      expect(await vm.submit(), isNull);
      expect(vm.formError, isNotNull);
    });
  });

  group('InvestorOnboardingViewModel', () {
    late FakeUserRepository users;
    const user = AppUser(
      uid: 'u1',
      role: AccountRole.investor,
      fullName: 'Layan Alsaab',
      email: 'layan@gmail.com',
      gain: 'The team',
      valueOffered: 'Mentoring',
    );

    setUp(() {
      users = FakeUserRepository()..profiles['u1'] = user;
    });

    InvestorOnboardingViewModel make() {
      final vm = InvestorOnboardingViewModel(user: user, userRepository: users);
      addTearDown(vm.dispose);
      return vm;
    }

    void answerStep3(InvestorOnboardingViewModel vm) {
      vm.pickDeals('1–5');
      vm.pickLed('No');
      vm.pickCoInvest('Possibly');
      vm.pickTicket('SAR 100K – 500K');
    }

    test('step 3 is incomplete until the required answers are given', () {
      final vm = make();
      expect(vm.step3Complete, isFalse);
      answerStep3(vm);
      expect(vm.step3Complete, isTrue);
    });

    test('Next while incomplete marks the step tried and shows the errors', () {
      final vm = make();
      expect(vm.dealsError, isNull);
      expect(vm.tryStep3(), isFalse);
      expect(vm.dealsError, ValidationStrings.chooseOne);
      expect(vm.ledError, ValidationStrings.chooseOne);
      expect(vm.coInvestError, ValidationStrings.chooseOne);
      expect(vm.ticketError, ValidationStrings.chooseOne);
    });

    test('"Other" ticket needs text', () {
      final vm = make();
      answerStep3(vm);
      vm.pickTicket('Other');
      expect(vm.step3Complete, isFalse);
      vm.ticketOther.text = 'SAR 50K';
      expect(vm.step3Complete, isTrue);
    });

    test('rounds led only matters when Yes; No clears it', () {
      final vm = make();
      vm.pickLed('Yes');
      vm.pickRoundsLed('3–5');
      expect(vm.roundsLed, '3–5');
      vm.pickLed('No');
      expect(vm.roundsLed, isNull);
    });

    test('minimum above maximum blocks Next with the live error', () {
      final vm = make();
      answerStep3(vm);
      vm.roundMin.text = '5,000,000';
      vm.roundMax.text = '1,000,000';
      expect(vm.rangeBad, isTrue);
      expect(vm.rangeError, ValidationStrings.roundRange);
      expect(vm.step3Complete, isFalse);
      vm.roundMax.text = '6,000,000';
      expect(vm.step3Complete, isTrue);
    });

    test('step 4 needs a sector, a stage and a model', () async {
      final vm = make();
      expect(vm.step4Complete, isFalse);
      expect(await vm.finish(), isNull);
      expect(vm.sectorsError, ValidationStrings.sectors);
      expect(vm.stagesError, ValidationStrings.selectAtLeastOneStage);
      expect(vm.modelsError, ValidationStrings.selectAtLeastOneModel);
      expect(users.onboardingSaves, 0);
    });

    test('Finish saves the criteria and marks onboarding complete', () async {
      final vm = make();
      answerStep3(vm);
      vm.roundMin.text = '1,000,000';
      vm.roundMax.text = '5,000,000';
      vm.toggleSector('Fintech');
      vm.toggleSector('HealthTech');
      vm.toggleStage('Seed');
      vm.toggleModel('Business-to-Business (B2B)');
      final updated = await vm.finish();
      expect(updated, isNotNull);
      expect(updated!.onboardingCompleted, isTrue);
      expect(users.onboardingSaves, 1);
      final c = users.savedInvestorCriteria!;
      expect(c.dealsCount, '1–5');
      expect(c.hasLedRound, isFalse);
      expect(c.coInvest, 'Possibly');
      expect(c.ticketBand, 'SAR 100K – 500K');
      expect(c.roundMin, 1000000);
      expect(c.roundMax, 5000000);
      // Sectors are saved in the chip order, not the tap order.
      expect(c.sectors, ['HealthTech', 'Fintech']);
      expect(c.stages, ['Seed']);
      expect(c.commerceModels, ['Business-to-Business (B2B)']);
      // What they look for is what they said they hope to gain at sign-up.
      expect(c.lookFor, 'The team');
      // The value they bring was saved at sign-up: not asked or touched here.
      expect(users.savedValueOffered, isNull);
      expect(updated.valueOffered, 'Mentoring');
    });

    test('a failed save is a form error and nothing is lost', () async {
      users.updateFails = AuthFailure.network;
      final vm = make();
      vm.toggleSector('Fintech');
      vm.toggleStage('Seed');
      vm.toggleModel('Other');
      vm.modelsOther.text = 'Subscription';
      expect(await vm.finish(), isNull);
      expect(vm.formError, isNotNull);
      expect(vm.sectors, {'Fintech'});
    });
  });
}
