import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/app_constants/startup_strings.dart';
import 'package:startsa/features/startups/widgets/startup_form.dart';
import 'package:startsa/features/startups/widgets/looking_for_chips.dart';
import 'package:startsa/features/startups/widgets/select_field.dart' show otherTextFormatters;
import 'package:startsa/helpers/startup_validators.dart';
import 'package:startsa/shared_ui/common_widgets/app_text_field.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/startups/screens/my_startups_screen.dart';
import 'package:startsa/features/startups/screens/manage_startup_screen.dart';
import 'package:startsa/features/startups/screens/startup_profile_screen.dart';
import 'package:startsa/features/startups/widgets/my_startup_card.dart';
import 'package:startsa/features/startups/widgets/startup_profile_view.dart';
import 'package:startsa/models/auth_failure.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_association.dart';
import 'package:startsa/data_access/mock_data/mock_startups.dart';
import 'package:startsa/features/profiles/screens/investor_profile_screen.dart';
import 'package:startsa/features/startups/view_models/startup_form_view_model.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/navigation/placeholder_features.dart';

import '../../support/fakes.dart';

const _description =
    'We help small shops in Riyadh accept card payments with a phone.';

Startup _startup({
  bool isPublic = false,
  String name = 'Nakhla Pay',
  String description = _description,
  int? foundedYear,
  String? websiteUrl,
  Set<LookingFor> lookingFor = const {LookingFor.mentorship},
  int? fundingRequirement,
}) => Startup(
  id: 's1',
  founderId: 'uid1',
  name: name,
  description: description,
  sector: Sector.fintech,
  stage: StartupStage.preSeed,
  businessModel: BusinessModel.b2b,
  location: StartupLocation.riyadh,
  lookingFor: lookingFor,
  foundedYear: foundedYear,
  websiteUrl: websiteUrl,
  fundingRequirement: fundingRequirement,
  isPublic: isPublic,
  updatedAt: DateTime.now(),
);

