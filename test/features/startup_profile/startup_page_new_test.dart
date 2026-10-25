import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/request_repository.dart';
import 'package:startsa/features/startup_profile/screens/startup_profile_screen.dart';
import 'package:startsa/features/startup_profile/view_models/startup_profile_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/models/team_member.dart';

const _investor = AppUser(
  uid: 'inv1',
  role: AccountRole.investor,
  fullName: 'Layan Alsaab',
  email: 'layan@gmail.com',
);

Startup _startup({bool isPublic = true}) => PrototypeSeed.rafeeq.copyWith(
  isPublic: isPublic,
  businessModelText: 'Families pay per visit',
  fundingRequirement: 500000,
  raisedInRound: 200000,
  wantsLeadInvestor: true,
  partnerTypes: ['Technology', 'Distribution'],
  supportTypes: ['Mentorship', 'Hiring'],
  revenueThisYear: 0,
  monthlyBurn: 50000,
  capital: 350000,
  team: const [
    TeamMember(
      name: 'Sara Member',
      role: 'Designer',
      contribution: 'Designs',
      uid: 'm1',
    ),
    TeamMember(
      name: 'Ggg Invited',
      role: 'Ops',
      contribution: 'Runs ops',
      invited: true,
    ),
    TeamMember(
      name: 'Faisal Co',
      role: 'CTO',
      contribution: 'Builds',
      coFounder: true,
      uid: 'c1',
    ),
    TeamMember(
      name: 'Shahad Founder',
      role: 'CEO',
      contribution: 'Leads',
      isFounder: true,
      uid: 'f1',
    ),
  ],
);

Future<StartupProfileViewModel> _vm(Startup s, {bool preview = false}) async =>
    StartupProfileViewModel(
      startup: s,
      preview: preview,
      rounds: const [],
      discovery: DiscoveryRepository.sample(),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    AppSession.instance = AppSession()..signIn(_investor);
    RequestRepository.instance = RequestRepository();
    DiscoveryRepository.instance = DiscoveryRepository.sample();
  });

  Future<void> pump(WidgetTester t, Startup s, {bool preview = false}) async {
    t.view.physicalSize = const Size(412, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: StartupProfileScreen(startup: s, preview: preview),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> goTo(WidgetTester t, String tab) async {
    await t.tap(find.text(tab).first);
    await t.pumpAndSettle();
  }

  testWidgets('Overview: Looking for has only the minimal values', (t) async {
    await pump(t, _startup());
    expect(find.text('Raising SAR 500,000'), findsOneWidget);
    expect(find.text('Technology, Distribution'), findsOneWidget);
    expect(find.text('Mentorship, Hiring'), findsOneWidget);
    expect(find.textContaining('raised so far'), findsNothing);
    expect(find.textContaining('lead investor'), findsNothing);
  });

  testWidgets('Business: model card, no growth plan', (t) async {
    await pump(t, _startup());
    await goTo(t, 'Business');
    expect(find.text('Business model'), findsOneWidget);
    expect(find.text('Families pay per visit'), findsOneWidget);
    expect(find.textContaining('rowth'), findsNothing);
  });

  testWidgets('Team: founder first, then co-founder, then members', (t) async {
    await pump(t, _startup());
    await goTo(t, 'Team');
    double y(String name) => t.getTopLeft(find.text(name)).dy;
    expect(y('Shahad Founder'), lessThan(y('Faisal Co')));
    expect(y('Faisal Co'), lessThan(y('Sara Member')));
    // Invited people are hidden from everybody outside the team.
    expect(find.text('Ggg Invited'), findsNothing);
    expect(find.text('Invited'), findsNothing);
  });

  testWidgets('Team preview shows the invited person, not tappable', (t) async {
    AppSession.instance = AppSession()
      ..signIn(
        const AppUser(
          uid: 'f1',
          role: AccountRole.founder,
          fullName: 'Shahad Founder',
          email: 'shahad@gmail.com',
        ),
      );
    await pump(t, _startup(), preview: true);
    await goTo(t, 'Team');
    expect(find.text('Ggg Invited'), findsOneWidget);
    expect(find.text('Invited'), findsOneWidget);
  });

  testWidgets('Funding: current round, key numbers, no old tiles', (t) async {
    await pump(t, _startup());
    await goTo(t, 'Funding');
    expect(find.text('Current round'), findsOneWidget);
    expect(find.text('Funding goal'), findsOneWidget);
    expect(find.text('SAR 200,000 raised'), findsOneWidget);
    expect(find.text('40%'), findsWidgets);
    expect(find.text('Looking for a lead investor'), findsOneWidget);
    expect(find.text('Key numbers'), findsOneWidget);
    expect(find.text('SAR 0'), findsOneWidget, reason: 'revenue 0');
    expect(find.text('About 7 months'), findsOneWidget);
    expect(find.text('Available now'), findsNothing);
    expect(find.text('Traction'), findsNothing);
  });

  test(
    'Current round: no open round falls back to the Step 7 values',
    () async {
      final vm = await _vm(_startup());
      final r = vm.currentRound!;
      expect(r.type, 'Pre-seed');
      expect(r.goal, 500000);
      expect(r.raised, 200000);
      expect(r.percent, 40);
      final notRaising = await _vm(
        _startup().copyWith(
          lookingFor: {LookingFor.partnership},
          fundingRequirement: 0,
        ),
      );
      expect(notRaising.currentRound, isNull);
    },
  );
}
