import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/shared_ui/common_widgets/form_message.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/app_constants/investor_strings.dart';
import 'package:startsa/app_constants/seeker_strings.dart';
import 'package:startsa/data_access/repositories/app_settings_repository.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/explore_startups/screens/seeker_explore_screen.dart';
import 'package:startsa/main.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';
import 'package:startsa/navigation/main_screen.dart';

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
    StartupRepository.instance = FakeStartupRepository();
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
    String phone = '512345678',
    String password = 'Startup1!',
    String confirm = 'Startup1!',
    bool pickCityAndSector = true,
  }) async {
    await tester.enterText(field(0), name);
    await tester.enterText(field(1), email);
    await tester.enterText(field(2), phone);
    await tester.enterText(field(3), password);
    await tester.enterText(field(4), confirm);
    if (!pickCityAndSector) return;

    await tester.ensureVisible(find.text(AppStrings.cityHint));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.cityHint));
    await tester.pumpAndSettle();
    // Riyadh is far down the list, so find it with the search field.
    await tester.enterText(find.byType(TextField).last, 'Riyadh');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'Riyadh'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Fintech'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fintech'));
    await tester.pumpAndSettle();
  }

  Future<void> openSignupAs(WidgetTester tester, {String role = 'Founder'}) async {
    await goToWelcome(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your role'), findsOneWidget);
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

      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('a restored session goes straight to the role home', (tester) async {
      repo.sessionUser = repo.onboardedFounder;
      await pumpApp(tester);

      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.text('Mohammed Ahmed'), findsOneWidget); // on the Account tab
      expect(find.textContaining('Where Saudi startups'), findsNothing);
    });

    testWidgets('log out signs out and clears the history', (tester) async {
      repo.sessionUser = repo.onboardedFounder;
      await pumpApp(tester);

      // Account tab -> Log out -> confirm in the dialog.
      await tester.ensureVisible(find.text(AppStrings.logOut));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logOut));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logOut).last);
      await tester.pumpAndSettle();

      expect(repo.signOutCalls, 1);
      expect(find.text('Create account'), findsOneWidget);

      // Back must not return to the logged-in screen.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
    });
  });

  group('roles', () {
    testWidgets('a guest goes to the seeker Explore, not the sign-up form', (tester) async {
      await goToWelcome(tester);
      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();

      expect(find.byType(SeekerExploreScreen), findsOneWidget);
      expect(find.text(AppStrings.signupTitle), findsNothing);
    });

    testWidgets('Back from Choose role returns to Log in when it came from there', (tester) async {
      await goToWelcome(tester);
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(AppStrings.signupLink));
      await tester.pumpAndSettle();
      expect(find.text('Choose your role'), findsOneWidget);

      await tester.tap(find.byType(InkResponse).first); // the top-bar back arrow
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    });

    testWidgets('a seeker who switches role can go Back from Choose role', (tester) async {
      await goToWelcome(tester);
      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(SeekerStrings.switchRole));
      await tester.pumpAndSettle();
      await tester.tap(find.text(SeekerStrings.exitConfirm).last);
      await tester.pumpAndSettle();
      expect(find.text('Choose your role'), findsOneWidget);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isTrue);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('Create account'), findsOneWidget); // Welcome
    });

    testWidgets('choose role offers only Founder and Investor', (tester) async {
      await goToWelcome(tester);
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Founder'), findsOneWidget);
      expect(find.text('Investor'), findsOneWidget);
      expect(find.text('Startup Seeker'), findsNothing);
    });

    testWidgets('an investor sees the sign-up form', (tester) async {
      await openSignupAs(tester, role: 'Investor');

      expect(find.text(AppStrings.signupTitle), findsOneWidget);
    });
  });

  group('sign up', () {
    testWidgets('shows every error at once and sends nothing', (tester) async {
      await openSignupAs(tester);
      await fillSignup(
        tester,
        name: '',
        email: 'bad',
        phone: '123',
        password: 'abc',
        confirm: 'xyz',
        pickCityAndSector: false,
      );

      await tester.tap(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();

      // Each field shows its unmet rules, and the missing choices say so.
      expect(find.text(AppStrings.ruleNameLength), findsOneWidget);
      expect(find.text(AppStrings.ruleEmailAt), findsOneWidget);
      expect(find.text(AppStrings.rulePhoneStart), findsOneWidget);
      expect(find.text(AppStrings.rulePasswordLength), findsOneWidget);
      expect(find.text(AppStrings.ruleConfirmMatches), findsOneWidget);
      expect(find.text(AppStrings.cityRequired), findsOneWidget);
      expect(find.text(AppStrings.sectorsRequired), findsOneWidget);
      expect(repo.signUpCalls, 0);
    });

    testWidgets('the city picker lists every city and can be searched', (tester) async {
      await openSignupAs(tester);
      await tester.ensureVisible(find.text(AppStrings.cityHint));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.cityHint));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.citySheetTitle), findsWidgets);
      expect(find.text(AppStrings.citySearchHint), findsOneWidget);
      expect(find.text('Abha'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'jed');
      await tester.pumpAndSettle();
      expect(find.text('Jeddah'), findsOneWidget);
      expect(find.text('Abha'), findsNothing);

      await tester.enterText(find.byType(TextField).last, 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.cityNoResults), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'jed');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jeddah'));
      await tester.pumpAndSettle();

      expect(find.text('Jeddah'), findsOneWidget); // now shown in the field
      expect(find.text(AppStrings.cityHint), findsNothing);
    });

    testWidgets('Create account has no yellow progress lines for founders or investors', (tester) async {
      Finder goldBars() => find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color == AppColors.gold,
          );

      await openSignupAs(tester, role: 'Founder');
      expect(find.text(AppStrings.signupTitle), findsOneWidget);
      expect(goldBars(), findsNothing);

      // Same screen for an investor.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Investor'));
      await tester.tap(find.text('Investor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.signupTitle), findsOneWidget);
      expect(goldBars(), findsNothing);
    });

    testWidgets('password rules turn from red to green as they are met', (tester) async {
      await openSignupAs(tester);
      await tester.enterText(field(3), 'abc');
      await tester.pump();

      Color colorOf(String label) =>
          tester.widget<Text>(find.text(label)).style!.color!;
      expect(colorOf(AppStrings.rulePasswordLength), AppColors.error);
      expect(colorOf(AppStrings.rulePasswordLower), AppColors.moss600);

      await tester.enterText(field(3), 'Abcdefg1!');
      await tester.pump();

      for (final rule in [
        AppStrings.rulePasswordLength,
        AppStrings.rulePasswordUpper,
        AppStrings.rulePasswordLower,
        AppStrings.rulePasswordNumber,
        AppStrings.rulePasswordSpecial,
      ]) {
        expect(colorOf(rule), AppColors.moss600, reason: rule);
      }
    });

    testWidgets('valid sign up lands on Log in with the Verify your email pop-up', (tester) async {
      await openSignupAs(tester);
      await fillSignup(tester);

      await tester.tap(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();

      expect(repo.signUpCalls, 1);
      expect(find.text(AppStrings.loginTitle), findsOneWidget); // behind the pop-up
      expect(find.text(AppStrings.verifyEmailTitle), findsOneWidget);
      expect(find.textContaining('name@example.com', findRichText: true), findsWidgets);
      expect(find.text(AppStrings.verifyEmailSpamHint), findsOneWidget);
      expect(find.text(AppStrings.resendVerification), findsOneWidget);
      expect(find.text(AppStrings.verifyEmailOk), findsOneWidget);
      // The new account is already filled in on the Log in form.
      expect(
        tester.widget<TextField>(field(0)).controller!.text,
        'name@example.com',
      );
    });

    testWidgets('duplicate email is reported under the email field', (tester) async {
      repo.signUpFails = AuthFailure.emailInUse;
      await openSignupAs(tester);
      await fillSignup(tester);

      await tester.tap(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.emailInUse), findsOneWidget);
      expect(find.text(AppStrings.verifyEmailTitle), findsNothing);
    });

    testWidgets('logging in before verifying shows the pop-up again with a reminder', (tester) async {
      await openSignupAs(tester);
      await fillSignup(tester);
      await tester.tap(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.verifyEmailTitle), findsOneWidget); // first time

      await tester.tap(find.text(AppStrings.verifyEmailOk));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.verifyEmailTitle), findsNothing);

      // Still not verified: the account is the same, so log in is refused.
      repo.logInFails = AuthFailure.emailNotVerified;
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.verifyEmailReminderTitle), findsOneWidget);
      expect(find.text(AppStrings.verifyEmailTitle), findsNothing);
      expect(find.text(AppStrings.resendVerification), findsOneWidget);
    });

    testWidgets('resend and OK work from the Verify your email pop-up', (tester) async {
      await openSignupAs(tester);
      await fillSignup(tester);
      await tester.tap(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.resendVerification));
      await tester.pumpAndSettle();
      expect(repo.resendCalls, 1);
      expect(find.text(AppStrings.verificationSent), findsOneWidget);

      await tester.tap(find.text(AppStrings.verifyEmailOk));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.verifyEmailTitle), findsNothing);
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

    testWidgets('"Forgot password?" lines up with the left edge of the fields', (tester) async {
      await openLogin(tester);

      final fieldLeft = tester.getTopLeft(find.byType(TextField).first).dx;
      final linkLeft =
          tester.getTopLeft(find.text(AppStrings.forgotPasswordLink)).dx;

      expect(linkLeft, fieldLeft);
    });

    testWidgets('a founder who finished onboarding goes to their home', (tester) async {
      repo.loggedInUser = repo.onboardedFounder;
      await openLogin(tester);
      await tester.enterText(field(0), 'name@example.com');
      await tester.enterText(field(1), 'Startup1');

      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('a new founder goes straight to their home, with no onboarding page', (tester) async {
      await openLogin(tester);
      await tester.enterText(field(0), 'name@example.com');
      await tester.enterText(field(1), 'Startup1');
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.text('What sector is your startup in?'), findsNothing);
    });

    testWidgets('a new investor goes straight to their home, with no onboarding page',
        (tester) async {
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

      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.text(InvestorStrings.sectorsTitle), findsNothing);
    });

    testWidgets('an investor who finished onboarding goes straight to their home',
        (tester) async {
      repo.loggedInUser = const AppUser(
        uid: 'uid2',
        role: AccountRole.investor,
        fullName: 'Sara',
        email: 's@b.co',
        onboardingCompleted: true,
      );
      await openLogin(tester);
      await tester.enterText(field(0), 's@b.co');
      await tester.enterText(field(1), 'Startup1');

      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.text(InvestorStrings.sectorsTitle), findsNothing);
    });

    testWidgets('wrong or missing details show one generic message', (tester) async {
      await openLogin(tester);

      await tester.tap(find.text(AppStrings.loginButton)); // nothing typed
      await tester.pumpAndSettle();
      // The hint has the same words, so look for the error message widget.
      expect(
        find.widgetWithText(FormMessage, AppStrings.loginPasswordRequired),
        findsOneWidget,
      );
      expect(find.text(AppStrings.ruleEmailAt), findsOneWidget);
      expect(repo.logInCalls, 0);

      repo.logInFails = AuthFailure.invalidCredentials;
      await tester.enterText(field(0), 'name@example.com');
      await tester.enterText(field(1), 'WrongPass1');
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.incorrectCredentials), findsOneWidget);
      expect(find.byType(MainScreen), findsNothing);
    });

    testWidgets('unverified email opens the Verify your email pop-up and stays out of the app', (tester) async {
      repo.logInFails = AuthFailure.emailNotVerified;
      await openLogin(tester);
      await tester.enterText(field(0), 'name@example.com');
      await tester.enterText(field(1), 'Startup1');

      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.verifyEmailReminderTitle), findsOneWidget);
      expect(find.byType(MainScreen), findsNothing);

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
      // The top-bar arrow is the only way back (no "Back to log in" link).
      expect(find.text('Back to log in'), findsNothing);
    }

    Future<void> send(WidgetTester tester, String email) async {
      await tester.enterText(field(0), email);
      await tester.tap(find.text(AppStrings.forgotButton));
      await tester.pumpAndSettle();
    }

    testWidgets('invalid email format shows an error', (tester) async {
      await openForgot(tester);

      await send(tester, 'not-an-email');

      expect(find.text(AppStrings.ruleEmailAt), findsOneWidget);
      expect(find.text(AppStrings.ruleEmailDomain), findsOneWidget);
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