void main() {
  late FakeStartupRepository repo;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    repo = FakeStartupRepository();
    StartupRepository.instance = repo;
    UserRepository.instance = FakeUserRepository();
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

  /// Opens a select field (shows its hint, e.g. "Select a sector", while
  /// empty) and picks [option].
  Future<void> choose(WidgetTester tester, String hint, String option) async {
    await tapText(tester, hint);
    // The city list has a search box: type the city to find it.
    final search = find.widgetWithText(TextField, AppStrings.citySearchHint);
    if (search.evaluate().isNotEmpty) {
      await tester.enterText(search, option);
      await tester.pumpAndSettle();
    }
    await tapText(tester, option);
  }

  Future<void> fillRequired(
    WidgetTester tester, {
    String name = 'Nakhla Pay',
  }) async {
    await tester.enterText(field(0), name);
    await tester.enterText(field(1), _description);
    await choose(tester, StartupStrings.selectSector, Sector.fintech.label);
    await choose(
      tester,
      StartupStrings.selectStage,
      StartupStage.preSeed.label,
    );
    await choose(
      tester,
      StartupStrings.selectLocation,
      StartupLocation.jeddah.label,
    );
    await choose(
      tester,
      StartupStrings.selectBusinessModel,
      BusinessModel.b2b.label,
    );
    await tapText(tester, LookingFor.mentorship.label);
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
    // The dark toast confirms it (Figma "V2 · 44b").
    expect(find.text(StartupStrings.added('Nakhla Pay')), findsOneWidget);
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

    await tapText(tester, LookingFor.funding.label);
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
    expect(find.text(StartupStrings.nameTooShort(3)), findsNothing);

    await tapText(tester, StartupStrings.saveNew);
    expect(find.text(StartupStrings.nameTooShort(3)), findsOneWidget);
    expect(repo.startups, isEmpty);
  });

  testWidgets('name and description show an n/max counter like signup', (
    tester,
  ) async {
    await pumpList(tester);
    await tapText(tester, StartupStrings.emptyButton);
    expect(find.text('0/40'), findsOneWidget);
    expect(find.text('0/1000'), findsOneWidget);

    await tester.enterText(field(0), 'Rafeeq Health');
    await tester.pump();
    expect(find.text('13/40'), findsOneWidget);

    // The input stops at 40 characters.
    await tester.enterText(field(0), 'a' * 55);
    await tester.pump();
    expect(find.text('40/40'), findsOneWidget);
  });

  testWidgets('the form has no one-liner field and follows the Figma order', (
    tester,
  ) async {
    await pumpList(tester);
    await tapText(tester, StartupStrings.emptyButton);
    expect(find.text('One-liner description'), findsNothing);
    expect(find.textContaining('One line that sums up'), findsNothing);
    // Name, description, website and the founded year are the only text
    // inputs (funding comes later, only when Funding is selected).
    expect(
      find.descendant(
        of: find.byType(StartupForm),
        matching: find.byType(AppTextField),
      ),
      findsNWidgets(4),
    );
    expect(find.text(StartupStrings.selectSector), findsOneWidget);
    expect(find.text(StartupStrings.selectStage), findsOneWidget);
    expect(find.text(StartupStrings.selectBusinessModel), findsOneWidget);
    expect(find.text(StartupStrings.selectLocation), findsOneWidget);
    // Founded is a text box now, not a list.
    expect(find.text(StartupStrings.foundedYearHint), findsOneWidget);
    for (final option in LookingFor.values) {
      expect(find.text(option.label), findsOneWidget);
    }
  });

  testWidgets('leaving with unsaved changes asks to discard', (tester) async {
    await pumpList(tester);
    await tapText(tester, StartupStrings.emptyButton);
    // Add has a close (X) button in the top bar, as in Figma.
    await tester.enterText(field(0), 'Draft');
    // Let the form rebuild so the unsaved-changes guard is active.
    await tester.pump();

    await tester.tap(find.byTooltip(StartupStrings.close));
    await tester.pumpAndSettle();
    expect(find.text(StartupStrings.discardTitle), findsOneWidget);

    await tapText(tester, StartupStrings.keepEditing);
    expect(find.text(StartupStrings.addTitle), findsOneWidget);

    await tester.tap(find.byTooltip(StartupStrings.close));
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
    expect(find.byType(ManageStartupScreen), findsOneWidget);
    await tapText(tester, StartupStrings.editStartup);
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

    // Manage > Preview, then close.
    await tapText(tester, StartupStrings.preview);
    expect(find.byType(StartupProfileScreen), findsOneWidget);
    expect(find.text(StartupStrings.previewBanner), findsOneWidget);
    expect(find.text(StartupStrings.previewPrivateBanner), findsOneWidget);
    expect(find.text(_description), findsOneWidget);
    // A preview has no request or interest button.
    expect(find.text(StartupStrings.sendRequest), findsNothing);
    expect(find.text(StartupStrings.expressInterest), findsNothing);

    await tester.tap(find.byTooltip(StartupStrings.close));
    await tester.pumpAndSettle();
    expect(find.byType(StartupProfileScreen), findsNothing);
  });

  testWidgets('delete asks first, then removes the startup', (tester) async {
    repo.startups.add(_startup());
    await pumpList(tester);
    // Tall enough that the whole Manage page is built (it is a lazy list).
    tester.view.physicalSize = const Size(1080, 3600);
    await tapText(tester, 'Nakhla Pay');

    await tapText(tester, StartupStrings.deleteButton);
    expect(find.text(StartupStrings.deleteTitle('Nakhla Pay')), findsOneWidget);
    expect(find.text(StartupStrings.deleteBody), findsOneWidget);
    expect(repo.startups, hasLength(1));

    // Cancel keeps it.
    await tapText(tester, StartupStrings.cancel);
    expect(repo.startups, hasLength(1));
    expect(find.text(StartupStrings.deleteTitle('Nakhla Pay')), findsNothing);

    await tapText(tester, StartupStrings.deleteButton);
    await tapText(tester, StartupStrings.deleteConfirm);
    expect(repo.startups, isEmpty);
    expect(find.text(StartupStrings.emptyTitle), findsOneWidget);
    expect(find.text(StartupStrings.deleted('Nakhla Pay')), findsOneWidget);
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
    'deleting the last startup brings back the "Add startup" empty state',
    (tester) async {
      repo.startups.add(_startup());
      await pumpList(tester);
      // Tall enough that the whole Manage page is built (it is a lazy list).
      tester.view.physicalSize = const Size(1080, 3600);
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

  Startup second() => Startup(
    id: 's2',
    founderId: 'uid1',
    name: 'Naql',
    description: 'Naql moves goods for shops across the Kingdom.',
    sector: Sector.logistics,
    stage: StartupStage.seriesA,
    businessModel: BusinessModel.b2b,
    location: StartupLocation.dammam,
    lookingFor: const {LookingFor.funding, LookingFor.techDevelopment},
    fundingRequirement: 1200000,
  );

  testWidgets('the list shows a count, tags, visibility and Manage', (
    tester,
  ) async {
    repo.startups
      ..add(_startup(isPublic: true))
      ..add(second());
    await pumpList(tester);

    expect(find.text('2 startups'), findsOneWidget);
    expect(find.byType(MyStartupCard), findsNWidgets(2));
    // The old All / Public / Private chips are gone.
    expect(find.text('All'), findsNothing);
    // Header "Add" action.
    expect(find.text(StartupStrings.addAction), findsOneWidget);
    // Each card: tags, badge, Manage.
    expect(find.text(StartupStrings.manage), findsNWidgets(2));
    expect(find.text(Sector.logistics.label), findsOneWidget);
    expect(find.text(StartupStage.seriesA.label), findsOneWidget);
    expect(find.text('Looking for: SAR 1.2M'), findsOneWidget);
    expect(find.text('Looking for: Mentorship'), findsOneWidget);
    expect(find.text(StartupStrings.publicBadge), findsOneWidget);
    expect(find.text(StartupStrings.privateBadge), findsOneWidget);
    // One-line summary: the first sentence of the description.
    expect(find.text(_description), findsOneWidget);
    expect(
      find.text('Naql moves goods for shops across the Kingdom.'),
      findsOneWidget,
    );
  });

  testWidgets('a single startup reads "1 startup"; Add opens the form', (
    tester,
  ) async {
    repo.startups.add(_startup());
    await pumpList(tester);
    expect(find.text('1 startup'), findsOneWidget);

    await tapText(tester, StartupStrings.addAction);
    expect(find.text(StartupStrings.addTitle), findsWidgets);
    expect(find.text(StartupStrings.saveNew), findsOneWidget);
  });

  testWidgets('the Manage button opens the Manage page', (tester) async {
    repo.startups.add(_startup(isPublic: true));
    await pumpList(tester);

    await tapText(tester, StartupStrings.manage);
    expect(find.byType(ManageStartupScreen), findsOneWidget);
    // Header is the startup name; the summary repeats it.
    expect(find.text('Nakhla Pay'), findsNWidgets(2));
  });

  group('Manage', () {
    Future<void> openManage(WidgetTester tester) async {
      repo.startups.add(_startup(isPublic: true));
      await pumpList(tester);
      // Tall enough that every section is built (it is a lazy list).
      tester.view.physicalSize = const Size(1080, 3600);
      await tapText(tester, StartupStrings.manage);
    }

    testWidgets('shows the summary and every section', (tester) async {
      await openManage(tester);

      expect(find.text(Sector.fintech.label), findsOneWidget);
      expect(find.text(StartupStage.preSeed.label), findsOneWidget);
      expect(find.text(StartupLocation.riyadh.label), findsOneWidget);
      expect(find.text(StartupStrings.publicBadge), findsOneWidget);
      expect(find.text(StartupStrings.editStartup), findsOneWidget);
      expect(find.text(StartupStrings.preview), findsOneWidget);
      expect(find.text(StartupStrings.activityTitle), findsOneWidget);
      // A startup the user created has no activity tracking yet: honest
      // zeros, no period and no sample numbers.
      expect(find.text(StartupStrings.activityPeriod), findsNothing);
      expect(find.text('0'), findsNWidgets(3));
      expect(find.text('128'), findsNothing);
      expect(find.text('+18%'), findsNothing);
      expect(find.text(StartupStrings.noAssociations), findsOneWidget);
      expect(find.text('Ahmad Hassan'), findsNothing);
      expect(find.text('Omar Khalid'), findsNothing);
      expect(find.text(StartupStrings.activityViews), findsOneWidget);
      expect(find.text(StartupStrings.activityBookmarks), findsOneWidget);
      expect(find.text(StartupStrings.activityRequests), findsOneWidget);
      expect(find.text(StartupStrings.associationsTitle), findsOneWidget);
      expect(find.text(StartupStrings.addInvestor), findsOneWidget);
      expect(find.text(StartupStrings.calculatorTitle), findsOneWidget);
      expect(find.text(StartupStrings.calculatorSubtitle), findsOneWidget);
      expect(find.text(StartupStrings.deleteButton), findsOneWidget);
    });

    for (final label in [
      StartupStrings.activityTitle,
      StartupStrings.addInvestor,
      StartupStrings.calculatorTitle,
    ]) {
      testWidgets('$label is an inert placeholder', (tester) async {
        await openManage(tester);
        await tapText(tester, label);
        // Nothing opens and no message shows: still on the manage page.
        expect(find.byType(SnackBar), findsNothing);
        expect(find.text(StartupStrings.deleteButton), findsOneWidget);
        expect(find.text(StartupStrings.editStartup), findsOneWidget);
      });
    }

    testWidgets('a failed delete shows the error and keeps the startup', (
      tester,
    ) async {
      await openManage(tester);
      repo.deleteFails = AuthFailure.network;
      await tapText(tester, StartupStrings.deleteButton);
      await tapText(tester, StartupStrings.deleteConfirm);

      expect(repo.startups, hasLength(1));
      expect(find.byType(ManageStartupScreen), findsOneWidget);
      expect(find.textContaining(StartupStrings.deleteFailed), findsOneWidget);
    });
  });

  testWidgets('long names and large text never overflow the list or Manage', (
    tester,
  ) async {
    repo.startups.add(
      _startup(
        isPublic: true,
        name: 'A very long startup name that keeps going past 40',
        description: List.filled(30, 'Long description words').join(' '),
        lookingFor: const {
          LookingFor.funding,
          LookingFor.talent,
          LookingFor.partnership,
        },
        fundingRequirement: 500000,
      ),
    );
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: const MyStartupsScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tapText(tester, StartupStrings.manage);
    expect(find.byType(ManageStartupScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('Startup profile (Figma V2 45 / 45b)', () {
    Future<void> pumpProfile(
      WidgetTester tester, {
      required bool isPreview,
      String? founderName,
      List<ProfileAssociation> associations = const [],
      Startup? startup,
    }) async {
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: StartupProfileScreen(
            startup:
                startup ??
                _startup(
                  isPublic: true,
                  foundedYear: 2024,
                  websiteUrl: 'https://nakhlapay.sa',
                  lookingFor: const {LookingFor.funding, LookingFor.talent},
                  fundingRequirement: 500000,
                ),
            isPreview: isPreview,
            founderName: founderName,
            associations: associations,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('founder preview: banner, sections, no action button', (
      tester,
    ) async {
      await pumpProfile(
        tester,
        isPreview: true,
        founderName: 'Shahad Alabdulkarim',
        associations: const [
          StartupAssociation(name: 'Ahmad Hassan', subtitle: 'Riyadh'),
        ],
      );

      expect(find.text(StartupStrings.previewBanner), findsOneWidget);
      expect(find.text(StartupStrings.previewPrivateBanner), findsNothing);
      expect(find.text('Nakhla Pay'), findsOneWidget);
      expect(find.text('nakhlapay.sa'), findsOneWidget);
      expect(find.textContaining('Shahad Alabdulkarim'), findsOneWidget);
      expect(find.text(StartupStrings.sendRequest), findsNothing);
      expect(find.text(StartupStrings.expressInterest), findsNothing);
      expect(find.text(StartupStrings.aboutTitle), findsOneWidget);
      expect(find.text(_description), findsOneWidget);
      expect(find.text(StartupStrings.lookingForTitle), findsOneWidget);
      expect(find.text('Funding'), findsOneWidget);
      expect(find.text('Talent'), findsOneWidget);
      expect(find.text('SAR 500,000'), findsOneWidget);
      expect(find.text(StartupStrings.raisingThisRound), findsOneWidget);
      expect(find.text(StartupStrings.detailsTitle), findsOneWidget);
      expect(find.text('B2B'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text(StartupStrings.associationsTitle), findsOneWidget);
      expect(find.text('Ahmad Hassan'), findsOneWidget);
      // Preview: the top bar has Close and Share, no bookmark.
      expect(find.byTooltip(StartupStrings.close), findsOneWidget);
      expect(
        find.bySemanticsLabel(PlaceholderFeature.bookmarks.label),
        findsNothing,
      );
    });

    testWidgets('investor view: Send request opens the placeholder', (
      tester,
    ) async {
      await pumpProfile(tester, isPreview: false);

      expect(find.text(StartupStrings.previewBanner), findsNothing);
      expect(find.text(StartupStrings.expressInterest), findsNothing);
      // Unknown founder: the "Founded by" row is left out.
      expect(find.textContaining(StartupStrings.foundedBy), findsNothing);
      // No associations known: the section is left out.
      expect(find.text(StartupStrings.associationsTitle), findsNothing);
      expect(
        find.bySemanticsLabel(PlaceholderFeature.bookmarks.label),
        findsOneWidget,
      );

      // Send request is an inert placeholder: nothing opens.
      await tester.tap(find.text(StartupStrings.sendRequest));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text(StartupStrings.sendRequest), findsOneWidget);
    });

    testWidgets('bookmark and share are inert', (tester) async {
      await pumpProfile(tester, isPreview: false);
      await tester.tap(
        find.bySemanticsLabel(PlaceholderFeature.bookmarks.label),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel(PlaceholderFeature.shareStartup.label),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text(StartupStrings.sendRequest), findsOneWidget);
    });

    testWidgets('a long name and description wrap without overflowing', (
      tester,
    ) async {
      await pumpProfile(
        tester,
        isPreview: false,
        founderName: 'Abdulrahman Mohammed Alghamdi Alshehri',
        startup: _startup(
          name: 'A very long startup name that keeps going past 40',
          description: List.filled(40, 'Long description words').join(' '),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('"Other" shows a text box (Sector, Stage, Commerce model)', () {
    // (field label on the form, the current choice's text, the text box
    // label, a typed value, how the saved startup reads back)
    final cases =
        <
          ({
            String name,
            String current,
            String boxLabel,
            String typed,
            String Function(Startup) saved,
            String Function(Startup) shown,
          })
        >[
          (
            name: 'Sector',
            current: Sector.fintech.label,
            boxLabel: StartupStrings.sectorOtherLabel,
            typed: 'Biotech',
            saved: (s) => s.sectorOther ?? '',
            shown: (s) => s.sectorLabel,
          ),
          (
            name: 'Stage',
            current: StartupStage.preSeed.label,
            boxLabel: StartupStrings.stageOtherLabel,
            typed: 'Bridge round',
            saved: (s) => s.stageOther ?? '',
            shown: (s) => s.stageLabel,
          ),
          (
            name: 'Commerce model',
            current: BusinessModel.b2b.label,
            boxLabel: StartupStrings.businessModelOtherLabel,
            typed: 'Subscription box',
            saved: (s) => s.businessModelOther ?? '',
            shown: (s) => s.businessModelLabel,
          ),
        ];

    Finder boxField(String label) => find.descendant(
      of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label),
      matching: find.byType(TextField),
    );

    for (final c in cases) {
      testWidgets('${c.name}: appears, is required, saved and shown', (
        tester,
      ) async {
        await pumpList(tester);
        await tapText(tester, StartupStrings.emptyButton);
        await fillRequired(tester);
        expect(find.text(c.boxLabel), findsNothing);

        // Choosing Other reveals the text box inside the picker.
        await tapText(tester, c.current);
        final otherRow = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Other'),
        );
        // Scroll the picker to its end, where "Other" is.
        await tester.drag(
          find
              .descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(Scrollable),
              )
              .first,
          const Offset(0, -600),
        );
        await tester.pumpAndSettle();
        await tester.tap(otherRow);
        await tester.pumpAndSettle();
        expect(find.text(c.boxLabel), findsOneWidget);
        expect(find.text('0/${Startup.otherMaxLength}'), findsWidgets);
        await tester.enterText(boxField(c.boxLabel), c.typed);
        await tapText(tester, StartupStrings.done);

        // It stays on the form, filled in; clearing it blocks saving.
        expect(find.text(c.boxLabel), findsOneWidget);
        expect(saveEnabled(tester, StartupStrings.saveNew), isTrue);
        await tester.enterText(boxField(c.boxLabel), '');
        await tester.pumpAndSettle();
        expect(saveEnabled(tester, StartupStrings.saveNew), isFalse);
        await tester.enterText(boxField(c.boxLabel), c.typed);
        await tester.pumpAndSettle();
        expect(saveEnabled(tester, StartupStrings.saveNew), isTrue);

        await tapText(tester, StartupStrings.saveNew);
        final saved = repo.startups.single;
        expect(c.saved(saved), c.typed);
        expect(c.shown(saved), c.typed);
        // The list card shows the typed text, not the word "Other".
        if (c.name != 'Commerce model') {
          expect(find.text(c.typed), findsOneWidget);
        }
      });
    }

    test('the form requires the text and rejects more than 40 characters', () {
      final vm = StartupFormViewModel(repository: repo)
        ..name.text = 'Nakhla Pay'
        ..description.text = _description
        ..selectSector(Sector.other)
        ..selectStage(StartupStage.other)
        ..selectBusinessModel(BusinessModel.other)
        ..selectLocation(StartupLocation.riyadh)
        ..setLookingFor({LookingFor.mentorship});
      addTearDown(vm.dispose);
      expect(vm.requiredFilled, isFalse);
      expect(vm.validate(), isFalse);
      expect(
        vm.errors[StartupField.sectorOther],
        StartupStrings.sectorOtherRequired,
      );
      expect(
        vm.errors[StartupField.stageOther],
        StartupStrings.stageOtherRequired,
      );
      expect(
        vm.errors[StartupField.businessModelOther],
        StartupStrings.businessModelOtherRequired,
      );

      vm.sectorOther.text = 'x' * 41;
      vm.stageOther.text = 'Bridge';
      vm.businessModelOther.text = 'Box';
      expect(vm.validate(), isFalse);
      expect(
        vm.errors[StartupField.sectorOther],
        StartupStrings.otherTooLong(40),
      );
      vm.sectorOther.text = 'Biotech';
      expect(vm.validate(), isTrue);
    });

    test('the text is kept only while Other is chosen', () {
      const s = Startup(
        id: 's',
        founderId: 'u',
        name: 'Nakhla',
        description: _description,
        sector: Sector.fintech,
        sectorOther: 'Biotech',
        stage: StartupStage.other,
        stageOther: 'Bridge',
        businessModel: BusinessModel.other,
        businessModelOther: 'Box',
        location: StartupLocation.riyadh,
        lookingFor: {LookingFor.funding},
      );
      final map = s.toMap();
      expect(map['sectorOther'], isNull);
      expect(map['stageOther'], 'Bridge');
      expect(map['businessModelOther'], 'Box');
      expect(s.sectorLabel, 'Fintech');
      expect(s.stageLabel, 'Bridge');
      expect(s.businessModelLabel, 'Box');
      final back = Startup.fromMap('s', {...map, 'createdAt': null});
      expect(back!.stageOther, 'Bridge');
      expect(back.copyWith(isPublic: true).businessModelOther, 'Box');
    });
  });

  group('Investment associations', () {
    Future<void> pumpScreen(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: home));
      await tester.pumpAndSettle();
    }

    const mixed = [
      StartupAssociation(name: 'Ahmad Hassan', subtitle: 'Riyadh'),
      StartupAssociation(
        name: 'Omar Khalid',
        subtitle: 'Riyadh',
        status: AssociationStatus.waiting,
        isPublic: false,
      ),
      StartupAssociation(
        name: 'Sara Al-Mohsen',
        subtitle: 'Jeddah',
        isPublic: false,
      ),
    ];

    testWidgets('the preview lists only approved, public associations', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        StartupProfileScreen(
          startup: _startup(isPublic: true),
          isPreview: true,
          associations: mixed,
        ),
      );
      expect(find.text('Ahmad Hassan'), findsOneWidget);
      expect(find.text('Omar Khalid'), findsNothing);
      expect(find.text('Sara Al-Mohsen'), findsNothing);
    });

    testWidgets('the section is left out when none is public', (tester) async {
      await pumpScreen(
        tester,
        StartupProfileScreen(
          startup: _startup(isPublic: true),
          associations: [mixed[1], mixed[2]],
        ),
      );
      expect(find.text(StartupStrings.associationsTitle), findsNothing);
    });

    testWidgets('tapping an association opens the investor profile', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        StartupProfileScreen(
          startup: _startup(isPublic: true),
          associations: [mixed.first],
        ),
      );
      await tester.tap(find.text('Ahmad Hassan'));
      await tester.pumpAndSettle();
      expect(find.byType(InvestorProfileScreen), findsOneWidget);
    });

    testWidgets('Manage of a sample startup lists all, with status', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        ManageStartupScreen(startup: MockStartups.rafeeq.startup),
      );
      expect(find.text('Ahmad Hassan'), findsOneWidget);
      expect(find.text('Omar Khalid'), findsOneWidget);
      expect(find.text(StartupStrings.associationApproved), findsOneWidget);
      expect(find.text(StartupStrings.associationWaiting), findsOneWidget);
      // Sample numbers are allowed only for the built-in sample startups.
      expect(find.text('128'), findsOneWidget);
      expect(find.text(StartupStrings.activityPeriod), findsOneWidget);

      await tester.ensureVisible(find.text('Ahmad Hassan'));
      await tester.tap(find.text('Ahmad Hassan'));
      await tester.pumpAndSettle();
      expect(find.byType(InvestorProfileScreen), findsOneWidget);
    });

    testWidgets('the preview of a real new startup has no associations', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        ManageStartupScreen(startup: _startup(isPublic: true)),
      );
      await tester.tap(find.text(StartupStrings.preview));
      await tester.pumpAndSettle();
      expect(find.text(StartupStrings.previewBanner), findsOneWidget);
      expect(find.text(StartupStrings.associationsTitle), findsNothing);
    });
  });

  group('City search, symbols in "Other", and "Other" in Looking for', () {
    testWidgets('the city picker has a search box that filters the cities', (
      tester,
    ) async {
      await pumpList(tester);
      await tapText(tester, StartupStrings.emptyButton);
      await tapText(tester, StartupStrings.selectLocation);

      final search = find.widgetWithText(TextField, AppStrings.citySearchHint);
      expect(search, findsOneWidget);

      await tester.enterText(search, 'riy');
      await tester.pumpAndSettle();
      expect(find.text('Riyadh'), findsOneWidget);
      expect(find.text('Jeddah'), findsNothing);

      await tester.enterText(search, 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.cityNoResults), findsOneWidget);

      await tester.enterText(search, 'jed');
      await tester.pumpAndSettle();
      await tapText(tester, 'Jeddah');
      // The chosen city is on the field, and the sheet is closed.
      expect(find.text('Jeddah'), findsOneWidget);
      expect(find.text(AppStrings.citySearchHint), findsNothing);
    });

    test('symbols such as "--" or an apostrophe are not allowed in Other', () {
      String? check(String v) => StartupValidators.otherText(
        v,
        requiredMessage: 'required',
      );
      expect(check('Biotech'), isNull);
      expect(check('Bridge round 2'), isNull);
      expect(check('Fin-tech'), StartupStrings.otherSymbols);
      expect(check('Bio -- tech'), StartupStrings.otherSymbols);
      expect(check("Founder's pool"), StartupStrings.otherSymbols);
      expect(check('12345'), StartupStrings.otherSymbols); // needs a letter
      expect(check('   '), 'required');
    });

    test('the Other box cannot even be typed into with symbols', () {
      TextEditingValue type(String text) {
        var value = TextEditingValue.empty;
        for (final f in otherTextFormatters) {
          value = f.formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(text: text),
          );
        }
        return value;
      }

      expect(type("A--b'c d").text, 'Abc d');
      expect(type('Biotech').text, 'Biotech');
    });

    testWidgets('Other in Looking for shows a text box that is required', (
      tester,
    ) async {
      await pumpList(tester);
      await tapText(tester, StartupStrings.emptyButton);
      await fillRequired(tester);
      expect(find.text(StartupStrings.lookingForOtherHint), findsNothing);
      expect(saveEnabled(tester, StartupStrings.saveNew), isTrue);

      final otherChip = find.descendant(
        of: find.byType(LookingForChips),
        matching: find.text('Other'),
      );
      await tester.ensureVisible(otherChip);
      await tester.pumpAndSettle();
      await tester.tap(otherChip);
      await tester.pumpAndSettle();

      // The chip becomes "Other: [box]" (as on Create Account), and saving
      // waits until it is filled in.
      expect(find.text('Other:'), findsOneWidget);
      expect(find.text(StartupStrings.lookingForOtherHint), findsOneWidget);
      expect(saveEnabled(tester, StartupStrings.saveNew), isFalse);

      final box = find.descendant(
        of: find.byType(LookingForChips),
        matching: find.byType(TextField),
      );
      await tester.enterText(box, "Legal -- advice's");
      await tester.pumpAndSettle();
      // Symbols are dropped as they are typed.
      expect(
        tester.widget<TextField>(box).controller!.text,
        'Legal  advices',
      );
      expect(saveEnabled(tester, StartupStrings.saveNew), isTrue);

      await tapText(tester, StartupStrings.saveNew);
      final saved = repo.startups.single;
      expect(saved.lookingFor, contains(LookingFor.other));
      expect(saved.lookingForOther, 'Legal  advices');
      expect(saved.lookingForLabelOf(LookingFor.other), 'Legal  advices');
      expect(saved.toMap()['lookingForOther'], 'Legal  advices');
    });

    test('lookingForOther is kept only while Other is ticked', () {
      const s = Startup(
        id: 's',
        founderId: 'u',
        name: 'Nakhla',
        description: _description,
        sector: Sector.fintech,
        stage: StartupStage.seed,
        businessModel: BusinessModel.b2b,
        location: StartupLocation.riyadh,
        lookingFor: {LookingFor.funding},
        lookingForOther: 'Legal advice',
        fundingRequirement: 1000,
      );
      expect(s.toMap()['lookingForOther'], isNull);
      final withOther = Startup(
        id: 's',
        founderId: 'u',
        name: 'Nakhla',
        description: _description,
        sector: Sector.fintech,
        stage: StartupStage.seed,
        businessModel: BusinessModel.b2b,
        location: StartupLocation.riyadh,
        lookingFor: const {LookingFor.other},
        lookingForOther: 'Legal advice',
      );
      final back = Startup.fromMap('s', {
        ...withOther.toMap(),
        'founderId': 'u',
      });
      expect(back!.lookingForOther, 'Legal advice');
    });
  });

}
