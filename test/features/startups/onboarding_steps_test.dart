import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/team_lookup.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/helpers/round_limits.dart';
import 'package:startsa/helpers/startup_finance.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';

import '../../support/fakes.dart';

const _founder = AppUser(
  uid: 'u1',
  role: AccountRole.founder,
  fullName: 'Shahad Alabdulkarim',
  email: 'Shahad@Gmail.com',
);

StartupStepsViewModel _vm({StartupStage stage = StartupStage.preSeed}) {
  final vm = StartupStepsViewModel();
  vm.selectStage(stage.label);
  return vm;
}

/// A test lookup with one registered account (the real one searches users).
class _OneAccount extends TeamLookup {
  const _OneAccount();

  @override
  Future<TeamAccount?> findByEmail(String email) async =>
      email.trim().toLowerCase() == 'nora.alharbi@gmail.com'
      ? const TeamAccount(uid: 'sample-nora', name: 'Nora Alharbi')
      : null;
}

void main() {
  late FakeStartupRepository repo;

  setUp(() {
    repo = FakeStartupRepository();
    StartupRepository.instance = repo;
    AppSession.instance = AppSession();
    TeamLookup.instance = const _OneAccount();
  });

  tearDown(() => TeamLookup.instance = const TeamLookup());

  group('Part 3: Overview, description and market', () {
    test('website message waits for a dot or Next', () {
      final vm = _vm();
      addTearDown(vm.dispose);
      vm.website.text = 'exa';
      expect(vm.errorOf(StartupField.website), isNull);
      vm.website.text = 'exa.';
      expect(
        vm.errorOf(StartupField.website),
        'Enter a valid website, like example.com or https://example.com',
      );
      vm.website.text = 'example.com';
      expect(vm.errorOf(StartupField.website), isNull);
    });

    test('limits: 350 / 350 / 250, market size more than 0', () {
      expect(Startup.problemMax, 350);
      expect(Startup.solutionMax, 350);
      expect(Startup.customersMax, 250);
      final vm = _vm();
      addTearDown(vm.dispose);
      expect(
        vm.errorOf(StartupField.marketSize),
        isNull,
        reason: 'empty waits for Next',
      );
      vm.tam.text = '0';
      expect(
        vm.errorOf(StartupField.marketSize),
        'Target market size must be more than 0.',
      );
    });
  });

  group('Part 4: Finance and Growth', () {
    test('runway line', () {
      expect(Runway.label(100000, null), isNull);
      expect(Runway.label(100000, 0), 'Cash-flow positive');
      expect(Runway.label(0, 5000), 'No runway left');
      expect(Runway.label(100000, 20000), 'About 5 months of runway');
      expect(Runway.label(1000, 20000), 'About 1 month of runway');
      expect(Runway.short(100000, 20000), 'About 5 months');
      final vm = _vm();
      addTearDown(vm.dispose);
      vm.capital.text = '350,000';
      vm.burn.text = '50,000';
      expect(vm.runwayLine, 'About 7 months of runway');
    });

    test('every field is required, 0 is fine for revenue and burn', () {
      final vm = _vm();
      addTearDown(vm.dispose);
      vm.step = 3;
      expect(vm.currentComplete, isFalse);
      vm.next();
      expect(
        vm.errorOf(StartupField.revenueNow),
        'Please enter your revenue. Enter 0 if you haven’t made any yet.',
      );
      expect(
        vm.errorOf(StartupField.burn),
        'Please enter your monthly burn rate. Enter 0 if you earn more than you spend.',
      );
      expect(
        vm.errorOf(StartupField.valuation),
        'Please enter your current valuation.',
      );
      expect(
        vm.errorOf(StartupField.modelText),
        'Please explain your business model.',
      );
      vm.revenueNow.text = '0';
      vm.capital.text = '1';
      vm.burn.text = '0';
      vm.valuation.text = '0';
      vm.rev1.text = '1';
      vm.rev2.text = '1';
      vm.rev3.text = '1';
      vm.modelText.text = 'Subscriptions';
      expect(vm.currentComplete, isTrue);
    });
  });

  group('Part 5: Startup Ask', () {
    test('round amount limits', () {
      expect(RoundLimits.allows(StartupStage.preSeed, 150000), isTrue);
      expect(RoundLimits.allows(StartupStage.preSeed, 149999), isFalse);
      expect(RoundLimits.allows(StartupStage.preSeed, 2000000), isTrue);
      expect(RoundLimits.allows(StartupStage.seed, 2000000), isFalse);
      expect(RoundLimits.allows(StartupStage.seed, 7500000), isTrue);
      expect(RoundLimits.allows(StartupStage.seriesA, 55000000), isTrue);
      expect(RoundLimits.allows(StartupStage.seriesB, 190000001), isFalse);
      expect(RoundLimits.allows(StartupStage.seriesC, 190000001), isTrue);
      expect(
        RoundLimits.hint(StartupStage.preSeed),
        'Pre-seed: SAR 150,000 to 2,000,000',
      );
      expect(
        RoundLimits.hint(StartupStage.seed),
        'Seed: over SAR 2,000,000 to 7,500,000',
      );
      expect(
        RoundLimits.hint(StartupStage.seriesC),
        'Series C: over SAR 190,000,000',
      );
      expect(
        RoundLimits.error(StartupStage.preSeed, 5),
        'That amount isn’t in the Pre-seed range. Enter between SAR 150,000 and SAR 2,000,000.',
      );
      expect(
        RoundLimits.error(StartupStage.seed, 9000000),
        'That amount isn’t in the Seed range. Enter more than SAR 2,000,000 and up to SAR 7,500,000.',
      );
      expect(
        RoundLimits.error(StartupStage.seriesC, 1),
        'That amount isn’t in the Series C range. Enter more than SAR 190,000,000.',
      );
    });

    test('nothing is ticked; only the ticked boxes ask questions', () {
      final vm = _vm();
      addTearDown(vm.dispose);
      vm.step = 4;
      expect(vm.lookingFor, isEmpty);
      expect(vm.currentComplete, isFalse);
      vm.next();
      expect(vm.errorOf(StartupField.lookingFor), 'Select at least one.');
      vm.toggleLookingFor('Partnership');
      expect(vm.currentComplete, isFalse);
      expect(
        vm.errorOf(StartupField.partnerTypes),
        'Select at least one partner type.',
      );
      vm.togglePartner('Technology');
      expect(vm.currentComplete, isTrue, reason: 'no funding questions');
      vm.toggleLookingFor('Support');
      expect(
        vm.errorOf(StartupField.supportTypes),
        'Select at least one support type.',
      );
      vm.toggleSupport('Other');
      expect(vm.currentComplete, isFalse, reason: 'Other needs text');
      vm.supportOther.text = 'Legal help';
      expect(vm.currentComplete, isTrue);
    });

    test('funding amount follows the Stage and says so at once', () {
      final vm = _vm(stage: StartupStage.seed);
      addTearDown(vm.dispose);
      vm.toggleLookingFor('Funding');
      vm.step = 4;
      expect(vm.fundingHint, 'Seed: over SAR 2,000,000 to 7,500,000');
      vm.funding.text = '5,000';
      expect(
        vm.errorOf(StartupField.funding),
        'That amount isn’t in the Seed range. Enter more than SAR 2,000,000 and up to SAR 7,500,000.',
      );
      vm.funding.text = '500,000';
      expect(
        vm.errorOf(StartupField.funding),
        'That amount isn’t in the Seed range. Enter more than SAR 2,000,000 and up to SAR 7,500,000.',
      );
      vm.funding.text = '3,000,000';
      expect(vm.errorOf(StartupField.funding), isNull);
      vm.raised.text = '4,000,000';
      expect(
        vm.errorOf(StartupField.raised),
        'This can’t be more than the amount you’re raising.',
      );
      vm.raised.text = '0';
      vm.setLead(false);
      expect(vm.currentComplete, isTrue);
    });

    test('saves what was chosen', () async {
      final vm = _vm();
      addTearDown(vm.dispose);
      vm.name.text = 'Nakhla Pay';
      vm.description.text = 'We help shops.';
      vm.selectSector('Fintech', null);
      vm.selectModel('Business-to-Business (B2B)', null);
      vm.selectCity('Jeddah');
      vm.toggleLookingFor('Funding');
      vm.toggleLookingFor('Partnership');
      vm.funding.text = '1,000,000';
      vm.raised.text = '200,000';
      vm.setLead(true);
      vm.togglePartner('Technology');
      vm.togglePartner('Other');
      vm.partnerOther.text = 'Banks';
      vm.revenueNow.text = '10';
      vm.burn.text = '5';
      vm.modelText.text = 'Fees per payment';
      final saved = await vm.save();
      expect(saved!.raisedInRound, 200000);
      expect(saved.fundingRequirement, 1000000);
      expect(saved.revenueThisYear, 10);
      expect(saved.monthlyBurn, 5);
      expect(saved.businessModelText, 'Fees per payment');
      expect(saved.partnerTypes, ['Technology', 'Banks']);
      expect(saved.supportTypes, isEmpty);
      expect(saved.lookingFor, {LookingFor.funding, LookingFor.partnership});
    });
  });

  group('Part 6: Startup Team', () {
    setUp(() => AppSession.instance.signIn(_founder));

    test('the founder is first, locked, and must add role + contribution', () {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      final me = vm.team.first;
      expect(me.isFounder, isTrue);
      expect(me.name, 'Shahad Alabdulkarim');
      expect(me.email, 'shahad@gmail.com');
      expect(vm.stepComplete(StartupStepsViewModel.teamStep), isFalse);
      vm.openMemberEditor(0);
      expect(vm.editingFounder, isTrue);
      expect(vm.memberError(vm.memberName), isNull);
      vm.memberRole.text = 'CEO';
      vm.memberContribution.text = 'Leads the company';
      expect(vm.memberComplete, isTrue);
    });

    test('founder row completes the step', () async {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      vm.openMemberEditor(0);
      vm.memberRole.text = 'CEO';
      vm.memberContribution.text = 'Leads the company';
      expect(await vm.saveMember(), MemberSave.saved);
      expect(vm.stepComplete(StartupStepsViewModel.teamStep), isTrue);
      expect(vm.team.first.role, 'CEO');
      expect(vm.team.first.isFounder, isTrue);
    });

    test('unknown e-mail: invite dialog, then an Invited member', () async {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      vm.openMemberEditor();
      vm.memberName.text = 'Sara Alamri';
      vm.memberEmail.text = 'sara.alamri@gmail.com';
      vm.memberRole.text = 'COO';
      vm.memberContribution.text = 'Operations';
      expect(await vm.saveMember(), MemberSave.needsInvite);
      expect(vm.team, hasLength(1));
      vm.setMemberCoFounder(true);
      expect(await vm.saveMember(inviteConfirmed: true), MemberSave.invited);
      final sara = vm.team.last;
      expect(sara.invited, isTrue);
      expect(sara.coFounder, isTrue);
      expect(sara.uid, isNull);
    });

    test(
      'registered e-mail fills in the name; duplicates are refused',
      () async {
        final vm = StartupStepsViewModel();
        addTearDown(vm.dispose);
        vm.openMemberEditor();
        vm.memberName.text = 'Someone';
        vm.memberEmail.text = 'NORA.alharbi@gmail.com';
        vm.memberRole.text = 'CMO';
        vm.memberContribution.text = 'Marketing';
        expect(await vm.saveMember(), MemberSave.saved);
        expect(vm.team.last.name, 'Nora Alharbi');
        expect(vm.team.last.invited, isFalse);
        expect(vm.team.last.uid, 'sample-nora');
        vm.openMemberEditor();
        vm.memberName.text = 'Nora Alharbi';
        vm.memberEmail.text = 'nora.alharbi@gmail.com';
        vm.memberRole.text = 'x';
        vm.memberContribution.text = 'y';
        expect(
          vm.memberError(vm.memberEmail),
          'This person is already on the team.',
        );
        expect(await vm.saveMember(), MemberSave.invalid);
        for (final bad in [
          'bad',
          'name@gmail.co',
          'name@gmail.org',
          'a@b.xyz',
        ]) {
          vm.memberEmail.text = bad;
          expect(
            vm.memberError(vm.memberEmail),
            'Enter a valid email, like name@example.com',
            reason: bad,
          );
        }
        vm.memberEmail.text = 'student@ksu.edu.sa';
        expect(vm.memberError(vm.memberEmail), isNull);
        vm.memberEmail.text = 'bad';
        expect(
          vm.memberError(vm.memberEmail),
          'Enter a valid email, like name@example.com',
        );
      },
    );
  });
}
