import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/founder_tools_strings.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/activity_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/funding_round_repository.dart';
import 'package:startsa/data_access/repositories/interest_repository.dart';
import 'package:startsa/data_access/repositories/request_repository.dart';
import 'package:startsa/data_access/repositories/startup_draft_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/connection_requests/view_models/interest_view_model.dart';
import 'package:startsa/features/connection_requests/view_models/requests_view_model.dart';
import 'package:startsa/features/fundraising_calculator/screens/valuation_calculator_screen.dart';
import 'package:startsa/features/fundraising_calculator/view_models/valuation_calculator_view_model.dart';
import 'package:startsa/features/startups/screens/manage_startup_screen.dart';
import 'package:startsa/features/startups/screens/my_startups_screen.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_flow.dart';
import 'package:startsa/features/startups/screens/startup_steps_screen.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/shared_ui/widgets/overlays/picker_sheet.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/features/startups/widgets/startup_step_body.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/connection_request.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/headers/tabbed_header.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

import '../../support/fakes.dart';

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  navigatorKey: AppToast.navigatorKey,
  home: home,
);

/// A field label (rich text, because of the red star).
Finder _label(String text) => find.textContaining(text, findRichText: true);

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1236, 2676);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// The Finance and Growth / Startup Ask answers older sample startups lack.
Startup _withNewAnswers(Startup s) => s.copyWith(
  revenueThisYear: 0,
  monthlyBurn: 0,
  businessModelText: 'Monthly subscriptions',
  raisedInRound: 0,
);

/// Fills every required answer of all four steps.
void _fillAll(StartupStepsViewModel vm) {
  vm.name.text = 'Nakhla Pay';
  vm.description.text = 'We help small shops accept card payments.';
  vm.selectSector('Fintech', null);
  vm.selectStage('Seed');
  vm.selectModel('Business-to-Business (B2B)', null);
  vm.selectCity('Jeddah');
  vm.founded.text = '2024';
  vm.problem.text = 'p';
  vm.solution.text = 's';
  vm.customers.text = 'c';
  vm.advantage.text = 'a';
  vm.tam.text = '2,400,000,000';
  vm.revenueNow.text = '0';
  vm.capital.text = '350,000';
  vm.burn.text = '50,000';
  vm.modelText.text = 'Monthly subscriptions';
  vm.rev1.text = '1,000';
  vm.rev2.text = '2,000';
  vm.rev3.text = '3,000';
  vm.valuation.text = '0';
  vm.toggleLookingFor('Funding');
  vm.funding.text = '3,000,000';
  vm.raised.text = '0';
}

