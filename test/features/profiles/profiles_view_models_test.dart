import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/features/profiles/view_models/account_view_model.dart';
import 'package:startsa/features/profiles/view_models/edit_account_view_model.dart';
import 'package:startsa/features/profiles/view_models/investor_profile_view_model.dart';
import 'package:startsa/features/startup_profile/view_models/startup_profile_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';

import '../../support/fakes.dart';

const _founder = AppUser(
  uid: 'u1',
  role: AccountRole.founder,
  fullName: 'Shahad Alabdulkarim',
  email: 'shahad@gmail.com',
  city: 'Riyadh',
  phone: '551234567',
  bio: 'Building things.',
  sectorsOfInterest: ['HealthTech', 'Fintech'],
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

void main() {
  late AppSession session;

  setUp(() => session = AppSession());

  group('StartupProfileViewModel roles', () {
    final startup = PrototypeSeed.rafeeq;

    test('guest: express interest, no bookmark', () {
      session.signInAsGuest();
      final vm = StartupProfileViewModel(startup: startup, session: session);
      expect(vm.showCta, isTrue);
      expect(vm.showBookmark, isFalse);
      expect(vm.ctaLabel, 'Express interest');
      vm.ctaDone = true;
      expect(vm.ctaLabel, 'Interest sent');
    });

    test('investor: send investment request', () {
      session.signIn(_investor);
      final vm = StartupProfileViewModel(startup: startup, session: session);
      expect(vm.showCta, isTrue);
      expect(vm.showBookmark, isTrue);
      expect(vm.ctaLabel, 'Send investment request');
      vm.ctaDone = true;
      expect(vm.ctaLabel, 'Request sent');
    });

    test('founder on another startup: no CTA; on own startup: preview', () {
      session.signIn(_founder);
      final other = StartupProfileViewModel(startup: startup, session: session);
      expect(other.showCta, isFalse);
      expect(other.isPreview, isFalse);
      expect(other.showBookmark, isTrue);

      session.setOwnStartupIds([startup.id]);
      final own = StartupProfileViewModel(startup: startup, session: session);
      expect(own.isPreview, isTrue);
      expect(own.showCta, isFalse);
      expect(own.showBookmark, isFalse);
      expect(own.showShare, isFalse);
    });

    test('tabs and display values follow the prototype', () {
      session.signIn(_investor);
      final vm = StartupProfileViewModel(startup: startup, session: session);
      expect(StartupProfileViewModel.tabLabels, [
        'Overview',
        'Business',
        'Team',
        'Funding',
      ]);
      vm.selectTab(3);
      expect(vm.tab, 3);
      // One sub-line under the name (the founded year is in the Overview).
      expect(vm.infoLine, 'HealthTech · Pre-seed · Riyadh');
      expect(vm.raising, 'SAR 500K');
      expect(vm.lookingFor, ['Funding', 'Talent']);
      final cells = vm.financials.map((c) => c.$1).toList();
      expect(cells, contains('Raising'));
      expect(
        cells,
        isNot(contains('City')),
        reason: 'the city is in the header',
      );
      expect(
        cells,
        isNot(contains('Founded')),
        reason: 'founded is in the header',
      );
      expect(vm.revenueLabels, ['Year 1', 'Year 2', 'Year 3']);
    });
  });

  group('InvestorProfileViewModel', () {
    test('only founders get the CTA; guests get no bookmark', () {
      final inv = PrototypeSeed.layan;
      session.signIn(_founder);
      var vm = InvestorProfileViewModel(investor: inv, session: session);
      expect(vm.showCta, isTrue);
      expect(vm.showBookmark, isTrue);

      session.signIn(_investor);
      vm = InvestorProfileViewModel(investor: inv, session: session);
      expect(vm.showCta, isFalse);

      session.signInAsGuest();
      vm = InvestorProfileViewModel(investor: inv, session: session);
      expect(vm.showCta, isFalse);
      expect(vm.showBookmark, isFalse);
      expect(vm.key, 'i-layan');
    });
  });

  group('AccountViewModel', () {
    test('labels and sectors', () {
      final vm = AccountViewModel(
        user: _founder,
        userRepository: FakeUserRepository(),
        startupRepository: FakeStartupRepository(),
        session: session,
      );
      expect(vm.roleLabel, 'Founder');
      expect(vm.sectors, ['HealthTech', 'Fintech']);
      expect(vm.phoneLabel, '+966 55 123 4567');
    });

    test('reload loads the founder startups and publishes their ids', () async {
      final startups = FakeStartupRepository()
        ..startups.add(PrototypeSeed.rafeeq);
      final vm = AccountViewModel(
        user: _founder,
        userRepository: FakeUserRepository(),
        startupRepository: startups,
        session: session,
      );
      await vm.reload();
      expect(vm.startups, hasLength(1));
      expect(session.ownStartupIds, {PrototypeSeed.rafeeq.id});
    });
  });

  group('Part 8: contact visibility and carry-over', () {
    AccountViewModel vmFor(AppUser u) => AccountViewModel(
      user: u,
      userRepository: FakeUserRepository(),
      startupRepository: FakeStartupRepository(),
      session: session,
    );

    test('others see only what is public; I always see both', () {
      final both = _founder.copyWith(emailPublic: true, phonePublic: true);
      final onlyPhone = _founder.copyWith(
        emailPublic: false,
        phonePublic: true,
      );
      final none = _founder.copyWith(emailPublic: false, phonePublic: false);
      expect(vmFor(both).contactRows(isOwner: false), hasLength(2));
      expect(
        vmFor(onlyPhone).contactRows(isOwner: false).single.kind,
        ContactKind.phone,
      );
      expect(vmFor(none).contactRows(isOwner: false), isEmpty);
      expect(vmFor(none).contactRows(), hasLength(2));
    });

    test('profile lists founded and member startups with roles', () async {
      final startups = FakeStartupRepository()
        ..startups.add(PrototypeSeed.rafeeq);
      final vm = AccountViewModel(
        user: _founder,
        userRepository: FakeUserRepository(),
        startupRepository: startups,
        session: session,
      );
      await vm.reload();
      expect(vm.startupEntries.first.isFounder, isTrue);
      expect(vm.startupEntries.length, greaterThan(1));
    });

    test(
      'a founder bio is required and the visibility flags are saved',
      () async {
        final users = FakeUserRepository();
        final vm = EditAccountViewModel(user: _founder, userRepository: users);
        vm.setBio('  ');
        expect(await vm.submit(), isNull);
        expect(vm.bioError, 'Please write a short bio.');
        vm.setBio('Hello');
        vm.setEmailPublic(true);
        vm.setPhonePublic(false);
        final saved = await vm.submit();
        expect(saved!.emailPublic, isTrue);
        expect(saved.phonePublic, isFalse);
      },
    );

    test('changing my name updates my team cards', () async {
      final users = FakeUserRepository();
      final startups = FakeStartupRepository();
      final vm = EditAccountViewModel(
        user: _founder,
        userRepository: users,
        startupRepository: startups,
      );
      vm.setFullName('Shahad Alabdulkarim Jr');
      await vm.submit();
      expect(startups.renames, [
        ('u1', 'Shahad Alabdulkarim', 'Shahad Alabdulkarim Jr'),
      ]);
    });
  });

  group('EditAccountViewModel', () {
    test('starts from the profile and validates on save', () async {
      final users = FakeUserRepository();
      final vm = EditAccountViewModel(user: _investor, userRepository: users);
      expect(vm.fullName, 'Layan Alsaab');
      expect(vm.phone, '509876543');
      expect(vm.isSectorSelected('HealthTech'), isTrue);

      vm.setFullName('Layan');
      vm.setGain('  ');
      expect(
        vm.fullNameError,
        'Enter your first and last name.',
        reason: 'the name rule shows live',
      );
      expect(vm.gainError, isNull, reason: 'required fields wait for a save');
      expect(await vm.submit(), isNull);
      expect(vm.fullNameError, 'Enter your first and last name.');
      expect(
        vm.gainError,
        'Tell founders what you are looking for — it can’t be blank.',
      );
      expect(users.profileUpdates, 0);
    });

    test(
      'an investor with no saved answers still opens, then saves all',
      () async {
        final users = FakeUserRepository();
        final vm = EditAccountViewModel(user: _investor, userRepository: users);
        final c = vm.criteria!;
        expect(c.deals, isNull);
        expect(c.sectors, isEmpty);
        vm.setBio('A short bio.');
        expect(await vm.submit(), isNull, reason: 'answers are still missing');
        expect(c.dealsError, isNotNull);
        c.pickYears('1–3 years');
        c.pickDeals('0');
        c.pickLed('No');
        c.toggleSector('HealthTech');
        c.toggleStage('Seed');
        c.toggleModel('Business-to-Business (B2B)');
        vm.setEmailPublic(true);
        final saved = await vm.submit();
        expect(saved, isNotNull);
        expect(saved!.emailPublic, isTrue);
        expect(saved.investorCriteria!.dealsCount, '0');
        expect(saved.investorCriteria!.roundMin, isNull);
        expect(saved.investorCriteria!.stages, ['Seed']);
        expect(saved.investorCriteria!.lookFor, 'Early access.');
        expect(users.onboardingSaves, 1);
      },
    );

    test('saves and returns the updated user', () async {
      final users = FakeUserRepository();
      final vm = EditAccountViewModel(user: _founder, userRepository: users);
      vm.setFullName('Shahad Alabdulkarim Jr');
      vm.setLinkedin('linkedin.com/in/shahad');
      vm.toggleSector('EdTech');
      final saved = await vm.submit();
      expect(saved, isNotNull);
      expect(saved!.fullName, 'Shahad Alabdulkarim Jr');
      expect(saved.sectorsOfInterest, ['HealthTech', 'Fintech', 'EdTech']);
      expect(users.savedProfile!['linkedin'], 'linkedin.com/in/shahad');
      expect(users.savedProfile!['gain'], isNull);
    });

    test('Other needs text; a bad LinkedIn link blocks saving', () async {
      final vm = EditAccountViewModel(
        user: _founder,
        userRepository: FakeUserRepository(),
      );
      vm.toggleSector('Other');
      vm.setLinkedin('not a link');
      expect(await vm.submit(), isNull);
      expect(
        vm.otherError,
        'Please type your other sector — it can’t be blank.',
      );
      expect(
        vm.linkedinError,
        'Enter a LinkedIn profile link, like linkedin.com/in/your-name',
      );
      vm.setOtherSector('SportsTech');
      vm.setLinkedin('');
      final saved = await vm.submit();
      expect(saved!.sectorsOther, 'SportsTech');
      expect(saved.sectorsOfInterest, contains('Other'));
    });

    test('a failed save keeps the form and shows a message', () async {
      final users = FakeUserRepository();
      final vm = EditAccountViewModel(user: _founder, userRepository: users);
      users.updateFails = AuthFailure.network;
      expect(await vm.submit(), isNull);
      expect(vm.formError, isNotNull);
      expect(vm.isLoading, isFalse);
    });
  });
}
