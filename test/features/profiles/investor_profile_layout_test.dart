import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/request_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/profiles/screens/account_screen.dart';
import 'package:startsa/features/profiles/screens/investor_profile_screen.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/investor_criteria.dart';
import 'package:startsa/models/investor_profile.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';

import '../../support/fakes.dart';

const _full = AppUser(
  uid: 'u2',
  role: AccountRole.investor,
  fullName: 'Layan Alsaab',
  email: 'layan@gmail.com',
  city: 'Riyadh',
  phone: '509876543',
  emailPublic: true,
  bio: 'Angel investor in the Kingdom.',
  valueOffered: 'Connections.',
  gain: 'Early access.',
  investorCriteria: InvestorCriteria(
    yearsInvesting: '4–6 years',
    dealsCount: '4–6',
    roundMin: 500000,
    roundMax: 1000000,
    hasLedRound: true,
    sectors: ['HealthTech', 'Other'],
    sectorsOther: 'SportsTech',
    stages: ['Seed'],
    commerceModels: ['Business-to-Business (B2B)', 'Other'],
    commerceModelsOther: 'Marketplace',
  ),
);

const _empty = AppUser(
  uid: 'u3',
  role: AccountRole.investor,
  fullName: 'Empty Investor',
  email: 'e@gmail.com',
);

Future<void> _pump(WidgetTester t, Widget screen, Size size) async {
  await t.binding.setSurfaceSize(size);
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(MaterialApp(theme: AppTheme.light, home: screen));
  await t.pump(const Duration(milliseconds: 1200));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    AppSession.instance = AppSession();
    BookmarkRepository.instance = BookmarkRepository();
    RequestRepository.instance = RequestRepository(sample: true);
    DiscoveryRepository.instance = DiscoveryRepository.sample();
    UserRepository.instance = FakeUserRepository()
      ..profiles['u2'] = _full
      ..profiles['u3'] = _empty;
    StartupRepository.instance = FakeStartupRepository();
  });

  for (final size in const [Size(412, 892), Size(360, 740)]) {
    group('${size.width.toInt()} px wide', () {
      testWidgets('own profile with full data', (t) async {
        AppSession.instance.signIn(_full);
        await _pump(t, const OwnProfileScreen(user: _full), size);
        expect(find.text('Investment Size'), findsOneWidget);
        expect(find.text('SAR 500K – 1M'), findsWidgets);
        expect(find.text('B2B'), findsWidgets);
        expect(find.text('What I can offer startups'), findsOneWidget);
        expect(find.text('What I’m looking for in startups'), findsOneWidget);
        expect(find.text('Investment Background'), findsOneWidget);
        expect(find.text('Years of investing'), findsOneWidget);
        expect(find.text('Round Size'), findsOneWidget);
        expect(find.text('Led a round'), findsOneWidget);
        expect(find.text('Yes'), findsOneWidget);
        expect(find.text('Investment Interests'), findsOneWidget);
        expect(find.text('SportsTech'), findsWidgets);
        expect(find.text('Marketplace'), findsOneWidget);
        expect(find.text('Investment Focus'), findsNothing);
        await t.scrollUntilVisible(
          find.text('Contact'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Public'), findsOneWidget);
        expect(find.text('Only you'), findsOneWidget);
      });

      testWidgets('own profile with no data does not crash', (t) async {
        AppSession.instance.signIn(_empty);
        await _pump(t, const OwnProfileScreen(user: _empty), size);
        expect(find.text('Empty Investor'), findsOneWidget);
        expect(find.text('Investment Size'), findsNothing);
        expect(find.text('Investment Background'), findsNothing);
        expect(find.text('Investment Interests'), findsNothing);
        expect(find.text('Contact'), findsOneWidget);
        expect(find.text('Only you'), findsNWidgets(2));
      });

      testWidgets('founder view of a sample investor', (t) async {
        AppSession.instance.signIn(
          const AppUser(
            uid: 'u1',
            role: AccountRole.founder,
            fullName: 'Shahad Alabdulkarim',
            email: 's@gmail.com',
          ),
        );
        await _pump(
          t,
          InvestorProfileScreen(investor: PrototypeSeed.ahmad),
          size,
        );
        expect(find.text('Investment Size'), findsOneWidget);
        expect(find.text('SAR 100K – 500K'), findsWidgets);
        expect(find.text('Investment Background'), findsOneWidget);
        expect(find.text('Investment Interests'), findsOneWidget);
        expect(find.text('Contact'), findsNothing);
        expect(find.text('Send investment request'), findsOneWidget);
      });

      testWidgets('founder sees only the contact the investor made public', (
        t,
      ) async {
        AppSession.instance.signIn(
          const AppUser(
            uid: 'u1',
            role: AccountRole.founder,
            fullName: 'Shahad Alabdulkarim',
            email: 's@gmail.com',
          ),
        );
        const open = InvestorProfile(
          id: 'open',
          name: 'Open Investor',
          title: 'Investor',
          city: 'Riyadh',
          sectors: ['Fintech'],
          stages: [],
          ticketRange: '',
          locations: [],
          email: 'open@gmail.com',
          emailPublic: true,
          phone: '501112222',
        );
        await _pump(t, const InvestorProfileScreen(investor: open), size);
        await t.scrollUntilVisible(
          find.text('Contact'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('open@gmail.com'), findsOneWidget);
        expect(find.text('Public'), findsOneWidget);
        expect(find.text('Only you'), findsNothing);
        expect(find.textContaining('501112222'), findsNothing);
      });

      testWidgets('founder view with an empty investor does not crash', (
        t,
      ) async {
        AppSession.instance.signIn(
          const AppUser(
            uid: 'u1',
            role: AccountRole.founder,
            fullName: 'Shahad Alabdulkarim',
            email: 's@gmail.com',
          ),
        );
        const bare = InvestorProfile(
          id: 'bare',
          name: 'Bare Investor',
          title: 'Investor',
          city: '',
          sectors: [],
          stages: [],
          ticketRange: '',
          locations: [],
        );
        await _pump(t, const InvestorProfileScreen(investor: bare), size);
        expect(find.text('Bare Investor'), findsOneWidget);
        expect(find.text('Investment Size'), findsNothing);
        expect(find.text('Investment Interests'), findsNothing);
      });
    });
  }
}
