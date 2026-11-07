import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/request_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/profiles/screens/account_screen.dart';
import 'package:startsa/features/profiles/screens/investor_profile_screen.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/investor_profile.dart';
import 'package:startsa/shared_ui/icons/app_icons.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';

import '../../support/fakes.dart';

Future<void> _pump(WidgetTester t, Widget screen) async {
  await t.binding.setSurfaceSize(const Size(412, 892));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(MaterialApp(theme: AppTheme.light, home: screen));
  await t.pump(const Duration(milliseconds: 1200));
}

Future<void> _toContact(WidgetTester t) => t.scrollUntilVisible(
  find.text('Contact Information'),
  300,
  scrollable: find.byType(Scrollable).first,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const founder = AppUser(
    uid: 'f1',
    role: AccountRole.founder,
    fullName: 'Shahad Alabdulkarim',
    email: 'shahad@gmail.com',
    phone: '501234567',
    phonePublic: true,
    bio: 'Founder of a health startup.',
  );

  const investor = AppUser(
    uid: 'i1',
    role: AccountRole.investor,
    fullName: 'Layan Alsaab',
    email: 'layan@gmail.com',
    phone: '509876543',
    emailPublic: true,
    phonePublic: true,
    bio: 'Angel investor in the Kingdom.',
  );

  setUp(() {
    AppSession.instance = AppSession();
    BookmarkRepository.instance = BookmarkRepository();
    RequestRepository.instance = RequestRepository(sample: true);
    DiscoveryRepository.instance = DiscoveryRepository.sample();
    UserRepository.instance = FakeUserRepository()
      ..profiles['f1'] = founder
      ..profiles['i1'] = investor;
    StartupRepository.instance = FakeStartupRepository();
  });

  testWidgets('a founder\'s own profile: intro, both rows and their notes', (
    t,
  ) async {
    AppSession.instance.signIn(founder);
    await _pump(t, const OwnProfileScreen(user: founder));
    await _toContact(t);
    expect(
      find.text('Only the details marked Public are shown to others.'),
      findsOneWidget,
    );
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    // The email is private, the phone is public.
    expect(find.text('Private. Only you can see your email'), findsOneWidget);
    expect(find.text('Shown on your profile'), findsOneWidget);
    expect(find.text('Only you'), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
  });

  testWidgets('an investor\'s own profile with both public', (t) async {
    AppSession.instance.signIn(investor);
    await _pump(t, const OwnProfileScreen(user: investor));
    await _toContact(t);
    expect(find.text('Shown on your profile'), findsNWidgets(2));
    expect(find.text('Public'), findsNWidgets(2));
    expect(find.textContaining('Private. Only you'), findsNothing);
  });

  testWidgets('someone else\'s investor: public values, no notes, no intro', (
    t,
  ) async {
    AppSession.instance.signIn(founder);
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
      phonePublic: true,
    );
    await _pump(t, const InvestorProfileScreen(investor: open));
    await _toContact(t);
    expect(find.text('open@gmail.com'), findsOneWidget);
    expect(find.textContaining('+966'), findsOneWidget);
    expect(find.text('Email is private'), findsNothing);
    expect(find.text('Phone is private'), findsNothing);
    expect(find.text('Private'), findsNothing);
    expect(find.text('Shown on your profile'), findsNothing);
    expect(
      find.text('Only the details marked Public are shown to others.'),
      findsNothing,
    );
  });

  testWidgets(
    'someone else\'s investor: both private, a lock each, no values',
    (t) async {
      AppSession.instance.signIn(founder);
      const closed = InvestorProfile(
        id: 'closed',
        name: 'Closed Investor',
        title: 'Investor',
        city: 'Riyadh',
        sectors: ['Fintech'],
        stages: [],
        ticketRange: '',
        locations: [],
        email: 'secret@gmail.com',
        phone: '501112222',
      );
      await _pump(t, const InvestorProfileScreen(investor: closed));
      await _toContact(t);
      expect(find.text('Email is private'), findsOneWidget);
      expect(find.text('Phone is private'), findsOneWidget);
      expect(find.text('Private'), findsNWidgets(2));
      expect(
        find.byWidgetPredicate((w) => w is AppIcon && w.path == AppIcons.lock),
        findsNWidgets(2),
      );
      // The value is never in the page.
      expect(find.textContaining('secret@gmail.com'), findsNothing);
      expect(find.textContaining('501112222'), findsNothing);
      // A public flag with no value is still shown as private.
      const noValue = InvestorProfile(
        id: 'nv',
        name: 'No Value',
        title: 'Investor',
        city: 'Riyadh',
        sectors: ['Fintech'],
        stages: [],
        ticketRange: '',
        locations: [],
        emailPublic: true,
      );
      await _pump(t, const InvestorProfileScreen(investor: noValue));
      await _toContact(t);
      expect(find.text('Email is private'), findsOneWidget);
    },
  );

  testWidgets('no "Invests in" line, on either profile', (t) async {
    AppSession.instance.signIn(investor);
    await _pump(t, const OwnProfileScreen(user: investor));
    expect(find.textContaining('Invests in', findRichText: true), findsNothing);
    AppSession.instance.signIn(founder);
    const other = InvestorProfile(
      id: 'o',
      name: 'Other Investor',
      title: 'Investor',
      city: 'Riyadh',
      sectors: ['Fintech', 'HealthTech'],
      stages: ['Seed'],
      ticketRange: 'SAR 100K – 500K',
      locations: [],
    );
    await _pump(t, const InvestorProfileScreen(investor: other));
    expect(find.textContaining('Invests in', findRichText: true), findsNothing);
    // The sectors are still on the page, under Interests.
    expect(find.text('Investment Interests'), findsOneWidget);
  });

  testWidgets('the content sits indented under the bold heading', (t) async {
    AppSession.instance.signIn(investor);
    await _pump(t, const OwnProfileScreen(user: investor));
    final heading = t.getTopLeft(find.text('About')).dx;
    final content = t
        .getTopLeft(find.text('Angel investor in the Kingdom.'))
        .dx;
    expect(content - heading, closeTo(12, 0.5));
    final text = t.widget<Text>(find.text('About'));
    expect(text.style!.fontWeight, FontWeight.w700);
  });
}
