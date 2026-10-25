import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/request_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/profiles/screens/edit_account_screen.dart';
import 'package:startsa/features/profiles/screens/investor_profile_screen.dart';
import 'package:startsa/features/program_details/screens/program_details_screen.dart';
import 'package:startsa/features/startup_profile/screens/startup_profile_screen.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/headers/tabbed_header.dart';

import '../../support/fakes.dart';

const _founder = AppUser(
  uid: 'u1',
  role: AccountRole.founder,
  fullName: 'Shahad Alabdulkarim',
  email: 'shahad@gmail.com',
  city: 'Riyadh',
  phone: '551234567',
  bio: 'Building Rafeeq Health.',
  sectorsOfInterest: ['HealthTech', 'Fintech'],
  linkedin: 'linkedin.com/in/shahad',
);

const _investor = AppUser(
  uid: 'u2',
  role: AccountRole.investor,
  fullName: 'Layan Alsaab',
  email: 'layan@gmail.com',
  city: 'Riyadh',
  phone: '509876543',
  sectorsOfInterest: ['HealthTech'],
  valueOffered: 'Connections.',
  gain: 'Early access.',
);

Future<void> _pump(
  WidgetTester t,
  Widget screen, {
  Size size = const Size(412, 892),
}) async {
  await t.binding.setSurfaceSize(size);
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(MaterialApp(theme: AppTheme.light, home: screen));
  await t.pump(const Duration(milliseconds: 800));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    AppSession.instance = AppSession();
    BookmarkRepository.instance = BookmarkRepository();
    RequestRepository.instance = RequestRepository(sample: true);
    DiscoveryRepository.instance = DiscoveryRepository.sample();
    UserRepository.instance = FakeUserRepository()
      ..profiles['u1'] = _founder
      ..profiles['u2'] = _investor;
    StartupRepository.instance = FakeStartupRepository()
      ..startups.add(PrototypeSeed.rafeeq);
  });

  for (final size in const [Size(412, 892), Size(360, 740)]) {
    group('${size.width.toInt()} px wide', () {
      testWidgets('startup profile: tabs, request toggle', (t) async {
        AppSession.instance.signIn(_investor);
        await _pump(
          t,
          StartupProfileScreen(startup: PrototypeSeed.rafeeq),
          size: size,
        );
        expect(find.text('Rafeeq Health'), findsWidgets);
        expect(find.text('About'), findsOneWidget);
        expect(find.text('Send investment request'), findsOneWidget);

        // The four tabs (a "Funding" row also exists inside the Overview).
        Finder tab(String label) => find.descendant(
          of: find.byType(ScrollableHeaderTabBar),
          matching: find.text(label),
        );
        for (final name in ['Business', 'Team', 'Funding', 'Overview']) {
          await t.tap(tab(name));
          await t.pump(const Duration(milliseconds: 500));
        }
        await t.tap(tab('Funding'));
        await t.pump(const Duration(milliseconds: 500));
        expect(find.text('Funding rounds'), findsOneWidget);
        expect(find.text('Expected revenue'), findsOneWidget);

        await t.tap(find.text('Send investment request'));
        await t.pump(const Duration(milliseconds: 400));
        // Requests are not built yet: nothing happens and nothing is shown.
        expect(find.text('Request sent'), findsNothing);
        expect(find.text('Request sent to Rafeeq Health'), findsNothing);
        expect(find.text('Send investment request'), findsOneWidget);
      });

      testWidgets('investor profile', (t) async {
        AppSession.instance.signIn(_founder);
        await _pump(
          t,
          InvestorProfileScreen(investor: PrototypeSeed.layan),
          size: size,
        );
        expect(find.text('Layan Alsaab'), findsOneWidget);
        expect(
          find.textContaining('Invests in', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Investment Background'), findsOneWidget);
        expect(find.text('Send investment request'), findsOneWidget);
      });

      testWidgets('program details', (t) async {
        AppSession.instance.signInAsGuest();
        await _pump(
          t,
          ProgramDetailsScreen(program: PrototypeSeed.programs.first),
          size: size,
        );
        expect(find.text('Visit website'), findsOneWidget);
        expect(find.text('Focus sectors'), findsOneWidget);
        expect(find.text('Running since'), findsOneWidget);
        await t.pump(const Duration(seconds: 2));
      });

      testWidgets('founder edit profile: field order and no sectors sub-line', (
        t,
      ) async {
        AppSession.instance.signIn(_founder);
        await _pump(t, const EditProfileScreen(user: _founder), size: size);
        double y(String label) => t
            .getTopLeft(find.textContaining(label, findRichText: true).first)
            .dy;
        final order = [
          y('Full Name'),
          y('Bio'),
          y('Email Address'),
          y('Phone Number'),
          y('LinkedIn'),
          y('Which city'),
          y('Which sectors'),
        ];
        final sorted = [...order]..sort();
        expect(order, sorted);
        expect(find.textContaining('Select all that apply'), findsNothing);
        expect(find.textContaining('Password'), findsNothing);
      });

      testWidgets('edit profile shows errors and the fix toast', (t) async {
        AppSession.instance.signIn(_founder);
        await _pump(t, const EditProfileScreen(user: _founder), size: size);
        expect(find.text('Edit profile'), findsOneWidget);
        await t.enterText(find.byType(TextField).first, 'Shahad');
        await t.tap(find.text('Save'));
        await t.pump(const Duration(milliseconds: 400));
        expect(find.text('Enter your first and last name.'), findsOneWidget);
        expect(find.text('Please fix the highlighted fields'), findsOneWidget);
        await t.pump(const Duration(seconds: 4));
      });
    });
  }
}
