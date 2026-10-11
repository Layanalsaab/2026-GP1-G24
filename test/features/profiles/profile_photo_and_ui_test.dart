import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/account_strings.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/app_constants/program_strings.dart';
import 'package:startsa/app_constants/startup_strings.dart';
import 'package:startsa/data_access/device_services/profile_photo_picker_service.dart';
import 'package:startsa/data_access/mock_data/mock_investors.dart';
import 'package:startsa/data_access/mock_data/mock_programs.dart';
import 'package:startsa/data_access/mock_data/mock_startups.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/login_and_signup/screens/signup_screen.dart';
import 'package:startsa/features/profiles/screens/account_dialogs.dart';
import 'package:startsa/features/profiles/screens/account_screen.dart';
import 'package:startsa/features/profiles/screens/investor_profile_screen.dart';
import 'package:startsa/features/programs/screens/program_profile_screen.dart';
import 'package:startsa/features/startups/screens/startup_profile_screen.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';
import 'package:startsa/shared_ui/common_widgets/home_parts.dart';
import 'package:startsa/shared_ui/common_widgets/user_avatar.dart';

import '../../support/fakes.dart';

class _FakePhotoPicker implements ProfilePhotoPickerService {
  File? result = File('picked.jpg');
  ProfilePhotoFailure? fails;
  int calls = 0;

  @override
  Future<File?> pickSquarePhoto() async {
    calls++;
    if (fails != null) throw ProfilePhotoException(fails!);
    return result;
  }
}

