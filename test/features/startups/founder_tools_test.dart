import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/founder_tools_strings.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/activity_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
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
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/connection_request.dart';
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

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1236, 2676);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Fills every required answer of all four steps.
void _fillAll(StartupStepsViewModel vm) {
  vm.name.text = 'Nakhla Pay';
  vm.pitch.text = 'Card payments on a phone';
  vm.description.text = 'We help small shops accept card payments.';
  vm.selectSector('Fintech', null);
  vm.selectStage('Seed', null);
  vm.selectModel('Business-to-Business (B2B)', null);
  vm.selectCity('Jeddah');
  vm.founded.text = '2024';
  vm.problem.text = 'p';
  vm.solution.text = 's';
  vm.customers.text = 'c';
  vm.advantage.text = 'a';
  vm.growth.text = 'g';
  vm.capital.text = '350,000';
  vm.rev1.text = '1,000';
  vm.rev2.text = '2,000';
  vm.rev3.text = '3,000';
  vm.valuation.text = '0';
  vm.setLead(true);
  vm.funding.text = '500,000';
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
    AppSession.instance = AppSession();
    ValuationCalculatorViewModel.lastOwnership = '100';
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
      expect(vm.next(), StepAdvance.readyToSave);
      expect(vm.previous(), isTrue);
    });

    test('founded year error shows as soon as 4 digits are typed', () {
      final vm = StartupStepsViewModel(now: DateTime(2026, 10, 19));
      addTearDown(vm.dispose);
      vm.founded.text = '1800';
      expect(
        vm.errorOf(StartupField.founded),
        'Enter a year between 1900 and 2026.',
      );
      vm.founded.text = '20';
      expect(vm.errorOf(StartupField.founded), isNull);
    });

    test('valuation 0 is allowed and has no error text', () {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      _fillAll(vm);
      vm.step = 3;
      expect(vm.currentComplete, isTrue);
      vm.valuation.clear();
      expect(vm.currentComplete, isFalse);
      vm.next();
      expect(vm.errorOf(StartupField.valuation), isNull);
      expect(vm.hasError(StartupField.valuation), isTrue);
    });

    test('team member editor blocks Next and validates', () {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      _fillAll(vm);
      vm.step = 2;
      expect(vm.currentComplete, isTrue);
      vm.openMemberEditor();
      expect(vm.next(), StepAdvance.memberOpen);
      expect(vm.saveMember(), isFalse);
      expect(vm.memberError(vm.memberName), 'Required');
      vm.memberName.text = 'Faisal Alkhaldi';
      vm.memberRole.text = 'CTO';
      vm.memberSpec.text = 'Mobile and cloud';
      vm.memberYears.text = '10';
      vm.memberBio.text = 'Built platforms';
      expect(vm.saveMember(), isTrue);
      expect(vm.team.single.meta, 'CTO · 10 yrs · Mobile and cloud');
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
      expect(repo.startups.single.tagline, 'Card payments on a phone');
      expect(repo.startups.single.fundingRequirement, 500000);
      expect(repo.startups.single.valuation, 0);
      expect(AppSession.instance.ownStartupIds, contains(saved!.id));
    });

    test('edit mode starts from the startup and updates it', () async {
      final s = PrototypeSeed.rafeeq.copyWith(id: 'x1');
      repo.startups.add(s);
      final vm = StartupStepsViewModel(initial: s);
      addTearDown(vm.dispose);
      expect(vm.isEditing, isTrue);
      expect(vm.stepComplete(0), isTrue);
      expect(vm.stepComplete(3), isTrue);
      vm.name.text = 'Rafeeq Care';
      final saved = await vm.save();
      expect(saved!.name, 'Rafeeq Care');
      expect(repo.startups.single.name, 'Rafeeq Care');
    });
  });

  group('ValuationCalculatorViewModel', () {
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

    test('empty start shows errors and keeps the last ownership', () {
      var vm = ValuationCalculatorViewModel();
      expect(vm.fundingError, 'Enter the amount you want to raise.');
      expect(vm.equityError, 'Enter a percentage above 0 and below 100.');
      expect(vm.ownershipError, isNull);
      expect(vm.postText, 'SAR —');
      expect(vm.workText, 'Fill in the fields above');
      vm.ownership.text = '60';
      vm.dispose();
      vm = ValuationCalculatorViewModel();
      addTearDown(vm.dispose);
      expect(vm.ownership.text, '60');
      vm.ownership.text = '120';
      expect(vm.ownershipError, 'Enter a percentage between 0 and 100.');
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
      await tester.pumpWidget(_app(const MyStartupsScreen()));
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
      await tester.pumpWidget(_app(const MyStartupsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('2 startups'), findsOneWidget);
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
      expect(find.text('Edit startup'), findsOneWidget);
      expect(find.text('128'), findsOneWidget);
      expect(find.text('Ahmad Hassan'), findsOneWidget);

      await tester.tap(find.text('7D'));
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text('14'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(HeaderTabBar),
          matching: find.text('Requests'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pending · 1'), findsOneWidget);
      expect(find.text('SAR 300,000 for 15%'), findsOneWidget);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(
        find.text('Omar Khalid is now an associated investor'),
        findsOneWidget,
      );
      expect(find.text('No pending requests.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Interest'));
      await tester.pumpAndSettle();
      expect(find.text('New · 2'), findsOneWidget);
      expect(find.text('Noura Alharbi'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Public profile'), findsOneWidget);
      await tester.tap(find.text('Delete startup'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Rafeeq Health?'), findsOneWidget);
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
      expect(find.text('STEP 1 OF 4'), findsOneWidget);
      expect(find.text('Basics'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Please fill in the required fields'), findsOneWidget);
      expect(find.text('Please enter a startup name.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Onboarding numbering starts at STEP 3 OF 6', (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(
        _app(const StartupStepsScreen(mode: StartupStepsMode.onboarding)),
      );
      await tester.pumpAndSettle();
      expect(find.text('STEP 3 OF 6'), findsOneWidget);
      expect(find.text('Add your startup'), findsOneWidget);
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

    testWidgets('Leaving a half-filled new startup offers a draft', (
      tester,
    ) async {
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
        _app(const StartupStepsScreen(mode: StartupStepsMode.add)),
      );
      await tester.pumpAndSettle();
      final hint = find.widgetWithText(TextField, FounderToolsStrings.nameHint);
      await tester.enterText(hint, 'Nakhla Pay');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      expect(find.text('Leave without finishing?'), findsOneWidget);
      expect(find.text('Save as draft'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Keep editing'), findsOneWidget);
      await tester.tap(find.text('Save as draft'));
      await tester.pumpAndSettle();
      final draft = StartupDraftRepository.instance.current.value;
      expect(draft?['name'], 'Nakhla Pay');
      await tester.pump(const Duration(seconds: 5));
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
