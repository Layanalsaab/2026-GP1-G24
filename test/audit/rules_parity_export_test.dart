// Exports every write the app can make, with the biggest values the forms
// allow and every pick-list value, to build/rules_parity.json.
// tools/rules_tests/parity.test.mjs replays that file against the REAL
// firestore.rules, so a field the app writes but the rules refuse (or a limit
// that differs) is caught here instead of as "We couldn't save your startup".
//
//   flutter test test/audit/rules_parity_export_test.dart
//   cd tools/rules_tests && npm run parity
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/data_access/firebase_services/auth_service.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/funding_round_repository.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/data_access/repositories/invitation_repository.dart';
import 'package:startsa/data_access/repositories/public_profile_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/team_lookup.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/investor_criteria.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/models/team_member.dart';

import '../support/fakes.dart';
import '../support/recording_firestore.dart';

String _text(int n, [String c = 'a']) => List.filled(n, c).join();

/// A web address of exactly [n] characters ending in .com.
String _site(int n) => 'https://${_text(n - 'https://.com'.length)}.com';

void main() {
  late RecordingFirestore db;
  late FakeAuthService auth;
  late StartupRepository startups;
  late UserRepository users;
  late InvitationRepository invitations;
  late TeamLookup lookup;

  /// Switches the signed-in user. Waits first, so writes the app starts
  /// without waiting for them (profile refreshes) are labelled with the user
  /// who made them.
  Future<void> actor(String uid, String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    db.as(uid, email);
    auth.signedIn = AuthAccount(uid: uid, email: email, emailVerified: true);
  }

  setUp(() {
    db = RecordingFirestore();
    auth = FakeAuthService();
    users = UserRepository(firestore: db);
    UserRepository.instance = users;
    final rounds = FundingRoundRepository(firestore: db);
    FundingRoundRepository.instance = rounds;
    startups = StartupRepository(auth: auth, firestore: db, rounds: rounds);
    StartupRepository.instance = startups;
    PublicProfileRepository.instance = PublicProfileRepository(firestore: db);
    lookup = TeamLookup(firestore: db);
    TeamLookup.instance = lookup;
    invitations = InvitationRepository(auth: auth, firestore: db);
    InvitationRepository.instance = invitations;
  });

  Startup base({
    Sector sector = Sector.fintech,
    StartupStage stage = StartupStage.seed,
    BusinessModel model = BusinessModel.b2b,
    StartupLocation? location,
    Set<LookingFor>? looking,
    String? sectorOther,
    String? stageOther,
    String? modelOther,
    String? lookingOther,
  }) => Startup(
    id: 'x',
    founderId: 'x',
    name: 'Rafeeq',
    description: 'A short description.',
    sector: sector,
    sectorOther: sectorOther,
    stage: stage,
    stageOther: stageOther,
    businessModel: model,
    businessModelOther: modelOther,
    location: location ?? StartupLocation.riyadh,
    lookingFor: looking ?? {LookingFor.talent},
    lookingForOther: lookingOther,
    team: const [
      TeamMember(
        name: 'Founder One',
        role: 'CEO',
        contribution: 'Leads.',
        isFounder: true,
        uid: 'f1',
      ),
    ],
  );

  /// The founder signs up and verifies: every private and public document.
  Future<void> founderAccount({
    required String uid,
    required String email,
    bool max = false,
  }) async {
    await actor(uid, email);
    await users.createProfile(
      uid: uid,
      role: AccountRole.founder,
      fullName: max ? _text(50) : 'Fahad Alharbi',
      email: email,
      phone: '532851498',
      city: 'Al Jubail',
      bio: max ? _text(2000) : 'Builds things.',
      sectorsOfInterest: [for (final s in Sector.values) s.label],
      sectorsOther: max ? _text(40) : null,
      linkedin: max ? _text(120) : null,
      gain: max ? _text(1000) : null,
      valueOffered: max ? _text(1000) : null,
      emailPublic: true,
      phonePublic: true,
    );
    final user = await users.getProfile(uid);
    await lookup.publish(user!, emailVerified: true);
  }

  test('export every write the app makes', () async {
    // ---------------------------------------------------------- accounts
    db.scenario = 'founder signup (typical)';
    await founderAccount(uid: 'f1', email: 'f1@gmail.com');

    db.scenario = 'founder signup (biggest answers)';
    await founderAccount(uid: 'f2', email: 'f2@gmail.com', max: true);

    for (final private in [false, true]) {
      db.scenario = 'founder signup (${private ? 'private' : 'public'} contact)';
      final uid = private ? 'f3' : 'f4';
      await actor(uid, '$uid@gmail.com');
      await users.createProfile(
        uid: uid,
        role: AccountRole.founder,
        fullName: 'Noura Alsaud',
        email: '$uid@gmail.com',
        emailPublic: !private,
        phonePublic: !private,
        phone: '555555555',
      );
      final u = await users.getProfile(uid);
      await lookup.publish(u!, emailVerified: true);
    }

    db.scenario = 'investor signup + onboarding (typical)';
    await actor('i1', 'i1@gmail.com');
    await users.createProfile(
      uid: 'i1',
      role: AccountRole.investor,
      fullName: 'Sara Alotaibi',
      email: 'i1@gmail.com',
      phone: '555555555',
      city: 'Jeddah',
      bio: 'Invests.',
    );
    await users.saveInvestorOnboarding(
      uid: 'i1',
      criteria: const InvestorCriteria(
        yearsInvesting: '1–3 years',
        dealsCount: '1–3',
        coInvest: 'Possibly',
        ticketBand: 'SAR 100K – 500K',
        roundMin: 100000,
        roundMax: 500000,
        sectors: ['Fintech', 'SaaS'],
        stages: ['Seed'],
        commerceModels: ['Business-to-Business (B2B)'],
        lookFor: 'A strong team.',
      ),
      valueOffered: 'Network.',
    );

    db.scenario = 'investor signup + onboarding (biggest answers)';
    await actor('i2', 'i2@gmail.com');
    await users.createProfile(
      uid: 'i2',
      role: AccountRole.investor,
      fullName: _text(50),
      email: 'i2@gmail.com',
      phone: '599999999',
      city: 'Al Jubail',
      bio: _text(2000),
      sectorsOther: _text(40),
      linkedin: _text(120),
      emailPublic: true,
      phonePublic: true,
    );
    await users.saveInvestorOnboarding(
      uid: 'i2',
      criteria: InvestorCriteria(
        yearsInvesting: InvestorCriteria.yearsOptions.last,
        dealsCount: InvestorCriteria.dealsOptions.last,
        hasLedRound: true,
        roundsLed: InvestorCriteria.roundsLedOptions.last,
        coInvest: InvestorCriteria.coInvestOptions.first,
        ticketBand: 'Other',
        ticketOther: _text(40),
        roundMin: 9999999999999,
        roundMax: 9999999999999,
        sectors: [for (final s in Sector.values) s.label],
        sectorsOther: _text(40),
        stages: [...InvestorCriteria.stageOptions],
        stagesOther: _text(40),
        commerceModels: [for (final m in BusinessModel.values) m.label],
        commerceModelsOther: _text(40),
        lookFor: _text(InvestorCriteria.lookForMax),
      ),
      valueOffered: _text(1000),
    );

    // ----------------------------------------------- every pick-list value
    var n = 0;
    Future<void> createAndEdit(String label, Startup s) async {
      db.scenario = 'startup: $label';
      await actor('f1', 'f1@gmail.com');
      final saved = await startups.create(s);
      n++;
      await startups.update(saved.copyWith(name: 'Rafeeq $n'));
    }

    for (final v in Sector.values) {
      await createAndEdit(
        'sector ${v.value}',
        base(sector: v, sectorOther: v == Sector.other ? _text(40) : null),
      );
    }
    for (final v in StartupStage.values) {
      await createAndEdit(
        'stage ${v.value}',
        base(
          stage: v,
          stageOther: v == StartupStage.other ? _text(40) : null,
        ),
      );
    }
    for (final v in BusinessModel.values) {
      await createAndEdit(
        'model ${v.value}',
        base(
          model: v,
          modelOther: v == BusinessModel.other ? _text(40) : null,
        ),
      );
    }
    for (final v in StartupLocation.values) {
      await createAndEdit('city ${v.value}', base(location: v));
    }
    for (final v in LookingFor.values) {
      await createAndEdit(
        'looking for ${v.value}',
        base(
          looking: {v},
          lookingOther: v == LookingFor.other ? _text(40) : null,
        ),
      );
    }

    // ----------------------------------------------------- biggest startup
    final year = DateTime.now().year;
    final biggest = Startup(
      id: 'x',
      founderId: 'x',
      name: _text(Startup.nameMax),
      description: _text(Startup.descriptionMax),
      sector: Sector.other,
      sectorOther: _text(40),
      otherSectors: [for (var i = 0; i < 24; i++) _text(40, 'b')],
      stage: StartupStage.other,
      stageOther: _text(40),
      businessModel: BusinessModel.other,
      businessModelOther: _text(40),
      location: StartupLocation.values.last,
      foundedYear: year,
      websiteUrl: _site(Startup.websiteMax),
      lookingFor: LookingFor.values.toSet(),
      lookingForOther: _text(40),
      fundingRequirement: 9999999999999,
      isPublic: true,
      problem: _text(Startup.problemMax),
      solution: _text(Startup.solutionMax),
      customers: _text(Startup.customersMax),
      advantage: _text(Startup.longTextMax),
      tam: 9999999999999,
      sam: 9999999999999,
      som: 9999999999999,
      team: [
        const TeamMember(
          name: 'Founder One',
          role: 'CEO',
          contribution: 'Leads.',
          isFounder: true,
          uid: 'f1',
        ),
        for (var i = 0; i < 19; i++)
          TeamMember(
            name: _text(TeamMember.nameMax),
            email: '${_text(100 - '@gmail.com'.length)}@gmail.com',
            role: _text(TeamMember.roleMax),
            contribution: _text(TeamMember.contributionMax),
            invited: true,
          ),
      ],
      growth: _text(Startup.longTextMax),
      capital: 9999999999999,
      revenueYear1: 9999999999999,
      revenueYear2: 9999999999999,
      revenueYear3: 9999999999999,
      valuation: 9999999999999,
      wantsLeadInvestor: true,
      revenueThisYear: 9999999999999,
      monthlyBurn: 9999999999999,
      businessModelText: _text(250),
      raisedInRound: 9999999999999,
      partnerTypes: [for (var i = 0; i < 10; i++) _text(40, 'p')],
      supportTypes: [for (var i = 0; i < 10; i++) _text(40, 's')],
      memberRoles: {
        for (var i = 0; i < 49; i++) 'm$i': i.isEven ? 'coFounder' : 'member',
      },
    );
    db.scenario = 'account: the co-founder of the biggest startup';
    await founderAccount(uid: 'm0', email: 'm0@gmail.com');
    db.scenario = 'startup: biggest everything';
    await actor('f1', 'f1@gmail.com');
    final saved = await startups.create(biggest);
    await startups.update(saved.copyWith(description: 'Edited.'));
    // A co-founder (m0) edits the same biggest startup.
    await actor('m0', 'm0@gmail.com');
    await startups.update(saved.copyWith(description: 'Edited by co-founder.'));
    await actor('f1', 'f1@gmail.com');
    // Switching Funding off closes the round in the same write.
    await startups.update(
      saved.copyWith(
        lookingFor: {LookingFor.talent},
        clearFunding: true,
        isPublic: false,
      ),
    );
    await startups.delete(saved);

    // Zero amounts and the smallest texts.
    db.scenario = 'startup: smallest everything';
    await startups.create(
      Startup(
        id: 'x',
        founderId: 'x',
        name: 'A',
        description: '',
        sector: Sector.ai,
        stage: StartupStage.preSeed,
        businessModel: BusinessModel.b2c,
        location: StartupLocation.riyadh,
        lookingFor: const {},
        capital: 0,
        valuation: 0,
        revenueThisYear: 0,
        monthlyBurn: 0,
        raisedInRound: 0,
        revenueYear1: 0,
        revenueYear2: 0,
        revenueYear3: 0,
        tam: 0,
        sam: 0,
        som: 0,
        foundedYear: 1900,
      ),
    );

    // -------------------------------------------------- the team and invites
    db.scenario = 'team: invite, accept, rename, leave';
    await actor('f1', 'f1@gmail.com');
    final team = await startups.create(
      base(looking: {LookingFor.talent}).copyWith(isPublic: true),
    );
    const invitee = TeamMember(
      name: 'Layan Alsaab',
      email: 'layan@gmail.com',
      role: 'CTO',
      contribution: 'Builds the app.',
      coFounder: true,
      invited: true,
    );
    await startups.setTeam(team.id, [...team.team, invitee]);
    final withTeam = team.copyWith(team: [...team.team, invitee]);
    final inv = await invitations.ensure(
      startup: withTeam,
      member: invitee,
      invitedByName: 'Fahad Alharbi',
    );
    await invitations.ensure(
      startup: withTeam,
      member: invitee.copyWith(role: 'CTO & more'),
      invitedByName: 'Fahad Alharbi',
      newUser: true,
    );
    final sent = invitations.sendEmail;
    expect(sent, isNotNull);
    await invitations.cancel(team.id, 'layan@gmail.com');
    await invitations.ensure(
      startup: withTeam,
      member: invitee,
      invitedByName: 'Fahad Alharbi',
    );

    await founderAccount(uid: 'm1', email: 'layan@gmail.com');
    db.scenario = 'team: invite, accept, rename, leave';
    await actor('m1', 'layan@gmail.com');
    await invitations.accept(inv, fullName: _text(50));
    final joined = Startup.fromMap(
      team.id,
      await db.getDocument(FirestoreCollections.startups, team.id),
    )!;
    await startups.leave(joined);

    // A second person declines.
    await actor('f1', 'f1@gmail.com');
    const second = TeamMember(
      name: 'Omar',
      email: 'omar@gmail.com',
      role: 'COO',
      contribution: 'Runs it.',
      invited: true,
    );
    final i2 = await invitations.ensure(
      startup: withTeam,
      member: second,
      invitedByName: 'Fahad Alharbi',
      newUser: true,
    );
    await actor('o1', 'omar@gmail.com');
    await invitations.decline(i2);
    await actor('f1', 'f1@gmail.com');
    await invitations.cancel(team.id, 'omar@gmail.com');

    db.scenario = 'founder changes their name';
    await actor('f1', 'f1@gmail.com');
    await startups.syncMemberName(
      uid: 'f1',
      oldName: 'Founder One',
      newName: 'Fahad Alharbi',
    );

    // ----------------------------------------------------------- the rest
    db.scenario = 'edit profile: founder (biggest answers)';
    await actor('f2', 'f2@gmail.com');
    await users.updateProfile(
      uid: 'f2',
      fullName: _text(50),
      bio: _text(2000),
      phone: '599999999',
      sectorsOfInterest: [for (final s in Sector.values) s.label],
      city: 'Al Jubail',
      sectorsOther: _text(40),
      linkedin: _text(120),
      gain: _text(1000),
      valueOffered: _text(1000),
      emailPublic: false,
      phonePublic: false,
    );
    final f2 = await users.getProfile('f2');
    await lookup.publish(f2!, emailVerified: true);
    await users.completeOnboarding('f2');

    db.scenario = 'edit profile: investor (biggest answers)';
    await actor('i2', 'i2@gmail.com');
    await users.updateProfile(
      uid: 'i2',
      fullName: _text(50),
      bio: _text(2000),
      phone: '599999999',
      sectorsOfInterest: const [],
      city: 'Riyadh',
      sectorsOther: _text(40),
      linkedin: _text(120),
      gain: _text(1000),
      valueOffered: _text(1000),
      emailPublic: true,
      phonePublic: false,
    );

    db.scenario = 'bookmarks: add and remove';
    await actor('f1', 'f1@gmail.com');
    AppSession.instance = AppSession()
      ..signIn(
        const AppUser(
          uid: 'f1',
          role: AccountRole.founder,
          fullName: 'Fahad Alharbi',
          email: 'f1@gmail.com',
        ),
      );
    final marks = BookmarkRepository(firestore: db);
    marks.toggle('s-gen1');
    marks.toggle('i-ANG-0347ab276b');
    marks.toggle('p-abc');
    marks.toggle('s-gen1');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    db.scenario = 'delete account';
    await actor('d1', 'd1@gmail.com');
    await users.createProfile(
      uid: 'd1',
      role: AccountRole.founder,
      fullName: 'Delete Me',
      email: 'd1@gmail.com',
    );
    await lookup.publish((await users.getProfile('d1'))!, emailVerified: true);
    await lookup.remove(uid: 'd1', email: 'd1@gmail.com');
    await users.deleteProfile('d1');

    db.scenario = 'remove profile photo';
    await actor('f1', 'f1@gmail.com');
    await users.removeProfilePhoto('f1');

    final out = File('build/rules_parity.json');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(jsonEncode(db.log));
    // ignore: avoid_print
    print('Recorded ${db.log.length} writes in build/rules_parity.json');
    expect(db.log.length, greaterThan(100));
  });
}
