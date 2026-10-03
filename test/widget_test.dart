import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/data_access/repositories/app_settings_repository.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/main.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';

import 'support/fakes.dart';

void main() {
  late FakeAuthRepository repo;
  late FakeUserRepository users;
  late FakeAppSettingsRepository settings;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    repo = FakeAuthRepository();
    users = FakeUserRepository();
    AuthRepository.instance = repo;
    UserRepository.instance = users;
    settings = FakeAppSettingsRepository();
    AppSettingsRepository.instance = settings;
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const StartSaApp());
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
  }

  /// Splash -> intro 1 -> Skip -> Welcome.
  Future<void> goToWelcome(WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.textContaining('Where Saudi startups'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);
  }

  Finder field(int index) => find.byType(TextField).at(index);

  Future<void> fillSignup(
    WidgetTester tester, {
    String name = 'Mohammed Ahmed',
    String email = 'name@example.com',
    String password = 'Startup1',
    String confirm = 'Startup1',
  }) async {
    await tester.enterText(field(0), name);
    await tester.enterText(field(1), email);
    await tester.enterText(field(2), password);
    await tester.enterText(field(3), confirm);
  }

  Future<void> openSignupAs(WidgetTester tester, {String role = 'Founder'}) async {
    await goToWelcome(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('I am a...'), findsOneWidget);
    if (role != 'Founder') {
      await tester.ensureVisible(find.text(role)); // lower cards scroll into view
      await tester.pumpAndSettle();
      await tester.tap(find.text(role));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  group('first launch', () {
    testWidgets('no session: splash, intro, welcome', (tester) async {
      await goToWelcome(tester);
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('the intros are remembered once finished', (tester) async {
      expect(settings.introSeen, isFalse);
      await goToWelcome(tester); // skips the intros
      expect(settings.introSeen, isTrue);
    });

    testWidgets('finishing the last intro also remembers it', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byType(GestureDetector).last); // intro 1 -> next
      await tester.pumpAndSettle();
      await tester.tap(find.byType(GestureDetector).last); // intro 2 -> next
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);

      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(settings.introSeen, isTrue);
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('a returning visitor who is logged out skips the intros', (tester) async {
      settings.introSeen = true;
      await pumpApp(tester);

      expect(find.textContaining('Where Saudi startups'), findsNothing);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('a logged-in user skips the intros even on a first install', (tester) async {
      repo.sessionUser = repo.onboardedFounder;
      await pumpApp(tester);

      expect(find.text(AppStrings.founderHomeTitle), findsOneWidget);
    });

    testWidgets('a restored session goes straight to the role home', (tester) async {
      repo.sessionUser = repo.onboardedFounder;
      await pumpApp(tester);

      expect(find.text(AppStrings.founderHomeTitle), findsOneWidget);
      expect(find.text('Welcome, Mohammed Ahmed'), findsOneWidget);
      expect(find.textContaining('Where Saudi startups'), findsNothing);
    });

    testWidgets('log out signs out and clears the history', (tester) async {
      repo.sessionUser = repo.onboardedFounder;
      await pumpApp(tester);

      await tester.tap(find.text(AppStrings.logOut));
      await tester.pumpAndSettle();

      expect(repo.signOutCalls, 1);
      expect(find.text('Create account'), findsOneWidget);

      // Back must not return to the logged-in screen.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
    });
  });

  group('roles', () {
    testWidgets('a seeker goes to guest explore, not the sign-up form', (tester) async {
      await openSignupAs(tester, role: 'Startup Seeker');

      expect(find.text(AppStrings.seekerExploreTitle), findsOneWidget);
      expect(find.text(AppStrings.signupTitle), findsNothing);
    });

    testWidgets('an investor sees the investor sign-up', (tester) async {
      await openSignupAs(tester, role: 'Investor');

      expect(find.text(AppStrings.signupSubtitle('Investor')), findsOneWidget);
    });
  });

  group('sign up', () {
    testWidgets('shows every error at once and sends nothing', (tester) async {
      await openSignupAs(tester);
      await fillSignup(tester, name: '', email: 'bad', password: 'abc', confirm: 'xyz');

      await tester.tap(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.fullNameRequired), findsOneWidget);
      expect(find.text(AppStrings.emailInvalid), findsOneWidget);
      expect(find.text(AppStrings.passwordTooShort), findsOneWidget);
      expect(find.text(AppStrings.passwordsDontMatch), findsOneWidget);
      expect(repo.signUpCalls, 0);
    });

    testWidgets('valid sign up lands on Check your email', (tester) async {
      await openSignupAs(tester);
      await fillSignup(tester);

      await tester.tap(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();

      expect(repo.signUpCalls, 1);
      expect(find.text(AppStrings.checkEmailTitle), findsOneWidget);
      expect(find.textContaining('name@example.com'), findsOneWidget);
      expect(find.text(AppStrings.resendVerification), findsOneWidget);
    });

    testWidgets('duplicate email is reported under the email field', (tester) async {
      repo.signUpFails = AuthFailure.emailInUse;
      await openSignupAs(tester);
      await fillSignup(tester);

      await tester.tap(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.emailInUse), findsOneWidget);
      expect(find.text(AppStrings.checkEmailTitle), findsNothing);
    });

    testWidgets('resend and back to log in work from Check your email', (tester) async {
      await openSignupAs(tester);
      await fillSignup(tester);
      await tester.tap(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.resendVerification));
      await tester.pumpAndSettle();
      expect(repo.resendCalls, 1);
      expect(find.text(AppStrings.verificationSent), findsOneWidget);

      await tester.tap(find.text(AppStrings.backToLogin));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    });
  });

  group('log in', () {
    Future<void> openLogin(WidgetTester tester) async {
      await goToWelcome(tester);
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    }

    testWidgets('a founder who finished onboarding goes to their home', (tester) async {
      repo.loggedInUser = repo.onboardedFounder;
      await openLogin(tester);
      await tester.enterText(field(0), 'name@example.com');
      await tester.enterText(field(1), 'Startup1');

      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.founderHomeTitle), findsOneWidget);
      expect(find.text(AppStrings.onboardingSectorTitle), findsNothing);
    });

    testWidgets('a new founder sees the onboarding first, then their home', (tester) async {
      await openLogin(tester);
      await tester.enterText(field(0), 'name@example.com');
      await tester.enterText(field(1), 'Startup1');
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboardingSectorTitle), findsOneWidget);
      expect(find.text(AppStrings.founderHomeTitle), findsNothing);

      // Continuing without answers is refused.
      await tester.tap(find.text(AppStrings.onboardingContinue));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.onboardingIncomplete), findsOneWidget);
      expect(users.onboardingSaves, 0);

      await tester.tap(find.text('Fintech'));
      await tester.tap(find.text('Seed'));
      await tester.ensureVisible(find.text('Jeddah'));
      await tester.tap(find.text('Jeddah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.onboardingContinue));
      await tester.pumpAndSettle();

      expect(users.savedOnboarding, {'sector': 'Fintech', 'stage': 'Seed', 'city': 'Jeddah'});
      expect(find.text(AppStrings.founderHomeTitle), findsOneWidget);
    });

    testWidgets('an investor skips founder onboarding', (tester) async {
      repo.loggedInUser = const AppUser(
        uid: 'uid2',
        role: AccountRole.investor,
        fullName: 'Sara',
        email: 's@b.co',
      );
      await openLogin(tester);
      await tester.enterText(field(0), 's@b.co');
      await tester.enterText(field(1), 'Startup1');

      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.investorHomeTitle), findsOneWidget);
    });

    testWidgets('wrong or missing details show one generic message', (tester) async {
      await openLogin(tester);

      await tester.tap(find.text(AppStrings.loginButton)); // nothing typed
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.incorrectCredentials), findsOneWidget);

      repo.logInFails = AuthFailure.invalidCredentials;
      await tester.enterText(field(0), 'name@example.com');
      await tester.enterText(field(1), 'WrongPass1');
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.incorrectCredentials), findsOneWidget);
      expect(find.text(AppStrings.founderHomeTitle), findsNothing);
    });

    testWidgets('unverified email offers a resend and stays out of the app', (tester) async {
      repo.logInFails = AuthFailure.emailNotVerified;
      await openLogin(tester);
      await tester.enterText(field(0), 'name@example.com');
      await tester.enterText(field(1), 'Startup1');

      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.verifyEmailFirst), findsOneWidget);
      expect(find.text(AppStrings.founderHomeTitle), findsNothing);

      await tester.tap(find.text(AppStrings.resendVerification));
      await tester.pumpAndSettle();
      expect(repo.resendCalls, 1);
      expect(find.text(AppStrings.verificationSent), findsOneWidget);
    });
  });

  group('forgot password', () {
    Future<void> openForgot(WidgetTester tester) async {
      await goToWelcome(tester);
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.forgotPasswordLink));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.forgotTitle), findsOneWidget);
    }

    Future<void> send(WidgetTester tester, String email) async {
      await tester.enterText(field(0), email);
      await tester.tap(find.text(AppStrings.forgotButton));
      await tester.pumpAndSettle();
    }

    testWidgets('invalid email format shows an error', (tester) async {
      await openForgot(tester);

      await send(tester, 'not-an-email');

      expect(find.text(AppStrings.emailInvalid), findsOneWidget);
      expect(repo.resetCalls, 0);
    });

    testWidgets('any valid email gets the same confirmation', (tester) async {
      await openForgot(tester);

      await send(tester, 'anyone@example.com');
      expect(find.text(AppStrings.resetLinkMessage), findsOneWidget);
      expect(repo.resetCalls, 1);

      await send(tester, 'someone.else@example.com');
      expect(find.text(AppStrings.resetLinkMessage), findsOneWidget);
      expect(repo.resetCalls, 2);
    });
  });
}