void main() {
  late FakeAuthRepository auth;
  late FakeUserRepository users;
  late _FakePhotoPicker picker;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    auth = FakeAuthRepository();
    users = FakeUserRepository();
    picker = _FakePhotoPicker();
    AuthRepository.instance = auth;
    UserRepository.instance = users;
    ProfilePhotoPickerService.instance = picker;
  });

  tearDown(() {
    ProfilePhotoPickerService.instance = const ProfilePhotoPickerService();
  });

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  group('UserAvatar', () {
    Future<void> pumpAvatar(WidgetTester tester, UserAvatar avatar) =>
        tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Center(child: avatar))),
        );

    testWidgets('shows the initials when there is no photo', (tester) async {
      await pumpAvatar(
        tester,
        const UserAvatar(name: 'Khalid Al-Mansour', size: 48),
      );

      expect(find.text('KA'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a single name gives one letter, an empty one "?"', (
      tester,
    ) async {
      expect(UserAvatar.initialsOf('layan'), 'L');
      expect(UserAvatar.initialsOf('  '), '?');
    });

    testWidgets('falls back to the initials when the photo cannot load', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        const UserAvatar(
          name: 'Khalid Al-Mansour',
          photoUrl: 'https://photos.test/missing.jpg',
          size: 48,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('KA'), findsOneWidget);
    });
  });

  group('Create account photo', () {
    Future<void> openSignup(WidgetTester tester) async {
      bigScreen(tester);
      await tester.pumpWidget(
        const MaterialApp(home: SignupScreen(role: AccountRole.investor)),
      );
      await tester.pumpAndSettle();
    }

    Finder field(int i) => find.byType(TextField).at(i);

    Future<void> fill(WidgetTester tester) async {
      await tester.enterText(field(0), 'Mohammed Ahmed');
      await tester.enterText(field(1), 'name@example.com');
      await tester.enterText(field(2), '512345678');
      await tester.enterText(field(3), 'Startup1!');
      await tester.enterText(field(4), 'Startup1!');
      await tester.ensureVisible(find.text(AppStrings.cityHint));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.cityHint));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Riyadh');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, 'Riyadh'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Fintech'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fintech'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows "Add profile photo (optional)" at the top', (
      tester,
    ) async {
      await openSignup(tester);

      expect(
        find.textContaining(AccountStrings.addPhoto, findRichText: true),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    });

    testWidgets('sign-up without a photo works', (tester) async {
      await openSignup(tester);
      await fill(tester);

      await tester.tap(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();

      expect(auth.signUpCalls, 1);
      expect(auth.lastSignUpPhoto, isNull);
      expect(auth.lastSignUp?['phone'], '512345678');
      expect(auth.lastSignUp?['city'], 'Riyadh');
      expect(auth.lastSignUp?['sectors'], 'Fintech');
    });

    testWidgets('the chosen photo is sent with the sign-up', (tester) async {
      await openSignup(tester);
      await tester.tap(find.byIcon(Icons.photo_camera_outlined));
      await tester.pumpAndSettle();
      expect(picker.calls, 1);
      await fill(tester);

      await tester.tap(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();

      expect(auth.lastSignUpPhoto?.path, 'picked.jpg');
    });

    testWidgets('a photo that cannot be used shows a message only', (
      tester,
    ) async {
      picker.fails = ProfilePhotoFailure.tooLarge;
      await openSignup(tester);

      await tester.tap(find.byIcon(Icons.photo_camera_outlined));
      await tester.pumpAndSettle();

      expect(find.text(AccountStrings.photoTooLarge), findsOneWidget);
      await fill(tester);
      await tester.tap(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();
      expect(auth.signUpCalls, 1);
      expect(auth.lastSignUpPhoto, isNull);
    });
  });

  group('Edit profile photo', () {
    final founder = AppUser(
      uid: 'uid1',
      role: AccountRole.founder,
      fullName: 'Sara Alswailem',
      email: 'sara@example.com',
      city: 'Riyadh',
      phone: '512345678',
      sectorsOfInterest: const ['Fintech'],
      createdAt: DateTime(2026, 10, 3),
    );

    Future<void> openEdit(WidgetTester tester, AppUser user) async {
      bigScreen(tester);
      await tester.pumpWidget(MaterialApp(home: AccountScreen(user: user)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AccountStrings.editAccount));
      await tester.pumpAndSettle();
    }

    testWidgets('tapping the avatar picks a photo that Save uploads', (
      tester,
    ) async {
      await openEdit(tester, founder);

      await tester.tap(find.byIcon(Icons.photo_camera_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AccountStrings.save));
      await tester.pumpAndSettle();

      expect(users.photoUploads, ['uid1']);
      expect(find.text(AccountStrings.changesSaved), findsOneWidget);
    });

    testWidgets('a saved photo can be removed from the sheet', (tester) async {
      await openEdit(
        tester,
        founder.copyWith(photoUrl: 'https://photos.test/uid1.jpg'),
      );

      await tester.tap(find.byIcon(Icons.photo_camera_outlined));
      await tester.pumpAndSettle();
      expect(find.text(AccountStrings.removePhoto), findsOneWidget);
      await tester.tap(find.text(AccountStrings.removePhoto));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AccountStrings.save));
      await tester.pumpAndSettle();

      expect(users.photoRemovals, ['uid1']);
    });

    testWidgets('a failed upload keeps the form open with a message', (
      tester,
    ) async {
      users.photoFails = AuthFailure.network;
      await openEdit(tester, founder);

      await tester.tap(find.byIcon(Icons.photo_camera_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AccountStrings.save));
      await tester.pumpAndSettle();

      expect(find.text(AccountStrings.photoSaveFailed), findsOneWidget);
      expect(find.text(AccountStrings.save), findsOneWidget);
    });

    testWidgets('Profile shows the values saved at sign-up', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(MaterialApp(home: AccountScreen(user: founder)));
      await tester.pumpAndSettle();

      expect(find.text('Riyadh'), findsOneWidget);
      expect(find.text('Fintech'), findsOneWidget);
      expect(find.textContaining('51 234 5678'), findsOneWidget);
    });
  });

  group('Dialogs use the app font', () {
    testWidgets('the log-out dialog title and buttons are Inter', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showLogOutDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      for (final text in [AccountStrings.logOutTitle, AppStrings.logOut]) {
        final style = tester.widget<Text>(find.text(text)).style;
        expect(style?.fontFamily, startsWith('Inter'), reason: text);
      }
    });
  });

  group('Website is inert', () {
    testWidgets('the support system card button has no tap behaviour', (
      tester,
    ) async {
      var detailsOpened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SupportSystemCard(
              program: MockPrograms.taqadam,
              onViewDetails: () => detailsOpened++,
            ),
          ),
        ),
      );

      expect(find.text('Website'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Website'),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      await tester.tap(find.text('Website'));
      await tester.pump();
      expect(detailsOpened, 0);
      expect(find.byType(ProgramProfileScreen), findsNothing);

      // View details still works.
      await tester.tap(find.text('View details'));
      expect(detailsOpened, 1);
    });

    testWidgets('"Visit program website" does nothing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProgramProfileScreen(program: MockPrograms.taqadam),
        ),
      );
      await tester.pumpAndSettle();

      final label = find.text(ProgramStrings.visitWebsite);
      await tester.ensureVisible(label);
      expect(label, findsOneWidget);
      expect(
        find.ancestor(of: label, matching: find.byType(InkWell)),
        findsNothing,
      );
      await tester.tap(label);
      await tester.pumpAndSettle();
      expect(find.byType(ProgramProfileScreen), findsOneWidget);
    });
  });

  group('Investor profile', () {
    testWidgets('shows each sample investor correctly', (tester) async {
      bigScreen(tester);
      for (final i in MockInvestors.forYou) {
        await tester.pumpWidget(
          MaterialApp(home: InvestorProfileScreen(investor: i)),
        );
        await tester.pumpAndSettle();

        expect(find.text(i.name), findsOneWidget, reason: i.name);
        expect(find.text(i.initials), findsOneWidget, reason: i.name);
        expect(find.text('Investor'), findsOneWidget, reason: i.name);
        expect(find.text(i.profileBio), findsOneWidget, reason: i.name);
        expect(find.text(i.city), findsWidgets, reason: i.name);
        for (final sector in i.sectors) {
          expect(find.text(sector), findsWidgets, reason: i.name);
        }
        expect(find.text(i.ticketRange), findsOneWidget, reason: i.name);
        // Someone else's profile: no Edit profile, and no email / phone /
        // joined rows (sample investors have none).
        expect(find.text(AccountStrings.editAccount), findsNothing);
        expect(find.byIcon(Icons.mail_outline), findsNothing);
        expect(find.byIcon(Icons.phone_outlined), findsNothing);
        expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
        expect(find.text(StartupStrings.associationsTitle), findsOneWidget);
      }
    });

    testWidgets('lists the associated startups and opens them', (
      tester,
    ) async {
      bigScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: InvestorProfileScreen(investor: MockInvestors.sara),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('2 Associations', findRichText: true),
        findsOneWidget,
      );
      expect(find.text(MockStartups.daftar.name), findsOneWidget);
      expect(find.text(MockStartups.mizan.name), findsOneWidget);

      await tester.tap(find.text(MockStartups.daftar.name));
      await tester.pumpAndSettle();

      expect(find.byType(StartupProfileScreen), findsOneWidget);
    });
  });
}