void main() {
  late FakeStartupRepository repo;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    repo = FakeStartupRepository();
    StartupRepository.instance = repo;
    UserRepository.instance = FakeUserRepository();
    RequestRepository.instance = RequestRepository(sample: true);
    InterestRepository.instance = InterestRepository(sample: true);
    ActivityRepository.instance = ActivityRepository(sample: true);
    DiscoveryRepository.instance = DiscoveryRepository.sample();
    FundingRoundRepository.instance = FundingRoundRepository.sample();
    AppSession.instance = AppSession();
  });

  group('StartupStepsViewModel', () {
    test('Next is gated by each step and errors only show once tried', () {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      expect(vm.currentComplete, isFalse);
      expect(vm.errorOf(StartupField.name), isNull);
      expect(vm.next(), StepAdvance.incomplete);
      expect(vm.errorOf(StartupField.name), 'Please enter a startup name.');
      expect(vm.step, 0);
      _fillAll(vm);
      expect(vm.next(), StepAdvance.advanced);
      expect(vm.step, 1);
      expect(vm.next(), StepAdvance.advanced);
      expect(vm.next(), StepAdvance.advanced);
      expect(vm.step, 3);
      expect(vm.next(), StepAdvance.advanced);
      expect(vm.step, StartupStepsViewModel.teamStep);
      expect(vm.next(), StepAdvance.advanced);
      // The Startup Ask is the last step.
      expect(vm.step, StartupStepsViewModel.askStep);
      expect(vm.next(), StepAdvance.readyToSave);
      expect(vm.previous(), isTrue);
    });

    test('Startup Team comes before the Startup Ask (the last step)', () {
      expect(StartupStepsViewModel.stepCount, 6);
      expect(StartupStepsViewModel.sectionSteps, [0, 1, 2, 3, 4, 5]);
      expect(FounderToolsStrings.stepTitles, [
        'Startup Overview',
        'Startup Description',
        'Target Market',
        'Finance and Growth',
        'Startup Team',
        'Startup Ask',
      ]);
      expect(StartupStepsViewModel.teamStep, 4);
      expect(StartupStepsViewModel.askStep, 5);
      // Each Details section still opens its own step.
      final team = StartupStepsViewModel(onlySection: 4);
      addTearDown(team.dispose);
      expect(team.step, 4);
      final ask = StartupStepsViewModel(onlySection: 5);
      addTearDown(ask.dispose);
      expect(ask.step, 5);
    });

    test('a draft saved before the swap reopens on the same step', () {
      final old = StartupStepsViewModel();
      addTearDown(old.dispose);
      // Before the swap the Startup Ask was step 4 and the Team step 5.
      final draft = {...old.toDraft()}
        ..remove('order')
        ..['step'] = 4;
      final restored = StartupStepsViewModel()..loadDraft(draft);
      addTearDown(restored.dispose);
      expect(restored.step, StartupStepsViewModel.askStep);
    });

    test(
      'founded year: 4 digits starting with 2, error from the first key',
      () {
        final vm = StartupStepsViewModel(now: DateTime(2026, 10, 19));
        addTearDown(vm.dispose);
        const msg = 'Enter a 4-digit year starting with 2, like 2024.';
        expect(vm.errorOf(StartupField.founded), isNull, reason: 'untouched');
        for (final bad in ['1', '2', '20', '202', '1800', '0999', '1999']) {
          vm.founded.text = bad;
          expect(vm.errorOf(StartupField.founded), msg, reason: bad);
        }
        // A future year is fine.
        for (final good in ['2000', '2024', '2026', '2099', '2500']) {
          vm.founded.text = good;
          expect(vm.errorOf(StartupField.founded), isNull, reason: good);
        }
      },
    );

    test('website is checked from the first character; empty is fine', () {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      const msg = 'Enter a valid website, like example.com';
      expect(vm.errorOf(StartupField.website), isNull);
      vm.website.text = 'e';
      expect(vm.errorOf(StartupField.website), msg);
      vm.website.text = 'example';
      expect(vm.errorOf(StartupField.website), msg);
      vm.website.text = 'example.com';
      expect(vm.errorOf(StartupField.website), isNull);
      vm.website.text = 'www.example.sa';
      expect(vm.errorOf(StartupField.website), isNull);
      vm.website.text = 'https://example.com';
      expect(vm.errorOf(StartupField.website), isNull);
      vm.website.text = '';
      expect(vm.errorOf(StartupField.website), isNull);
    });

    test('Other cannot repeat a listed sector or commerce model', () {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      const msg = 'This option is already in the list. Select it instead.';
      vm.selectSector('Other', 'fintechs');
      expect(vm.errorOf(StartupField.sectorOther), msg);
      expect(vm.stepComplete(0), isFalse);
      vm.sectorOther.text = 'Fin Tech';
      expect(vm.errorOf(StartupField.sectorOther), msg);
      vm.sectorOther.text = 'Beekeeping';
      expect(vm.errorOf(StartupField.sectorOther), isNull);
      vm.selectModel('Other', 'b2b');
      expect(vm.errorOf(StartupField.modelOther), msg);
      vm.modelOther.text = 'Subscription boxes';
      expect(vm.errorOf(StartupField.modelOther), isNull);
    });

    test('valuation 0 is allowed; empty shows its message', () {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      _fillAll(vm);
      vm.step = 3;
      expect(vm.currentComplete, isTrue);
      vm.valuation.clear();
      expect(vm.currentComplete, isFalse);
      vm.next();
      expect(
        vm.errorOf(StartupField.valuation),
        'Please enter your current valuation.',
      );
      expect(vm.hasError(StartupField.valuation), isTrue);
    });

    test('team member editor blocks Next and validates', () async {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      _fillAll(vm);
      vm.step = StartupStepsViewModel.teamStep;
      expect(vm.currentComplete, isTrue);
      vm.openMemberEditor();
      expect(vm.next(), StepAdvance.memberOpen);
      expect(await vm.saveMember(), MemberSave.invalid);
      expect(vm.memberError(vm.memberName), 'Please enter their full name.');
      expect(vm.memberError(vm.memberEmail), 'Please enter their email.');
      expect(vm.memberError(vm.memberRole), 'Please enter the role.');
      expect(
        vm.memberError(vm.memberContribution),
        'Please describe the contribution.',
      );
      vm.memberName.text = 'Faisal Alkhaldi';
      vm.memberEmail.text = 'faisal.alkhaldi@gmail.com';
      vm.memberRole.text = 'CTO';
      vm.memberContribution.text = 'Built platforms';
      // Nobody is registered with that e-mail: invited.
      expect(await vm.saveMember(), MemberSave.needsInvite);
      expect(await vm.saveMember(inviteConfirmed: true), MemberSave.invited);
      expect(vm.team.single.meta, 'CTO');
      expect(vm.team.single.invited, isTrue);
      vm.openMemberEditor(0);
      vm.removeMember();
      expect(vm.team, isEmpty);
      expect(vm.editorOpen, isFalse);
    });

    test('save creates a public startup with the pitch as tagline', () async {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      _fillAll(vm);
      expect(vm.isPublic, isTrue);
      expect(vm.lookingFor, {LookingFor.funding});
      final saved = await vm.save();
      expect(saved, isNotNull);
      // The one-line pitch is gone: the brief description is the only text.
      expect(repo.startups.single.tagline, isNull);
      expect(
        repo.startups.single.description,
        'We help small shops accept card payments.',
      );
      expect(repo.startups.single.fundingRequirement, 3000000);
      expect(repo.startups.single.valuation, 0);
      expect(AppSession.instance.ownStartupIds, contains(saved!.id));
    });

    test('edit mode starts from the startup and updates it', () async {
      final s = _withNewAnswers(PrototypeSeed.rafeeq.copyWith(id: 'x1'));
      repo.startups.add(s);
      final vm = StartupStepsViewModel(initial: s);
      addTearDown(vm.dispose);
      expect(vm.isEditing, isTrue);
      expect(vm.stepComplete(0), isTrue);
      expect(vm.stepComplete(3), isTrue);
      expect(vm.stepComplete(4), isTrue);
      vm.name.text = 'Rafeeq Care';
      final saved = await vm.save();
      expect(saved!.name, 'Rafeeq Care');
      expect(repo.startups.single.name, 'Rafeeq Care');
    });
  });

  group('ValuationCalculatorViewModel', () {
    test('starts from the round and the current valuation', () {
      // 2M at an 8M valuation = 20%
      expect(
        ValuationCalculatorViewModel.equityAt(
          funding: 2000000,
          valuation: 8000000,
        ),
        20,
      );
      final vm = ValuationCalculatorViewModel(
        funding: 2000000,
        valuation: 8000000,
      );
      addTearDown(vm.dispose);
      expect(vm.funds.text, '2,000,000');
      expect(vm.equity.text, '20');
      expect(vm.ownership.text, '100');
      expect(vm.ownershipHint, isNull);
      expect(vm.postText, 'SAR 10,000,000');
      expect(vm.preText, 'SAR 8,000,000');
      // no valuation, nothing to work out
      expect(
        ValuationCalculatorViewModel.equityAt(funding: 1, valuation: 0),
        isNull,
      );
    });

    test('more funding costs more equity; the valuation stays', () {
      final vm = ValuationCalculatorViewModel(
        funding: 2000000,
        valuation: 8000000,
      );
      addTearDown(vm.dispose);
      vm.funds.text = '3,000,000';
      expect(vm.equity.text, '27.27');
      expect(vm.preText, 'SAR 8,000,000');
      expect(vm.postText, 'SAR 11,000,000');
      expect(vm.equityError, isNull);
      // typed equity stays even if funding changes
      vm.equity.text = '25';
      expect(vm.preText, 'SAR 9,000,000');
      vm.funds.text = '2,000,000';
      expect(vm.equity.text, '25');
      expect(vm.preText, 'SAR 6,000,000');
    });

    test('an uneven equity keeps the pre-money exactly the valuation', () {
      final vm = ValuationCalculatorViewModel(
        funding: 2000000,
        valuation: 7000000,
      );
      addTearDown(vm.dispose);
      expect(vm.equity.text, '22.22');
      expect(vm.preText, 'SAR 7,000,000');
      expect(vm.workText, 'SAR 2,000,000 ÷ 22.22%');
    });

    test('a note when the terms don\'t match the valuation', () {
      final vm = ValuationCalculatorViewModel(
        funding: 3000000,
        valuation: 9000000,
      );
      addTearDown(vm.dispose);
      // just opened: same as the valuation, no note
      expect(vm.valuationNote, isNull);
      vm.funds.text = '4,000,000';
      expect(vm.valuationNote, isNull, reason: 'equity followed the funding');
      vm.funds.text = '3,000,000';
      vm.equity.text = '30';
      expect(vm.preText, 'SAR 7,000,000');
      expect(vm.valuationLower, isTrue);
      expect(
        vm.valuationNote,
        'Lower than your valuation (SAR 9,000,000). At your valuation, '
        'SAR 3,000,000 would cost 25% of your company, not 30%, so you\'d '
        'give away more.',
      );
      vm.equity.text = '20';
      expect(vm.valuationLower, isFalse);
      expect(vm.valuationNote, startsWith('Higher than your valuation'));
      expect(vm.valuationNote, endsWith('so you\'d keep more.'));
      vm.equity.text = '25';
      expect(vm.valuationNote, isNull);
      vm.equity.text = '';
      expect(vm.valuationNote, isNull, reason: 'no result, no note');
    });

    test('a request keeps its equity and is compared too', () {
      final vm = ValuationCalculatorViewModel(
        funding: 1000000,
        equityPercent: 12.5,
        valuation: 9000000,
      );
      addTearDown(vm.dispose);
      expect(vm.equity.text, '12.5');
      expect(vm.preText, 'SAR 7,000,000');
      expect(vm.valuationNote, contains('would cost 10% of your company'));
      vm.funds.text = '2,000,000';
      expect(vm.equity.text, '12.5', reason: 'the investor\'s equity stays');
    });

    test('funding at least 1,000, ownership above 0, 2 decimals', () {
      final vm = ValuationCalculatorViewModel(funding: 3000000, valuation: 9000000);
      addTearDown(vm.dispose);
      vm.funds.text = '500';
      expect(vm.fundingError, 'The amount must be at least SAR 1,000.');
      expect(vm.isValid, isFalse);
      vm.funds.text = '';
      expect(vm.fundingError, 'Enter the amount you want to raise.');
      vm.funds.text = '1,000';
      expect(vm.fundingError, isNull);
      vm.ownership.text = '0';
      expect(vm.ownershipError, 'Enter a percentage above 0 and up to 100.');
      vm.ownership.text = '100';
      expect(vm.ownershipError, isNull);
      // the percent boxes take one dot and 2 decimals at most
      String type(String old, String next) => ValuationCalculatorViewModel
          .percentInput
          .formatEditUpdate(
            TextEditingValue(text: old),
            TextEditingValue(text: next),
          )
          .text;
      expect(type('25.7', '25.75'), '25.75');
      expect(type('25.75', '25.755'), '25.75');
      expect(type('2.5', '2.5.'), '2.5');
      expect(type('', 'a'), '');
      // nothing above 100, no extra zeros in front
      expect(type('100', '1000'), '100');
      expect(type('10', '101'), '10');
      expect(type('100', '100.5'), '100');
      expect(type('0', '00'), '0');
      expect(type('0', '05'), '0');
      expect(type('0', '0.5'), '0.5');
      expect(type('99.9', '99.99'), '99.99');
    });

    test('rounding never makes a note', () {
      final vm = ValuationCalculatorViewModel(
        funding: 2000000,
        valuation: 7000000,
      );
      addTearDown(vm.dispose);
      vm.equity.text = '22.22';
      expect(vm.valuationNote, isNull);
    });

    test('co-founders or earlier rounds: ownership asks, with a hint', () {
      final vm = ValuationCalculatorViewModel(
        funding: 2000000,
        valuation: 8000000,
        ownershipUnknown: true,
      );
      addTearDown(vm.dispose);
      expect(vm.ownership.text, '');
      expect(vm.ownershipHint, isNotNull);
      expect(vm.ownershipError, isNull, reason: 'not typed yet');
      expect(vm.isValid, isFalse);
      vm.ownership.text = '50';
      expect(vm.ownershipHint, isNull);
      expect(vm.isValid, isTrue);
      expect(ValuationCalculatorViewModel.pct(vm.you), '40%');
    });

    test('ownership starts fresh each time, and 1.2.3 is not a number', () {
      final a = ValuationCalculatorViewModel();
      a.ownership.text = '60';
      a.dispose();
      final b = ValuationCalculatorViewModel();
      addTearDown(b.dispose);
      expect(b.ownership.text, '100');
      expect(ValuationCalculatorViewModel.parse('1.2.3').isNaN, isTrue);
      expect(ValuationCalculatorViewModel.parse('12.5'), 12.5);
    });

    test('math matches the prototype example', () {
      final vm = ValuationCalculatorViewModel(
        funding: 500000,
        equityPercent: 10,
      );
      addTearDown(vm.dispose);
      vm.ownership.text = '80';
      expect(vm.isValid, isTrue);
      expect(vm.postText, 'SAR 5,000,000');
      expect(vm.workText, 'SAR 500,000 ÷ 10%');
      expect(vm.preText, 'SAR 4,500,000');
      expect(vm.shareText, 'SAR 3,600,000');
      expect(ValuationCalculatorViewModel.pct(vm.you), '72%');
      expect(ValuationCalculatorViewModel.pct(vm.others), '18%');
      expect(vm.youWork, '80% × 90%');
      expect(vm.othersWork, '20% × 90%');
      expect(vm.hasOthers, isTrue);
    });

    test('empty start shows no errors; they appear once you type', () {
      var vm = ValuationCalculatorViewModel();
      expect(vm.fundingError, isNull, reason: 'just opened: nothing is red');
      expect(vm.equityError, isNull);
      expect(vm.ownershipError, isNull);
      expect(vm.isValid, isFalse, reason: 'but there is no result yet');
      vm.funds.text = '5';
      vm.funds.text = '';
      expect(vm.fundingError, 'Enter the amount you want to raise.');
      vm.equity.text = '100';
      expect(vm.equityError, 'Enter a percentage above 0 and below 100.');
      vm.dispose();
      vm = ValuationCalculatorViewModel();
      expect(vm.postText, 'SAR —');
      expect(vm.workText, 'Fill in the fields above');
      vm.ownership.text = '60';
      vm.dispose();
      vm = ValuationCalculatorViewModel();
      addTearDown(vm.dispose);
      expect(vm.ownership.text, '100');
      vm.ownership.text = '120';
      expect(vm.ownershipError, 'Enter a percentage above 0 and up to 100.');
    });
  });

  group('Manage tab view models', () {
    test('requests filter, accept and decline', () {
      final vm = RequestsViewModel(startupId: 'mock-rafeeq');
      addTearDown(vm.dispose);
      expect(vm.count(RequestStatus.pending), 1);
      expect(vm.count(RequestStatus.accepted), 1);
      final row = vm.rows.single;
      expect(row.name, 'Omar Khalid');
      expect(row.sub, 'Angel Investor · 2h ago');
      expect(vm.accept(row), 'Omar Khalid');
      expect(vm.count(RequestStatus.pending), 0);
      expect(vm.count(RequestStatus.accepted), 2);
    });

    test('interest new / all and mark replied', () {
      final vm = InterestViewModel(startupId: 'mock-rafeeq');
      addTearDown(vm.dispose);
      expect(vm.newCount, 2);
      expect(vm.allCount, 3);
      expect(vm.visible, hasLength(2));
      vm.markReplied(vm.visible.first);
      expect(vm.newCount, 1);
      vm.select(onlyNew: false);
      expect(vm.visible, hasLength(3));
    });
  });

  group('screens', () {
    testWidgets('My Startups empty state', (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(_app(const MyStartupsScreen(teamStartups: [])));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Add your first startup'), findsOneWidget);
      expect(find.text(FounderToolsStrings.emptyButton), findsOneWidget);
      expect(find.text(FounderToolsStrings.addAction), findsNothing);
    });

    testWidgets('My Startups lists cards with the needs line', (tester) async {
      _bigScreen(tester);
      repo.startups.addAll([
        PrototypeSeed.rafeeq,
        PrototypeSeed.daftar.copyWith(isPublic: false),
      ]);
      await tester.pumpWidget(_app(const MyStartupsScreen(teamStartups: [])));
      await tester.pumpAndSettle();
      // No count line under the title any more.
      expect(find.text('2 startups'), findsNothing);
      expect(find.text('Rafeeq Health'), findsOneWidget);
      expect(find.text('Raising SAR 500,000'), findsOneWidget);
      expect(find.text('Looking for partnership'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);
      expect(AppSession.instance.ownStartupIds, {'mock-rafeeq', 'mock-daftar'});
    });

    testWidgets('Manage: tabs, requests accept, interest, settings', (
      tester,
    ) async {
      _bigScreen(tester);
      await tester.pumpWidget(
        _app(ManageStartupScreen(startup: PrototypeSeed.rafeeq)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rafeeq Health'), findsOneWidget);
      // Header: role label above the name, six tabs, eye + share icons.
      expect(find.text('FOUNDER'), findsOneWidget);
      for (final tab in [
        'Dashboard',
        'Details',
        'Rounds',
        'Requests',
        'Interest',
        'Settings',
      ]) {
        expect(find.text(tab), findsWidgets, reason: tab);
      }
      expect(find.bySemanticsLabel('Preview profile'), findsOneWidget);
      expect(find.bySemanticsLabel('Share'), findsOneWidget);
      // Dashboard: the two tiles, the calculator and the investors card.
      expect(find.text('Raising'), findsOneWidget);
      expect(find.text('Valuation'), findsOneWidget);
      expect(find.text('Valuation calculator'), findsOneWidget);
      expect(find.text('Associated investors'), findsOneWidget);
      expect(find.text('128'), findsOneWidget);
      expect(find.text('Ahmad Hassan'), findsOneWidget);

      await tester.tap(find.text('7D'));
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text('14'), findsOneWidget);

      // The tab bar scrolls sideways: bring the tab into view, then tap it.
      Finder tab(String label) => find.descendant(
        of: find.byType(ScrollableHeaderTabBar),
        matching: find.text(label),
      );
      await tester.ensureVisible(tab('Requests'));
      await tester.pumpAndSettle();
      await tester.tap(tab('Requests'));
      await tester.pumpAndSettle();
      expect(find.text('Pending · 1'), findsOneWidget);
      expect(find.text('SAR 300,000 for 15%'), findsOneWidget);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      // Confirmations show no pop-up any more; the request just leaves the list.
      expect(find.text('No pending requests.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.ensureVisible(tab('Interest'));
      await tester.pumpAndSettle();
      await tester.tap(tab('Interest'));
      await tester.pumpAndSettle();
      expect(find.text('New · 2'), findsOneWidget);
      expect(find.text('Noura Alharbi'), findsOneWidget);

      await tester.ensureVisible(tab('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(tab('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Public profile'), findsOneWidget);
      await tester.tap(find.text('Delete startup'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Rafeeq Health?'), findsOneWidget);
    });

    testWidgets('the share icon copies the link and says so', (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(
        _app(ManageStartupScreen(startup: PrototypeSeed.rafeeq)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Share'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Link copied'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Add startup step 1 at 360 px: off button shows errors', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(const StartupStepsScreen(mode: StartupStepsMode.add)),
      );
      await tester.pumpAndSettle();
      expect(find.text('STEP 1 OF 6'), findsOneWidget);
      expect(find.text('Startup Overview'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Please fix the highlighted fields'), findsOneWidget);
      expect(find.text('Please enter a startup name.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Basics has one Brief description and ends with Visibility', (
      tester,
    ) async {
      _bigScreen(tester);
      await tester.pumpWidget(
        _app(const StartupStepsScreen(mode: StartupStepsMode.add)),
      );
      await tester.pumpAndSettle();
      expect(find.text('One-line pitch'), findsNothing);
      expect(find.text('Description'), findsNothing);
      expect(_label('Brief Description'), findsOneWidget);
      // Visibility is the last field of the step, under Website.
      final website = tester.getTopLeft(_label('Website')).dy;
      final visibility = tester.getTopLeft(_label('Visibility')).dy;
      expect(visibility, greaterThan(website));
      // Empty: the brief description asks to be filled in.
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Please describe your startup.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Visibility is gone from the Funding & goals step', (
      tester,
    ) async {
      _bigScreen(tester);
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(
              child: StartupStepBody(vm: vm, step: 3),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_label('Visibility'), findsNothing);
    });

    testWidgets('Onboarding numbering starts at STEP 3 OF 8', (tester) async {
      _bigScreen(tester);
      SignupFlow.current = SignupFlow(role: AccountRole.founder)
        ..accountCreated = true;
      await tester.pumpWidget(
        _app(const StartupStepsScreen(mode: StartupStepsMode.onboarding)),
      );
      await tester.pumpAndSettle();
      expect(find.text('STEP 3 OF 8'), findsOneWidget);
      expect(find.text('Startup Overview'), findsOneWidget);
    });

    testWidgets('Back on onboarding step 3 returns to the Verify step', (
      tester,
    ) async {
      _bigScreen(tester);
      SignupFlow.current = SignupFlow(role: AccountRole.founder)
        ..email = 'a@b.co'
        ..accountCreated = true;
      await tester.pumpWidget(
        _app(const StartupStepsScreen(mode: StartupStepsMode.onboarding)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      expect(find.text('Verify your email'), findsOneWidget);
      SignupFlow.current = null;
    });

    testWidgets('a picker with its own Other row shows Other once', (
      tester,
    ) async {
      _bigScreen(tester);
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showPickerSheet(
                context,
                title: 'Commerce model',
                options: [for (final m in BusinessModel.values) m.label],
                otherNoun: 'commerce model',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Other'), findsOneWidget);
    });

    test('team member needs a first and last name, live', () {
      final vm = StartupStepsViewModel();
      vm.memberName.text = 'Faisal';
      expect(vm.memberError(vm.memberName), 'Enter your first and last name.');
      vm.memberName.text = 'Faisal Alkhaldi';
      expect(vm.memberError(vm.memberName), isNull);
    });

    for (final choice in ['Discard', 'Keep editing']) {
      testWidgets('Leaving a half-filled new startup: $choice', (tester) async {
        SharedPreferences.setMockInitialValues({});
        StartupDraftRepository.instance = StartupDraftRepository();
        AppSession.instance.signIn(
          const AppUser(
            uid: 'uid1',
            role: AccountRole.founder,
            fullName: 'Shahad Alabdulkarim',
            email: 'a@b.co',
          ),
        );
        _bigScreen(tester);
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (context) => TextButton(
                onPressed: () => StartupStepsScreen.openAdd(context),
                child: const Text('open form'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open form'));
        await tester.pumpAndSettle();
        final hint = find.widgetWithText(
          TextField,
          FounderToolsStrings.nameHint,
        );
        await tester.enterText(hint, 'Nakhla Pay');
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('Back').first);
        await tester.pumpAndSettle();
        expect(find.text('Discard this startup?'), findsOneWidget);
        expect(
          find.text(
            'If you go back now, the details you entered will be deleted.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text(choice));
        await tester.pumpAndSettle();
        final stillOnForm = hint.evaluate().isNotEmpty;
        final draft = StartupDraftRepository.instance.current.value;
        // Nothing is saved as a draft any more.
        expect(draft, isNull);
        if (choice == 'Keep editing') {
          expect(stillOnForm, isTrue);
        } else {
          expect(stillOnForm, isFalse, reason: '$choice must leave the form');
          expect(find.text('open form'), findsOneWidget);
        }
        await tester.pump(const Duration(seconds: 5));
      });
    }

    testWidgets('Save changes on the last step leaves the edit form', (
      tester,
    ) async {
      repo.startups.add(_withNewAnswers(PrototypeSeed.rafeeq));
      _bigScreen(tester);
      Startup? result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await StartupStepsScreen.pushEdit(
                context,
                _withNewAnswers(PrototypeSeed.rafeeq),
              ),
              child: const Text('edit'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('edit'));
      await tester.pumpAndSettle();
      // Change something so the form is "dirty" (the back guard is on).
      final name = find.widgetWithText(TextField, 'Rafeeq Health');
      await tester.enterText(name, 'Rafeeq Health Plus');
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Save changes'), findsOneWidget);
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(find.text('Save changes'), findsNothing, reason: 'left the form');
      expect(find.text('edit'), findsOneWidget);
      expect(result?.name, 'Rafeeq Health Plus');
      await tester.pump(const Duration(seconds: 5));
    });

    test('a draft remembers the furthest step even after going Back', () {
      final vm = StartupStepsViewModel();
      _fillAll(vm);
      expect(vm.next(), StepAdvance.advanced);
      expect(vm.next(), StepAdvance.advanced);
      expect(vm.step, 2);
      vm.previous();
      vm.previous();
      expect(vm.step, 0);
      final draft = vm.toDraft();
      expect(draft['step'], 2, reason: 'step 3 of 4');
      final reopened = StartupStepsViewModel()..loadDraft(draft);
      expect(reopened.step, 2);
    });

    test('a draft restores the form and an untouched form is not dirty', () {
      final vm = StartupStepsViewModel();
      expect(vm.isDirty, isFalse);
      vm.name.text = 'Nakhla Pay';
      vm.selectSector('Fintech', null);
      expect(vm.isDirty, isTrue);
      final draft = vm.toDraft();
      final other = StartupStepsViewModel()..loadDraft(draft);
      expect(other.name.text, 'Nakhla Pay');
      expect(other.sector, Sector.fintech);
      expect(other.isDirty, isFalse, reason: 'opening a draft is the baseline');
    });

    testWidgets(
      'Calculator shows the result and hides ownership when invalid',
      (tester) async {
        _bigScreen(tester);
        await tester.pumpWidget(
          _app(
            ValuationCalculatorScreen(
              startup: PrototypeSeed.rafeeq,
              funding: 500000,
              equityPercent: 10,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('SAR 5,000,000'), findsOneWidget);
        expect(find.text('Ownership after this raise'), findsOneWidget);
        expect(find.text('You (founder)'), findsOneWidget);
        expect(find.text('Other existing owners'), findsNothing);

        await tester.enterText(find.byType(TextField).at(1), '');
        await tester.pumpAndSettle();
        expect(find.text('Fill in the fields above'), findsOneWidget);
        expect(find.text('Ownership after this raise'), findsNothing);
        expect(
          find.text('Enter a percentage above 0 and below 100.'),
          findsOneWidget,
        );
      },
    );
  });
}
