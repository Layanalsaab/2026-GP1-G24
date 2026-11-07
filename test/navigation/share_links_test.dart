import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/profiles/screens/investor_profile_screen.dart';
import 'package:startsa/features/startup_profile/screens/startup_profile_screen.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/navigation/main_screen.dart';
import 'package:startsa/navigation/share_links.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

import '../support/fakes.dart';

const _site = 'https://startsa-ea49e.web.app';

const _founder = AppUser(
  uid: 'u1',
  role: AccountRole.founder,
  fullName: 'Sara Alswailem',
  email: 'sara@gmail.com',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('ShareLinks.parse', () {
    test('a startup and an investor link', () {
      final s = ShareLinks.parse(Uri.parse('$_site/startup/abc123'));
      expect(s?.kind, ShareTarget.startup);
      expect(s?.id, 'abc123');
      final i = ShareLinks.parse(Uri.parse('$_site/investor/xyz/'));
      expect(i?.kind, ShareTarget.investor);
      expect(i?.id, 'xyz');
    });

    test('anything else is not a share link', () {
      for (final other in [
        '$_site/invite?i=1',
        '$_site/startup',
        '$_site/startup/a/b',
        '$_site/program/p1',
        'https://example.com/startup/abc',
      ]) {
        expect(ShareLinks.parse(Uri.parse(other)), isNull, reason: other);
      }
    });
  });

  group('opening a shared link', () {
    late FakeStartupRepository startups;

    setUp(() {
      startups = FakeStartupRepository()
        ..startups.addAll([PrototypeSeed.rafeeq, PrototypeSeed.daftar]);
      StartupRepository.instance = startups;
      DiscoveryRepository.instance = DiscoveryRepository.sample();
      AppSession.instance.reset();
    });

    Future<void> pumpApp(WidgetTester t) async {
      t.view.physicalSize = const Size(412, 892);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          navigatorKey: AppToast.navigatorKey,
          home: const Scaffold(body: Text('welcome')),
        ),
      );
    }

    Future<void> open(WidgetTester t, ShareLinkTarget target) async {
      ShareLinks.open(target);
      await t.pump();
      await t.pump(const Duration(milliseconds: 900));
      await t.pump(const Duration(seconds: 3));
    }

    testWidgets('nobody signed in: Home as a guest, then the startup', (
      t,
    ) async {
      await pumpApp(t);
      await open(t, const ShareLinkTarget(ShareTarget.startup, 'mock-rafeeq'));
      expect(AppSession.instance.isGuest, isTrue);
      expect(find.byType(MainScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(StartupProfileScreen), findsOneWidget);
      expect(find.text('Rafeeq Health'), findsWidgets);
    });

    testWidgets('signed in: the startup opens in their account', (t) async {
      AppSession.instance.signIn(_founder);
      await pumpApp(t);
      await open(t, const ShareLinkTarget(ShareTarget.startup, 'mock-rafeeq'));
      expect(AppSession.instance.isGuest, isFalse);
      expect(AppSession.instance.user?.uid, 'u1');
      expect(find.byType(StartupProfileScreen), findsOneWidget);
      // Nobody is signed out or turned into a guest, and no Home is stacked.
      expect(find.byType(MainScreen), findsNothing);
    });

    testWidgets('a private startup says it is no longer available', (t) async {
      await pumpApp(t);
      await open(t, const ShareLinkTarget(ShareTarget.startup, 'mock-daftar'));
      expect(find.byType(StartupProfileScreen), findsNothing);
      expect(find.text('This startup is no longer available.'), findsOneWidget);
      expect(find.text('Daftar'), findsNothing);
    });

    testWidgets('a deleted startup says it is no longer available', (t) async {
      await pumpApp(t);
      await open(t, const ShareLinkTarget(ShareTarget.startup, 'gone'));
      expect(find.byType(StartupProfileScreen), findsNothing);
      expect(find.text('This startup is no longer available.'), findsOneWidget);
    });

    testWidgets('an investor link opens the investor profile', (t) async {
      await pumpApp(t);
      await open(
        t,
        ShareLinkTarget(ShareTarget.investor, PrototypeSeed.layan.id),
      );
      expect(AppSession.instance.isGuest, isTrue);
      expect(find.byType(InvestorProfileScreen), findsOneWidget);
    });

    testWidgets('an investor who is gone says so', (t) async {
      await pumpApp(t);
      await open(t, const ShareLinkTarget(ShareTarget.investor, 'nobody'));
      expect(find.byType(InvestorProfileScreen), findsNothing);
      expect(
        find.text('This investor is no longer available.'),
        findsOneWidget,
      );
    });
  });
}
