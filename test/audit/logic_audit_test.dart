import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/data_access/firebase_services/auth_service.dart';
import 'package:startsa/data_access/repositories/invitation_repository.dart';
import 'package:startsa/data_access/repositories/public_profile_repository.dart';
import 'package:startsa/features/profiles/view_models/change_password_view_model.dart';
import 'package:startsa/helpers/formatters.dart';
import 'package:startsa/models/auth_failure.dart';
import 'package:startsa/models/invitation.dart';
import 'package:startsa/models/investor_criteria.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/models/team_member.dart';

import '../support/fakes.dart';
import '../support/recording_firestore.dart';

void main() {
  group('money formatters: the edges between K, M and B', () {
    test('a value that rounds up uses the next unit', () {
      expect(Formatters.shortMoney(999), '999');
      expect(Formatters.shortMoney(1000), '1K');
      expect(Formatters.shortMoney(999499), '999K');
      expect(Formatters.shortMoney(999500), '1M');
      expect(Formatters.shortMoney(999999), '1M');
      expect(Formatters.shortMoney(1000000), '1M');
      expect(Formatters.shortMoney(1050000), '1.1M');
      expect(Formatters.shortMoney(999949999), '999.9M');
      expect(Formatters.shortMoney(999950000), '1B');
      expect(Formatters.shortMoney(2400000000), '2.4B');
    });

    test('card tags: SAR 999,999 reads 1M, never 1000K', () {
      expect(Formatters.compactSar(0), 'SAR 0');
      expect(Formatters.compactSar(999), 'SAR 999');
      expect(Formatters.compactSar(1000), 'SAR 1K');
      expect(Formatters.compactSar(500000), 'SAR 500K');
      expect(Formatters.compactSar(999999), 'SAR 1M');
      expect(Formatters.compactSar(1200000), 'SAR 1.2M');
      expect(Formatters.compactSar(5000000), 'SAR 5M');
    });

    test('thousands separators and parsing', () {
      expect(Formatters.thousands(0), '0');
      expect(Formatters.thousands(999), '999');
      expect(Formatters.thousands(1000), '1,000');
      expect(Formatters.thousands(1234567), '1,234,567');
      expect(Formatters.thousands(9999999999999), '9,999,999,999,999');
      expect(Formatters.thousands(-1500), '-1,500');
      expect(Formatters.parseMoney('1,200,000'), 1200000);
      expect(Formatters.parseMoney(''), isNull);
      expect(Formatters.parseMoney('SAR'), isNull);
    });

    test('short web addresses', () {
      expect(Formatters.shortUrl('https://www.example.com/'), 'example.com');
      expect(Formatters.shortUrl('https://a.sa/x/y'), 'a.sa/x/y');
      expect(Formatters.shortUrl('not a url'), 'not a url');
    });
  });

  group('Change password: every field', () {
    late FakeAuthRepository auth;
    late ChangePasswordViewModel vm;
    setUp(() {
      auth = FakeAuthRepository();
      vm = ChangePasswordViewModel(authRepository: auth);
    });

    Future<bool> go(String cur, String next, String confirm) => vm.submit(
      currentPassword: cur,
      newPassword: next,
      confirmPassword: confirm,
    );

    test('empty current password is asked for', () async {
      expect(await go('', 'Newpass1!x', 'Newpass1!x'), isFalse);
      expect(vm.currentPasswordError, isNotNull);
      expect(vm.newPasswordError, isNull);
      expect(auth.changePasswordCalls, 0);
    });

    test('a weak new password is refused (each missing rule)', () async {
      for (final weak in [
        'Ab1!',
        'abcdefg1!',
        'ABCDEFG1!',
        'Abcdefgh!',
        'Abcdefg12',
        'Abcdef 1!',
      ]) {
        expect(await go('Oldpass1!', weak, weak), isFalse, reason: weak);
        expect(vm.newPasswordError, isNotNull, reason: weak);
      }
      expect(auth.changePasswordCalls, 0);
    });

    test('the same password as the current one is refused', () async {
      expect(await go('Samepass1!', 'Samepass1!', 'Samepass1!'), isFalse);
      expect(vm.newPasswordError, isNotNull);
      expect(auth.changePasswordCalls, 0);
    });

    test('a confirmation that differs is refused', () async {
      expect(await go('Oldpass1!', 'Newpass1!x', 'Newpass1!y'), isFalse);
      expect(vm.confirmPasswordError, isNotNull);
      expect(vm.newPasswordError, isNull);
      expect(await go('Oldpass1!', 'Newpass1!x', ''), isFalse);
      expect(vm.confirmPasswordError, isNotNull);
    });

    test('all three problems show at once', () async {
      expect(await go('', 'weak', 'other'), isFalse);
      expect(vm.currentPasswordError, isNotNull);
      expect(vm.newPasswordError, isNotNull);
      expect(vm.confirmPasswordError, isNotNull);
    });

    test('a valid change goes through and clears every error', () async {
      expect(await go('', 'weak', 'x'), isFalse);
      expect(await go('Oldpass1!', 'Newpass1!x', 'Newpass1!x'), isTrue);
      expect(auth.changePasswordCalls, 1);
      expect(vm.currentPasswordError, isNull);
      expect(vm.newPasswordError, isNull);
      expect(vm.confirmPasswordError, isNull);
      expect(vm.formError, isNull);
      expect(vm.isLoading, isFalse);
    });

    test('each server failure lands on the right field', () async {
      auth.changePasswordFails = AuthFailure.invalidCredentials;
      expect(await go('Oldpass1!', 'Newpass1!x', 'Newpass1!x'), isFalse);
      expect(vm.currentPasswordError, isNotNull);
      auth.changePasswordFails = AuthFailure.weakPassword;
      expect(await go('Oldpass1!', 'Newpass1!x', 'Newpass1!x'), isFalse);
      expect(vm.newPasswordError, isNotNull);
      auth.changePasswordFails = AuthFailure.network;
      expect(await go('Oldpass1!', 'Newpass1!x', 'Newpass1!x'), isFalse);
      expect(vm.formError, isNotNull);
      auth.changePasswordFails = AuthFailure.tooManyRequests;
      expect(await go('Oldpass1!', 'Newpass1!x', 'Newpass1!x'), isFalse);
      expect(vm.formError, isNotNull);
      auth.changePasswordFails = AuthFailure.unknown;
      expect(await go('Oldpass1!', 'Newpass1!x', 'Newpass1!x'), isFalse);
      expect(vm.formError, isNotNull);
      expect(vm.isLoading, isFalse);
    });
  });

  group('Investor answers: saved, read back and shown the same', () {
    const full = InvestorCriteria(
      yearsInvesting: '4–6 years',
      dealsCount: '4–6',
      hasLedRound: true,
      roundsLed: '3–5',
      coInvest: 'Possibly',
      ticketBand: 'Other',
      ticketOther: 'Up to a million',
      roundMin: 100000,
      roundMax: 900000,
      sectors: ['Fintech', 'Other'],
      sectorsOther: 'Beekeeping',
      stages: ['Pre-seed', 'Other'],
      stagesOther: 'Bridge',
      commerceModels: [
        'Business-to-Business (B2B)',
        'Business-to-Consumer (B2C)',
        'Other',
      ],
      commerceModelsOther: 'Marketplace',
      lookFor: 'A strong team.',
    );

    test('flat fields round-trip', () {
      final back = InvestorCriteria.fromFields(full.toFields())!;
      expect(back.toFields(), full.toFields());
      expect(back.ticketOther, 'Up to a million');
      expect(back.sectorsOther, 'Beekeeping');
      expect(back.commerceModels.length, 3);
    });

    test('the old single-map form round-trips', () {
      final back = InvestorCriteria.fromMap(full.toMap())!;
      expect(back.toMap(), full.toMap());
    });

    test('an "Other" text is dropped when Other is no longer picked', () {
      final c = full.copyWith(
        sectors: ['Fintech'],
        stages: ['Seed'],
        commerceModels: ['Business-to-Business (B2B)'],
        ticketBand: 'SAR 100K – 500K',
        hasLedRound: false,
      );
      final f = c.toFields();
      expect(f[UserFields.sectorsOther], isNull);
      expect(f[UserFields.preferredStagesOther], isNull);
      expect(f[UserFields.preferredCommerceModelsOther], isNull);
      expect(f[UserFields.ticketSizeOther], isNull);
      expect(f[UserFields.roundsLed], isNull);
    });

    test('labels on the profile', () {
      expect(full.ticketLabel, 'Up to a million');
      expect(full.stageRange, 'Pre-seed – Bridge');
      expect(full.commerceModelsShort, 'B2B, B2C, Marketplace');
      expect(const InvestorCriteria().ticketLabel, isNull);
      expect(const InvestorCriteria().stageRange, '');
      expect(
        const InvestorCriteria(
          ticketBand: 'Other',
          commerceModels: ['Other'],
          stages: ['Other'],
        ).ticketLabel,
        'Other',
      );
      expect(
        const InvestorCriteria(commerceModels: ['Other']).commerceModelsShort,
        'Other',
      );
      expect(const InvestorCriteria(stages: ['Seed']).stageRange, 'Seed');
    });

    test('a document with none of the answers gives none', () {
      expect(InvestorCriteria.fromFields({'fullName': 'x'}), isNull);
      expect(InvestorCriteria.fromMap('nope'), isNull);
    });
  });

  group('Invitations: the whole life of one invitation', () {
    late RecordingFirestore db;
    late FakeAuthService auth;
    late InvitationRepository repo;

    const startup = Startup(
      id: 's1',
      founderId: 'f1',
      name: 'Rafeeq',
      description: 'd',
      sector: Sector.fintech,
      stage: StartupStage.seed,
      businessModel: BusinessModel.b2b,
      location: StartupLocation.riyadh,
      lookingFor: {LookingFor.talent},
      team: [
        TeamMember(
          name: 'Fahad',
          role: 'CEO',
          contribution: 'Leads',
          isFounder: true,
          uid: 'f1',
        ),
        TeamMember(
          name: 'Typed Name',
          email: 'layan@gmail.com',
          role: 'CTO',
          contribution: 'Builds',
          invited: true,
        ),
      ],
    );
    const layan = TeamMember(
      name: 'Typed Name',
      email: 'Layan@Gmail.com',
      role: 'CTO',
      contribution: 'Builds',
      coFounder: true,
      invited: true,
    );

    void who(String uid, String email, {bool verified = true}) {
      db.as(uid, email);
      auth.signedIn = AuthAccount(
        uid: uid,
        email: email,
        emailVerified: verified,
      );
    }

    setUp(() {
      db = RecordingFirestore();
      auth = FakeAuthService();
      repo = InvitationRepository(auth: auth, firestore: db);
      PublicProfileRepository.instance = PublicProfileRepository(firestore: db);
      // The startup exists, as the founder saved it.
      db.store['startups'] = {
        's1': jsonDecode(jsonEncode(startup.toMap())) as Map<String, Object?>,
      };
    });

    Map<String, Object?> stored() =>
        db.store['invitations']!['s1~layan@gmail.com']!;

    test('a new invitation: e-mail lower-cased, pending, indexed', () async {
      who('f1', 'f1@gmail.com');
      final inv = await repo.ensure(
        startup: startup,
        member: layan,
        invitedByName: 'Fahad',
      );
      expect(inv.id, 's1~layan@gmail.com');
      expect(inv.role, 'coFounder');
      expect(inv.newUser, isFalse);
      expect(stored()['status'], 'pending');
      expect(stored()['invitedBy'], 'f1');
      expect(db.store['inviteEmails']!['layan@gmail.com']!['names'], [
        'Rafeeq',
      ]);
    });

    test('inviting a person without an account is marked newUser', () async {
      who('f1', 'f1@gmail.com');
      await repo.ensure(
        startup: startup,
        member: layan,
        invitedByName: 'Fahad',
        newUser: true,
      );
      expect(stored()['newUser'], isTrue);
    });

    test('the role and words follow the card while it is pending', () async {
      who('f1', 'f1@gmail.com');
      await repo.ensure(startup: startup, member: layan, invitedByName: 'F');
      await repo.ensure(
        startup: startup,
        member: layan.copyWith(coFounder: false, role: 'COO'),
        invitedByName: 'F',
      );
      expect(stored()['role'], 'member');
      expect(stored()['roleText'], 'COO');
      expect(stored()['status'], 'pending');
    });

    test('cancel, then invite again: pending with the e-mail unsent', () async {
      who('f1', 'f1@gmail.com');
      await repo.ensure(startup: startup, member: layan, invitedByName: 'F');
      await repo.cancel('s1', 'layan@gmail.com');
      expect(stored()['status'], 'cancelled');
      expect(db.store['inviteEmails']!['layan@gmail.com']!['names'], isEmpty);
      await repo.ensure(startup: startup, member: layan, invitedByName: 'F');
      expect(stored()['status'], 'pending');
      expect(stored()['emailSent'], isFalse);
    });

    test('the invited person sees it only with a VERIFIED e-mail', () async {
      who('f1', 'f1@gmail.com');
      await repo.ensure(startup: startup, member: layan, invitedByName: 'F');
      who('m1', 'layan@gmail.com', verified: false);
      expect(await repo.pendingForMe(), isEmpty);
      who('m1', 'Layan@gmail.com');
      expect((await repo.pendingForMe()).single.startupId, 's1');
    });

    test(
      'accepting: joined with the role, card linked, name replaced',
      () async {
        who('f1', 'f1@gmail.com');
        final inv = await repo.ensure(
          startup: startup,
          member: layan,
          invitedByName: 'F',
        );
        who('m1', 'layan@gmail.com');
        await repo.accept(inv, fullName: 'Layan Alsaab');
        final s = db.store['startups']!['s1']!;
        expect(s['memberIds'], ['m1']);
        expect((s['memberRoles'] as Map)['m1'], 'coFounder');
        final card = (s['teamMembers'] as List).cast<Map>().firstWhere(
          (m) => m['email'] == 'layan@gmail.com',
        );
        expect(card['fullName'], 'Layan Alsaab');
        expect(card['uid'], 'm1');
        expect(card['invited'], isFalse);
        expect(stored()['status'], 'accepted');
        expect(stored()['acceptedBy'], 'm1');
        expect(stored()['acceptedByName'], 'Layan Alsaab');
        expect(db.store['inviteEmails']!['layan@gmail.com']!['names'], isEmpty);
        // Inviting a joined person again changes nothing.
        who('f1', 'f1@gmail.com');
        final again = await repo.ensure(
          startup: startup,
          member: layan,
          invitedByName: 'F',
        );
        expect(again.status, InvitationStatus.accepted);
      },
    );

    test(
      'declining: declined stays declined until the card is removed',
      () async {
        who('f1', 'f1@gmail.com');
        final inv = await repo.ensure(
          startup: startup,
          member: layan,
          invitedByName: 'F',
        );
        who('m1', 'layan@gmail.com');
        await repo.decline(inv);
        expect(stored()['status'], 'declined');
        who('f1', 'f1@gmail.com');
        final again = await repo.ensure(
          startup: startup,
          member: layan,
          invitedByName: 'F',
        );
        expect(again.status, InvitationStatus.declined);
        // Removing a declined card forgets it, so inviting starts fresh.
        await repo.cancel('s1', 'layan@gmail.com');
        expect(
          db.store['invitations']!.containsKey('s1~layan@gmail.com'),
          isFalse,
        );
      },
    );

    test(
      'the sign-up warning lists the startups that invited an e-mail',
      () async {
        who('f1', 'f1@gmail.com');
        await repo.ensure(startup: startup, member: layan, invitedByName: 'F');
        expect(await repo.invitedBy('LAYAN@gmail.com'), ['Rafeeq']);
        expect(await repo.invitedBy('nobody@gmail.com'), isEmpty);
      },
    );

    test(
      'the founder reconciles a card whose owner joined a private startup',
      () async {
        who('f1', 'f1@gmail.com');
        final inv = await repo.ensure(
          startup: startup,
          member: layan,
          invitedByName: 'F',
        );
        who('m1', 'layan@gmail.com');
        await repo.accept(inv, fullName: 'Layan Alsaab');
        who('f1', 'f1@gmail.com');
        // The founder's copy of the startup still shows the card as invited.
        final fixed = await repo.reconcileTeam(startup);
        final card = fixed!.firstWhere((m) => m.email == 'layan@gmail.com');
        expect(card.invited, isFalse);
        expect(card.uid, 'm1');
        expect(card.name, 'Layan Alsaab');
      },
    );

    test('nothing to reconcile when nobody accepted', () async {
      who('f1', 'f1@gmail.com');
      await repo.ensure(startup: startup, member: layan, invitedByName: 'F');
      expect(await repo.reconcileTeam(startup), isNull);
    });

    test('resending is allowed any time while pending', () {
      final inv = Invitation(
        startupId: 's1',
        startupName: 'Rafeeq',
        emailLower: 'a@b.co',
        role: 'member',
        invitedBy: 'f1',
        lastSentAt: DateTime(2026, 1, 1, 12),
      );
      expect(inv.canResend, isTrue);
      expect(
        Invitation(
          startupId: 's',
          startupName: 'n',
          emailLower: 'a@b.co',
          role: 'member',
          invitedBy: 'f',
          status: InvitationStatus.accepted,
        ).canResend,
        isFalse,
      );
    });
  });
}
