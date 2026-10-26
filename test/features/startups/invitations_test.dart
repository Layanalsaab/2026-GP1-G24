import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/repositories/invitation_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/login_and_signup/screens/login_screen.dart';
import 'package:startsa/features/startups/screens/invite_screen.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/app_constants/founder_tools_strings.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_flow.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/helpers/invitation_claimer.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/invitation.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/team_member.dart';
import 'package:startsa/navigation/invite_links.dart';

import '../../support/fakes.dart';

const _fahad = AppUser(
  uid: 'uid1',
  role: AccountRole.founder,
  fullName: 'Fahad Alotaibi',
  email: 'fahad@gmail.com',
);

void main() {
  late FakeStartupRepository startups;
  late FakeInvitationRepository invites;

  setUp(() {
    startups = FakeStartupRepository();
    StartupRepository.instance = startups;
    invites = FakeInvitationRepository();
    InvitationRepository.instance = invites;
    AppSession.instance = AppSession()..signIn(_fahad);
  });

  StartupStepsViewModel formWithTeam({Startup? initial}) {
    final vm = StartupStepsViewModel(initial: initial, invitations: invites);
    if (initial == null) {
      vm.name.text = 'Rafeeq Health';
      vm.description.text = 'Home nursing.';
      vm.selectSector('HealthTech', null);
      vm.selectStage('Pre-seed');
      vm.selectModel('Business-to-Consumer (B2C)', null);
      vm.selectCity('Riyadh');
      vm.toggleLookingFor('Partnership');
      vm.togglePartner('Technology');
    }
    return vm;
  }

  Future<void> addInvited(
    StartupStepsViewModel vm, {
    String email = 'sara@gmail.com',
    bool coFounder = true,
  }) async {
    vm.openMemberEditor();
    vm.memberName.text = 'Sara Alamri';
    vm.memberEmail.text = email;
    vm.memberRole.text = 'COO';
    vm.memberContribution.text = 'Operations';
    vm.setMemberCoFounder(coFounder);
    await vm.saveMember();
    await vm.saveMember(inviteConfirmed: true);
  }

  group('Invitation model', () {
    test('the id is startupId~e-mail in lower case', () {
      expect(Invitation.idOf('S1', ' Sara@Gmail.com '), 'S1~sara@gmail.com');
    });

    test('canResend: never sent, or an hour ago', () {
      final now = DateTime(2026, 10, 25, 12);
      Invitation inv({DateTime? sent}) => Invitation(
        startupId: 's',
        startupName: 'S',
        emailLower: 'a@b.co',
        role: Invitation.roleMember,
        invitedBy: 'u',
        lastSentAt: sent,
      );
      expect(inv().canResend(now), isTrue);
      expect(
        inv(sent: now.subtract(const Duration(minutes: 5))).canResend(now),
        isFalse,
      );
      expect(
        inv(sent: now.subtract(const Duration(hours: 2))).canResend(now),
        isTrue,
      );
    });

    test('fromMap reads what toCreateMap writes', () {
      const inv = Invitation(
        startupId: 'S1',
        startupName: 'Rafeeq',
        emailLower: 'sara@gmail.com',
        role: Invitation.roleCoFounder,
        roleText: 'CTO',
        contribution: 'Builds',
        invitedBy: 'u1',
        invitedByName: 'Fahad',
      );
      final back = Invitation.fromMap(inv.toCreateMap())!;
      expect(back.id, inv.id);
      expect(back.isCoFounder, isTrue);
      expect(back.status, InvitationStatus.pending);
      expect(back.emailSent, isFalse);
    });
  });

  group('Saving a startup sends the invitations', () {
    test('an invited member gets an invitation and ONE e-mail', () async {
      final vm = formWithTeam();
      addTearDown(vm.dispose);
      await addInvited(vm);
      final saved = await vm.save();
      expect(saved, isNotNull);
      expect(invites.store.values.single.emailLower, 'sara@gmail.com');
      expect(invites.store.values.single.role, Invitation.roleCoFounder);
      expect(invites.sentEmails, hasLength(1));
      expect(vm.inviteSummary.sent, 1);
      expect(vm.inviteSummary.failed, 0);
      // Saving again does not send it again.
      invites.sentEmails.clear();
      final vm2 = formWithTeam(initial: saved);
      addTearDown(vm2.dispose);
      await vm2.save();
      expect(invites.sentEmails, isEmpty);
    });

    test('a failed e-mail is reported and kept "not sent"', () async {
      invites.sendResult = InviteSendResult.failed;
      final vm = formWithTeam();
      addTearDown(vm.dispose);
      await addInvited(vm);
      expect(await vm.save(), isNotNull, reason: 'the startup is saved anyway');
      expect(vm.inviteSummary.sent, 0);
      expect(vm.inviteSummary.failed, 1);
      expect(invites.store.values.single.emailSent, isFalse);
    });

    test('each situation has its own plain message', () async {
      Future<InviteSummary> run(InviteSendResult r) async {
        invites.sendResult = r;
        invites.store.clear();
        final vm = formWithTeam();
        addTearDown(vm.dispose);
        await addInvited(vm);
        await vm.save();
        return vm.inviteSummary;
      }

      var s = await run(InviteSendResult.offline);
      expect((s.failed, s.offline, s.limit), (1, true, false));
      s = await run(InviteSendResult.dailyLimit);
      expect((s.failed, s.offline, s.limit), (1, false, true));
      s = await run(InviteSendResult.notConfigured);
      expect((s.failed, s.offline, s.limit), (1, false, false));
      s = await run(InviteSendResult.tooSoon);
      expect(s.nothing, isTrue, reason: 'tooSoon is just "already sent"');
      expect(FounderToolsStrings.invitesFailed(1), contains('wasn’t sent'));
      expect(
        FounderToolsStrings.invitesFailed(2),
        contains('2 invitation emails'),
      );
    });

    test('removing an invited member cancels the invitation', () async {
      final vm = formWithTeam();
      addTearDown(vm.dispose);
      await addInvited(vm);
      final saved = await vm.save();
      final edit = formWithTeam(initial: saved);
      addTearDown(edit.dispose);
      final at = edit.team.indexWhere((m) => m.email == 'sara@gmail.com');
      edit.openMemberEditor(at);
      edit.removeMember();
      await edit.save();
      expect(invites.cancelled, contains('${saved!.id}~sara@gmail.com'));
    });

    test('a joined co-founder box change updates memberRoles', () async {
      final base = Startup.fromMap('S9', {
        'founderId': 'uid1',
        'name': 'Rafeeq',
        'description': 'd',
        'sector': 'fintech',
        'stage': 'seed',
        'businessModel': 'b2b',
        'location': 'riyadh',
        'lookingFor': ['funding'],
        'memberIds': ['m1'],
        'memberRoles': {'m1': 'member'},
        'teamMembers': [
          {
            'fullName': 'Maha Member',
            'email': 'maha@gmail.com',
            'role': 'Designer',
            'contribution': 'x',
            'uid': 'm1',
          },
        ],
      })!;
      startups.startups.add(base);
      final vm = formWithTeam(initial: base);
      addTearDown(vm.dispose);
      final at = vm.team.indexWhere((m) => m.uid == 'm1');
      vm.openMemberEditor(at);
      vm.setMemberCoFounder(true);
      expect(await vm.saveMember(), MemberSave.saved);
      final saved = await vm.save();
      expect(saved!.memberRoles['m1'], 'coFounder');
    });

    test(
      'registered founder: an invitation, no dialog; investor refused',
      () async {
        final vm = formWithTeam();
        addTearDown(vm.dispose);
        vm.openMemberEditor();
        vm.memberName.text = 'Nada Test';
        vm.memberEmail.text = 'unknown.person@gmail.com';
        vm.memberRole.text = 'r';
        vm.memberContribution.text = 'c';
        // Nobody registered with this e-mail: the dialog comes first.
        expect(await vm.saveMember(), MemberSave.needsInvite);
      },
    );
  });

  group('The invited person', () {
    Invitation pending(String email) => Invitation(
      startupId: 'S1',
      startupName: 'Rafeeq Health',
      emailLower: email,
      role: Invitation.roleCoFounder,
      invitedBy: 'u1',
      invitedByName: 'Fahad',
    );

    test('a new founder account joins every invitation at once', () async {
      invites.myEmail = 'sara@gmail.com';
      invites.store['S1~sara@gmail.com'] = pending('sara@gmail.com');
      invites.store['S2~sara@gmail.com'] = Invitation(
        startupId: 'S2',
        startupName: 'Naql',
        emailLower: 'sara@gmail.com',
        role: Invitation.roleMember,
        invitedBy: 'u2',
      );
      const sara = AppUser(
        uid: 's1',
        role: AccountRole.founder,
        fullName: 'Sara',
        email: 'sara@gmail.com',
      );
      final joined = await InvitationClaimer.acceptAll(
        sara,
        repository: invites,
      );
      expect(joined, ['Rafeeq Health', 'Naql']);
      expect(invites.accepted, hasLength(2));
      expect(
        InvitationClaimer.addedMessage(joined),
        'You’ve been added to 2 startups',
      );
      expect(
        InvitationClaimer.addedMessage(['Rafeeq Health']),
        'You’ve been added to Rafeeq Health',
      );
    });

    test('an investor can not join: the invitations are declined', () async {
      invites.myEmail = 'sara@gmail.com';
      invites.store['S1~sara@gmail.com'] = pending('sara@gmail.com');
      await InvitationClaimer.declineAll(repository: invites);
      expect(invites.declined, ['S1~sara@gmail.com']);
    });

    test('sign-up warns an investor whose e-mail was invited', () async {
      invites.inviteIndex['sara@gmail.com'] = ['Rafeeq Health'];
      expect(await invites.invitedBy('Sara@Gmail.com'), ['Rafeeq Health']);
      expect(await invites.invitedBy('nobody@gmail.com'), isEmpty);
    });
  });

  group('Sign-up from an invitation', () {
    test('has two steps: Create account and Verify email', () {
      final flow = SignupFlow(role: AccountRole.founder);
      expect(flow.totalSteps, 8);
      flow.fromInvite = true;
      expect(flow.totalSteps, 2);
    });
  });

  group('The invite link', () {
    test('only the invite address is recognised', () {
      expect(
        InviteLinks.idFrom(
          Uri.parse(
            'https://startsa-ea49e.web.app/invite?i=S1~sara%40gmail.com',
          ),
        ),
        'S1~sara@gmail.com',
      );
      expect(
        InviteLinks.idFrom(
          Uri.parse('https://startsa-ea49e.web.app/other?i=1'),
        ),
        isNull,
      );
      expect(
        InviteLinks.idFrom(Uri.parse('https://evil.example/invite?i=1')),
        isNull,
      );
      expect(
        InviteLinks.idFrom(Uri.parse('https://startsa-ea49e.web.app/invite')),
        isNull,
      );
    });
  });

  group('Invite screen', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    Future<void> pump(WidgetTester t, String id) async {
      t.view.physicalSize = const Size(412, 892);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(home: InviteScreen(invitationId: id)));
      await t.pumpAndSettle();
    }

    testWidgets('a pending invitation shows who, where and the e-mail', (
      t,
    ) async {
      AppSession.instance = AppSession(); // nobody signed in
      invites.store['S1~sara@gmail.com'] = const Invitation(
        startupId: 'S1',
        startupName: 'Rafeeq Health',
        emailLower: 'sara@gmail.com',
        role: Invitation.roleCoFounder,
        roleText: 'CTO',
        invitedBy: 'u1',
        invitedByName: 'Fahad Alotaibi',
      );
      await pump(t, 'S1~sara@gmail.com');
      expect(find.text('You’re invited to join Rafeeq Health'), findsOneWidget);
      expect(
        find.textContaining('Fahad Alotaibi invited you as a co-founder'),
        findsOneWidget,
      );
      expect(find.textContaining('sara@gmail.com'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('Log in has no "Sign up" line and can start with an email', (
      t,
    ) async {
      t.view.physicalSize = const Size(412, 892);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        const MaterialApp(home: LoginScreen(email: 'sara@gmail.com')),
      );
      await t.pumpAndSettle();
      expect(find.textContaining('have an account'), findsNothing);
      expect(find.text('Sign up'), findsNothing);
      expect(find.text('sara@gmail.com'), findsOneWidget);
    });

    testWidgets('a missing or cancelled invitation says so', (t) async {
      AppSession.instance = AppSession();
      await pump(t, 'S1~nobody@gmail.com');
      expect(find.text('This invitation is no longer active.'), findsOneWidget);
    });
  });

  test('TeamMember keeps the invited flag in its map', () {
    const m = TeamMember(
      name: 'Sara',
      role: 'COO',
      contribution: 'x',
      email: 'sara@gmail.com',
      invited: true,
    );
    expect(TeamMember.fromMap(m.toMap())!.invited, isTrue);
  });
}
