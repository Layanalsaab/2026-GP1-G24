import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/startup_strings.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/startups/screens/my_startups_screen.dart';
import 'package:startsa/features/startups/widgets/my_startup_card.dart';
import 'package:startsa/models/auth_failure.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/shared_ui/common_widgets/selection_chip.dart';

import '../../support/fakes.dart';

const _description =
    'We help small shops in Riyadh accept card payments with a phone.';

Startup _startup({bool isPublic = false}) => Startup(
  id: 's1',
  founderId: 'uid1',
  name: 'Nakhla Pay',
  description: _description,
  sector: Sector.fintech,
  stage: StartupStage.mvp,
  businessModel: BusinessModel.b2b,
  location: StartupLocation.riyadh,
  lookingFor: const {LookingFor.mentorship},
  isPublic: isPublic,
  updatedAt: DateTime.now(),
);

void main() {
  late FakeStartupRepository repo;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    repo = FakeStartupRepository();
    StartupRepository.instance = repo;
  });

  Future<void> pumpList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: const MyStartupsScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder field(int index) => find.byType(TextField).at(index);

  /// Opens a select field (shows "Choose <label>" while empty) and picks
  /// [options]; a multi-select is confirmed with Done.
  Future<void> choose(
    WidgetTester tester,
    String label,
    List<String> options, {
    bool multi = false,
  }) async {
    await tapText(tester, StartupStrings.choose(label));
    for (final option in options) {
      await tapText(tester, option);
    }
    if (multi) await tapText(tester, StartupStrings.done);
  }

  Future<void> fillRequired(
    WidgetTester tester, {
    String name = 'Nakhla Pay',
  }) async {
    await tester.enterText(field(0), name);
    await tester.enterText(field(2), _description);
    await choose(tester, StartupStrings.sectorLabel, [Sector.fintech.label]);
    await choose(tester, StartupStrings.stageLabel, [StartupStage.mvp.label]);
    await choose(tester, StartupStrings.locationLabel, [
      StartupLocation.jeddah.label,
    ]);
    await choose(tester, StartupStrings.businessModelLabel, [
      BusinessModel.b2b.label,
    ]);
    await choose(tester, StartupStrings.lookingForLabel, [
      LookingFor.mentorship.label,
    ], multi: true);
  }

  bool saveEnabled(WidgetTester tester, String label) {
    final button = find.ancestor(
      of: find.text(label),
      matching: find.byType(InkWell),
    );
    return tester.widget<InkWell>(button.first).onTap != null;
  }

  testWidgets('empty state, then add a startup (private by default)', (
    tester,
  ) async {
    await pumpList(tester);
    expect(find.text(StartupStrings.emptyTitle), findsOneWidget);

    await tapText(tester, StartupStrings.emptyButton);
    expect(find.text(StartupStrings.addTitle), findsOneWidget);
    expect(saveEnabled(tester, StartupStrings.saveNew), isFalse);
    expect(find.text(StartupStrings.visibilityOff), findsOneWidget);

    await fillRequired(tester);
    expect(saveEnabled(tester, StartupStrings.saveNew), isTrue);

    await tapText(tester, StartupStrings.saveNew);
    expect(repo.startups, hasLength(1));
    expect(repo.startups.single.isPublic, isFalse);
    expect(find.text('Nakhla Pay'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MyStartupCard),
        matching: find.text(StartupStrings.privateBadge),
      ),
      findsOneWidget,
    );
  });

  testWidgets('funding amount is asked only when Funding is selected', (
    tester,
  ) async {
    await pumpList(tester);
    await tapText(tester, StartupStrings.emptyButton);
    await fillRequired(tester);
    expect(find.textContaining(StartupStrings.fundingLabel), findsNothing);

    // The field now reads "Mentorship"; reopen it and add Funding.
    await tapText(tester, LookingFor.mentorship.label);
    await tapText(tester, LookingFor.funding.label);
    await tapText(tester, StartupStrings.done);
    expect(find.text('Funding, Mentorship'), findsOneWidget);
    expect(find.textContaining(StartupStrings.fundingLabel), findsOneWidget);
    // Required now, so Save is disabled until an amount is entered.
    expect(saveEnabled(tester, StartupStrings.saveNew), isFalse);
  });

  testWidgets('validation runs on submit and shows inline errors', (
    tester,
  ) async {
    await pumpList(tester);
    await tapText(tester, StartupStrings.emptyButton);
    await fillRequired(tester, name: 'ab');
    // No error while typing.
    expect(find.text(StartupStrings.nameLength(3, 60)), findsNothing);

    await tapText(tester, StartupStrings.saveNew);
    expect(find.text(StartupStrings.nameLength(3, 60)), findsOneWidget);
    expect(repo.startups, isEmpty);
  });

  testWidgets('leaving with unsaved changes asks to discard', (tester) async {
    await pumpList(tester);
    await tapText(tester, StartupStrings.emptyButton);
    await tester.enterText(field(0), 'Draft');
    // Let the form rebuild so the unsaved-changes guard is active.
    await tester.pump();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text(StartupStrings.discardTitle), findsOneWidget);

    await tapText(tester, StartupStrings.keepEditing);
    expect(find.text(StartupStrings.addTitle), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tapText(tester, StartupStrings.discard);
    expect(find.text(StartupStrings.emptyTitle), findsOneWidget);
  });

  testWidgets('making a public startup private asks for confirmation', (
    tester,
  ) async {
    repo.startups.add(_startup(isPublic: true));
    await pumpList(tester);
    expect(
      find.descendant(
        of: find.byType(MyStartupCard),
        matching: find.text(StartupStrings.publicBadge),
      ),
      findsOneWidget,
    );

    await tapText(tester, 'Nakhla Pay');
    expect(find.text(StartupStrings.editTitle), findsWidgets);

    final toggle = find.byType(Switch);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text(StartupStrings.makePrivateBody), findsOneWidget);

    await tapText(tester, StartupStrings.cancel);
    expect(tester.widget<Switch>(toggle).value, isTrue);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tapText(tester, StartupStrings.makePrivateConfirm);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(find.text(StartupStrings.visibilityOff), findsOneWidget);
  });

  testWidgets('preview shows the public profile', (tester) async {
    repo.startups.add(_startup());
    await pumpList(tester);
    await tapText(tester, 'Nakhla Pay');

    await tester.tap(find.byTooltip(StartupStrings.previewAsPublic));
    await tester.pumpAndSettle();
    expect(find.text(StartupStrings.previewBanner), findsOneWidget);
    expect(find.text(StartupStrings.previewPrivateBanner), findsOneWidget);
    expect(find.text(_description), findsOneWidget);
  });

  testWidgets('delete asks first, then removes the startup', (tester) async {
    repo.startups.add(_startup());
    await pumpList(tester);
    await tapText(tester, 'Nakhla Pay');

    await tapText(tester, StartupStrings.deleteButton);
    expect(find.text(StartupStrings.deleteTitle('Nakhla Pay')), findsOneWidget);

    await tapText(tester, StartupStrings.deleteConfirm);
    expect(repo.startups, isEmpty);
    expect(find.text(StartupStrings.emptyTitle), findsOneWidget);
  });

  testWidgets('a failed load shows the error with Retry', (tester) async {
    repo.fetchFails = AuthFailure.network;
    repo.startups.add(_startup());
    await pumpList(tester);
    expect(find.text(StartupStrings.loadFailed), findsOneWidget);
    expect(find.text(StartupStrings.networkError), findsOneWidget);

    repo.fetchFails = null;
    await tapText(tester, StartupStrings.retry);
    expect(find.text('Nakhla Pay'), findsOneWidget);
  });

  testWidgets(
    'deleting the last startup brings back "Add your first startup"',
    (tester) async {
      repo.startups.add(_startup());
      await pumpList(tester);
      await tapText(tester, 'Nakhla Pay');
      await tapText(tester, StartupStrings.deleteButton);
      await tapText(tester, StartupStrings.deleteConfirm);

      // Back to a clean slate: they can create their first startup again.
      await tapText(tester, StartupStrings.emptyButton);
      expect(find.text(StartupStrings.addTitle), findsOneWidget);
    },
  );

  testWidgets('the public switch can be turned on while creating', (
    tester,
  ) async {
    await pumpList(tester);
    await tapText(tester, StartupStrings.emptyButton);
    await fillRequired(tester);

    final toggle = find.byType(Switch);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text(StartupStrings.visibilityOn), findsOneWidget);

    await tapText(tester, StartupStrings.saveNew);
    expect(repo.startups.single.isPublic, isTrue);
    expect(find.text(StartupStrings.publicBadge), findsWidgets);
  });

  testWidgets('All / Public / Private chips filter the list', (tester) async {
    repo.startups
      ..add(_startup(isPublic: true))
      ..add(
        Startup(
          id: 's2',
          founderId: 'uid1',
          name: 'Naql',
          description: _description,
          sector: Sector.logisticsTransport,
          stage: StartupStage.growth,
          businessModel: BusinessModel.b2b,
          location: StartupLocation.dammam,
          lookingFor: const {LookingFor.services},
        ),
      );
    await pumpList(tester);
    expect(find.text('Nakhla Pay'), findsOneWidget);
    expect(find.text('Naql'), findsOneWidget);

    Finder chip(String label) => find.widgetWithText(SelectionChip, label);

    await tester.tap(chip(StartupStrings.publicBadge));
    await tester.pumpAndSettle();
    expect(find.text('Nakhla Pay'), findsOneWidget);
    expect(find.text('Naql'), findsNothing);

    await tester.tap(chip(StartupStrings.privateBadge));
    await tester.pumpAndSettle();
    expect(find.text('Nakhla Pay'), findsNothing);
    expect(find.text('Naql'), findsOneWidget);
    expect(find.text('Logistics & Transport · Growth'), findsOneWidget);
  });
}
