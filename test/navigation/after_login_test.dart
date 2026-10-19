import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/login_and_signup/screens/verify_email_screen.dart';
import 'package:startsa/features/login_and_signup/screens/welcome_screen.dart';
import 'package:startsa/features/startups/screens/startup_steps_screen.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/navigation/app_router.dart';
import 'package:startsa/navigation/main_screen.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

import '../support/fakes.dart';

const _founder = AppUser(
  uid: 'u1',
  role: AccountRole.founder,
  fullName: 'Sara Alswailem',
  email: 'sara@gmail.com',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeStartupRepository startups;

  setUp(() {
    startups = FakeStartupRepository();
    StartupRepository.instance = startups;
    AuthRepository.instance = FakeAuthRepository();
    DiscoveryRepository.instance = DiscoveryRepository.sample();
    AppSession.instance.reset();
  });

  Future<void> logIn(WidgetTester t) async {
    t.view.physicalSize = const Size(412, 892);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: AppToast.navigatorKey,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => AppRouter.openAfterLogin(context, _founder),
            child: const Text('log in'),
          ),
        ),
      ),
    );
    await t.tap(find.text('log in'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
  }

  testWidgets(
    'a verified founder with no startup lands on "Add your startup"',
    (t) async {
      await logIn(t);
      expect(find.byType(StartupStepsScreen), findsOneWidget);
      expect(find.text('STEP 3 OF 6'), findsOneWidget);
      expect(
        find.byType(VerifyEmailScreen),
        findsNothing,
        reason: 'no second verification',
      );
      await t.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('a founder who already has a startup goes to Home', (t) async {
    startups.startups.add(PrototypeSeed.rafeeq);
    await logIn(t);
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byType(StartupStepsScreen), findsNothing);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('Back on that first step logs out to Welcome', (t) async {
    await logIn(t);
    await t.tap(find.bySemanticsLabel('Back').first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(AppSession.instance.user, isNull);
    await t.pump(const Duration(seconds: 3));
  });
}
