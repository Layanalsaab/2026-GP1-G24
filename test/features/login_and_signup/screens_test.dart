import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/features/login_and_signup/screens/choose_role_screen.dart';
import 'package:startsa/features/login_and_signup/screens/investor_interests_screen.dart';
import 'package:startsa/features/login_and_signup/screens/investor_investments_screen.dart';
import 'package:startsa/features/login_and_signup/screens/login_screen.dart';
import 'package:startsa/features/login_and_signup/screens/signup_screen.dart';
import 'package:startsa/features/login_and_signup/screens/verify_email_screen.dart';
import 'package:startsa/features/login_and_signup/screens/welcome_screen.dart';
import 'package:startsa/features/login_and_signup/view_models/investor_onboarding_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_flow.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';
import 'package:startsa/shared_ui/widgets/forms/app_field.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';
import 'package:startsa/shared_ui/widgets/overlays/multi_picker_sheet.dart';

import '../../support/fakes.dart';

const _investor = AppUser(
  uid: 'u1',
  role: AccountRole.investor,
  fullName: 'Layan Alsaab',
  email: 'layan@gmail.com',
);

Future<void> _pump(WidgetTester t, Widget home, {double w = 412}) async {
  await t.binding.setSurfaceSize(Size(w, 892));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(
    MaterialApp(navigatorKey: AppToast.navigatorKey, home: home),
  );
  await t.pump(const Duration(milliseconds: 800));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => AuthRepository.instance = FakeAuthRepository());

  testWidgets('welcome shows the three actions', (t) async {
    await _pump(t, const WelcomeScreen());
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  for (final w in [412.0, 360.0]) {
    testWidgets('choose role -> investor sign-up at $w px', (t) async {
      await _pump(t, const ChooseRoleScreen(), w: w);
      expect(find.text('Choose your role'), findsOneWidget);
      await t.tap(find.text('Investor'));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Continue'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 800));
      expect(find.text('STEP 1 OF 4'), findsOneWidget);
      expect(
        find.textContaining('Hope to Gain', findRichText: true),
        findsWidgets,
      );
      expect(t.takeException(), isNull);
    });

    testWidgets('founder sign-up, empty submit shows errors at $w px', (
      t,
    ) async {
      await _pump(
        t,
        SignupScreen(
          role: AccountRole.founder,
          flow: SignupFlow(role: AccountRole.founder),
        ),
        w: w,
      );
      expect(find.text('STEP 1 OF 8'), findsOneWidget);
      await t.tap(find.text('Continue'));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Enter your first and last name.'), findsOneWidget);
      expect(find.text('Please select your city.'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 3));
    });
  }

  testWidgets('investor sign-up asks the value and the gain questions', (
    t,
  ) async {
    await _pump(
      t,
      SignupScreen(
        role: AccountRole.investor,
        flow: SignupFlow(role: AccountRole.investor),
      ),
    );
    final value = find.widgetWithText(
      TextField,
      'Describe the value you can bring',
    );
    final gain = find.widgetWithText(
      TextField,
      'Describe what you hope to gain',
    );
    await t.ensureVisible(value);
    expect(value, findsOneWidget);
    expect(gain, findsOneWidget);
    expect(
      find.textContaining('What Value Can You Bring', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Hope to Gain', findRichText: true),
      findsWidgets,
    );
    // The "i" button opens the example.
    final tip =
        'For example: connections with venture capital firms, experience in real estate, mentoring founders, industry partnerships.';
    expect(find.text(tip), findsNothing);
    await t.ensureVisible(find.byType(InfoButton).first);
    await t.tap(find.byType(InfoButton).first);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text(tip), findsOneWidget);
    // Submitting empty shows the error under the value question.
    await t.tap(find.text('Continue'));
    await t.pump(const Duration(milliseconds: 500));
    expect(
      find.text('Tell founders what you can bring — it can’t be blank.'),
      findsOneWidget,
    );
    await t.pump(const Duration(seconds: 3));
  });

  group('sign-up live rules', () {
    Future<void> openSignup(WidgetTester t, AccountRole role) => _pump(
      t,
      SignupScreen(
        role: role,
        flow: SignupFlow(role: role),
      ),
    );

    testWidgets('full name needs two words, live as you type', (t) async {
      await openSignup(t, AccountRole.founder);
      final field = find.widgetWithText(TextField, 'e.g. Mohammed Ahmed');
      await t.enterText(field, 'Sara');
      await t.pump();
      expect(find.text('Enter your first and last name.'), findsOneWidget);
      await t.enterText(field, 'Sara Ali');
      await t.pump();
      expect(find.text('Enter your first and last name.'), findsNothing);
    });

    testWidgets('email and phone messages are live', (t) async {
      await openSignup(t, AccountRole.founder);
      await t.enterText(
        find.widgetWithText(TextField, 'e.g. example@gmail.com'),
        'sara@gmail',
      );
      await t.pump();
      expect(
        find.text('Enter a valid email, like name@example.com'),
        findsOneWidget,
      );
      await t.enterText(find.widgetWithText(TextField, '5X XXX XXXX'), '55 12');
      await t.pump();
      expect(find.textContaining('9-digit Saudi number'), findsOneWidget);
      await t.enterText(
        find.widgetWithText(TextField, '5X XXX XXXX'),
        '55 123 4567',
      );
      await t.pump();
      expect(find.textContaining('9-digit Saudi number'), findsNothing);
    });

    testWidgets('password rules stay hidden until the field is tapped', (
      t,
    ) async {
      await openSignup(t, AccountRole.investor);
      expect(find.text('One lowercase letter'), findsNothing);
      final pw = find.widgetWithText(TextField, 'e.g. Startup@123');
      await t.ensureVisible(pw);
      await t.tap(pw);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('One lowercase letter'), findsOneWidget);
      expect(find.text('One uppercase letter'), findsOneWidget);
      expect(find.text('One number'), findsOneWidget);
      expect(find.textContaining('One special character'), findsOneWidget);
    });

    testWidgets('the city picker opens, searches and selects', (t) async {
      await openSignup(t, AccountRole.founder);
      await t.ensureVisible(find.text('Select your city'));
      await t.tap(find.text('Select your city'));
      await t.pump(const Duration(milliseconds: 600));
      expect(t.takeException(), isNull);
      await t.enterText(find.byType(TextField).last, 'Jed');
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Jeddah'), findsWidgets);
      expect(t.takeException(), isNull);
    });
  });

  group('founder sign-up redesign', () {
    Future<void> openFounder(WidgetTester t) => _pump(
      t,
      SignupScreen(
        role: AccountRole.founder,
        flow: SignupFlow(role: AccountRole.founder),
      ),
    );

    testWidgets('no log-in footer, a photo row and private pills', (t) async {
      await openFounder(t);
      expect(find.textContaining('Already have an account?'), findsNothing);
      expect(find.text('Profile Photo'), findsOneWidget);
      expect(find.text('Upload photo'), findsOneWidget);
      expect(find.text('Private'), findsNWidgets(2));
      await t.tap(find.text('Private').first);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);
    });

    testWidgets('the investor sign-up keeps its footer and round picker', (
      t,
    ) async {
      await _pump(
        t,
        SignupScreen(
          role: AccountRole.investor,
          flow: SignupFlow(role: AccountRole.investor),
        ),
      );
      expect(find.textContaining('Already have an account?'), findsOneWidget);
      expect(find.text('Add profile photo'), findsOneWidget);
      expect(find.text('Private'), findsNothing);
    });

    testWidgets('bio is required for founders', (t) async {
      await openFounder(t);
      await t.tap(find.text('Continue'));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Please write a short bio.'), findsOneWidget);
      expect(find.text('Select at least one sector.'), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('sectors open a checklist sheet with search and Done', (
      t,
    ) async {
      await openFounder(t);
      await t.ensureVisible(find.text('Select sectors'));
      await t.tap(find.text('Select sectors'));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Search sectors'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      await t.tap(find.text('HealthTech'));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Fintech'));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Done'));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('HealthTech, Fintech'), findsOneWidget);
      expect(find.textContaining('selected'), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('Other needs a write-in; closing the sheet blank unticks it', (
      t,
    ) async {
      await openFounder(t);
      await t.ensureVisible(find.text('Select sectors'));
      await t.tap(find.text('Select sectors'));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 600));
      final other = find.text('Other');
      await t.scrollUntilVisible(
        other,
        300,
        scrollable: find.descendant(
          of: find.descendant(
            of: find.byType(MultiPickerSheet),
            matching: find.byType(ListView),
          ),
          matching: find.byType(Scrollable),
        ),
      );
      await t.tap(other);
      await t.pump(const Duration(milliseconds: 300));
      expect(
        find.widgetWithText(TextField, 'Type your sector, e.g. SportsTech'),
        findsOneWidget,
      );
      await t.tap(find.text('Done'));
      await t.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Please type your sector — it can’t be blank.'),
        findsOneWidget,
      );
      // Tap outside: the sheet closes and Other is unticked again.
      await t.tapAt(const Offset(200, 20));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Select sectors'), findsOneWidget);
      expect(find.textContaining('selected'), findsNothing);
    });

    testWidgets('a misspelled or unknown domain is simply not valid', (
      t,
    ) async {
      await openFounder(t);
      final email = find.widgetWithText(TextField, 'e.g. example@gmail.com');
      for (final bad in [
        'sara@gmial.com',
        'sara@mycompany.sa',
        'sara@gmail.co',
      ]) {
        await t.enterText(email, bad);
        await t.pump();
        expect(
          find.text('Enter a valid email, like name@example.com'),
          findsOneWidget,
          reason: bad,
        );
        expect(find.textContaining('Did you mean'), findsNothing);
        expect(find.textContaining('Make sure your email'), findsNothing);
      }
      await t.enterText(email, 'sara@student.ksu.edu.sa');
      await t.pump();
      expect(find.textContaining('Enter a valid email'), findsNothing);
    });

    testWidgets('leaving with something typed asks first', (t) async {
      await openFounder(t);
      await t.enterText(
        find.widgetWithText(TextField, 'e.g. Mohammed Ahmed'),
        'Sara Ali',
      );
      await t.pump();
      await t.tap(find.bySemanticsLabel('Back').first);
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Discard sign-up?'), findsOneWidget);
      expect(
        find.text(
          'If you go back now, the details you entered will be deleted.',
        ),
        findsOneWidget,
      );
      // Keep editing leaves the data alone.
      await t.tap(find.text('Keep editing'));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Discard sign-up?'), findsNothing);
      expect(find.text('Sara Ali'), findsOneWidget);
    });

    testWidgets('Discard clears the form and goes back', (t) async {
      SignupFlow.current = null;
      addTearDown(() => SignupFlow.current = null);
      await _pump(
        t,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => SignupScreen.open(context, AccountRole.founder),
            child: const Text('open form'),
          ),
        ),
      );
      Future<void> open() async {
        await t.tap(find.text('open form'));
        await t.pump(const Duration(milliseconds: 100));
        await t.pump(const Duration(milliseconds: 900));
      }

      await open();
      await t.enterText(
        find.widgetWithText(TextField, 'e.g. Mohammed Ahmed'),
        'Sara Ali',
      );
      await t.pump();
      await t.tap(find.bySemanticsLabel('Back').first);
      await t.pump(const Duration(milliseconds: 500));
      await t.tap(find.text('Discard'));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 900));
      expect(find.text('open form'), findsOneWidget);
      // Opening it again shows an empty form.
      await open();
      expect(find.text('Sara Ali'), findsNothing);
    });

    testWidgets('an empty form goes back without a dialog', (t) async {
      await openFounder(t);
      await t.tap(find.bySemanticsLabel('Back').first);
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Discard sign-up?'), findsNothing);
    });
  });

  testWidgets('the verify step counts down 60 s before Resend email', (
    t,
  ) async {
    final flow = SignupFlow(role: AccountRole.founder)
      ..email = 'sara@gmail.com'
      ..nextResendAt = DateTime.now().add(const Duration(seconds: 60));
    await _pump(t, VerifyEmailScreen(flow: flow, showDialogOnOpen: false));
    expect(find.textContaining('Resend in'), findsOneWidget);
    expect(find.textContaining('1:00'), findsOneWidget);
    expect(find.text('Resend email'), findsNothing);
    // Forgot password sits in the password helper line.
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Email verified'), findsNothing);
  });

  testWidgets('at 0:00 the row becomes a tappable Resend email', (t) async {
    final flow = SignupFlow(role: AccountRole.founder)
      ..email = 'sara@gmail.com'
      ..password = 'Sara@1234'
      ..nextResendAt = DateTime.now().add(const Duration(seconds: 2));
    await _pump(t, VerifyEmailScreen(flow: flow, showDialogOnOpen: false));
    expect(find.textContaining('Resend in'), findsOneWidget);
    // Real time passes (the countdown follows the clock); then a tick.
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Resend in'), findsNothing);
    expect(find.textContaining('Resend email'), findsOneWidget);
    final auth = AuthRepository.instance as FakeAuthRepository;
    await t.tap(find.textContaining('Resend email'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(auth.resendCalls, 1);
    // The countdown restarts, and no toast is shown.
    expect(find.textContaining('1:00'), findsOneWidget);
    expect(find.text('Verification email sent'), findsNothing);
  });

  testWidgets('login: empty submit shows both errors', (t) async {
    await _pump(t, const LoginScreen());
    await t.tap(find.text('Log in').last);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Enter your password'), findsNWidgets(2)); // hint + error
    // The "fix the highlighted fields" pop-up shows, then goes away.
    expect(find.text('Please fix the highlighted fields'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('verify step opens with its dialog', (t) async {
    final flow = SignupFlow(role: AccountRole.founder)
      ..email = 'sara@gmail.com';
    await _pump(t, VerifyEmailScreen(flow: flow));
    await t.pump(const Duration(milliseconds: 500));
    // The dialog has one OK button; resending lives on the page itself.
    expect(find.text('Resend verification email'), findsNothing);
    expect(find.text('sara@gmail.com'), findsWidgets);
    await t.tap(find.text('OK'));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('STEP 2 OF 8'), findsOneWidget);
  });

  testWidgets('Continue before verifying says the email is not verified yet', (
    t,
  ) async {
    (AuthRepository.instance as FakeAuthRepository).logInFails =
        AuthFailure.emailNotVerified;
    final flow = SignupFlow(role: AccountRole.founder)
      ..email = 'sara@gmail.com';
    await _pump(t, VerifyEmailScreen(flow: flow, showDialogOnOpen: false));
    final fields = find.byType(TextField);
    await t.enterText(fields.at(1), 'Sara@1234');
    await t.tap(find.text('Continue'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Email not verified yet'), findsOneWidget);
    expect(find.text('Resend verification email'), findsNothing);
  });

  testWidgets('investor steps render and Next is gated', (t) async {
    await _pump(t, const InvestorInvestmentsScreen(user: _investor), w: 360);
    expect(find.text('STEP 3 OF 4'), findsOneWidget);
    await t.tap(find.text('1–5'));
    await t.pump(const Duration(milliseconds: 200));
    await t.tap(find.text('Next'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Please choose one.'), findsWidgets);
    expect(t.takeException(), isNull);
    await t.pump(const Duration(seconds: 3));

    final vm = InvestorOnboardingViewModel(user: _investor);
    addTearDown(vm.dispose);
    await _pump(t, InvestorInterestsScreen(viewModel: vm), w: 360);
    expect(find.text('STEP 4 OF 4'), findsOneWidget);
    await t.tap(find.text('Finish'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Select at least one sector.'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pump(const Duration(seconds: 3));
  });
}
