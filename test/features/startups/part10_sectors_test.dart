import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/funding_round_repository.dart';
import 'package:startsa/data_access/repositories/request_repository.dart';
import 'package:startsa/features/startup_profile/screens/startup_profile_screen.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/features/startups/widgets/startup_step_body.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/recommender/content_ranker.dart';
import 'package:startsa/recommender/knowledge_filter.dart';
import 'package:startsa/shared_ui/widgets/cards/box_grid.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';

import '../../support/fakes.dart';

const _repeats = 'This option is already in the list. Select it instead.';

Startup _startup() => PrototypeSeed.rafeeq.copyWith(
  sector: Sector.healthtech,
  otherSectors: const [],
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeStartupRepository repo;
  setUp(() {
    repo = FakeStartupRepository()..startups.add(_startup());
    StartupRepository.instance = repo;
    AppSession.instance = AppSession();
    RequestRepository.instance = RequestRepository(sample: true);
    DiscoveryRepository.instance = DiscoveryRepository.sample();
    FundingRoundRepository.instance = FundingRoundRepository.sample();
  });

  StartupStepsViewModel edit([Startup? s]) {
    final vm = StartupStepsViewModel(initial: s ?? _startup());
    addTearDown(vm.dispose);
    return vm;
  }

  group('the form: any number of sectors', () {
    test('an existing startup opens with just its one sector ticked', () {
      final vm = edit();
      expect(vm.sectorPicks, ['HealthTech']);
      expect(vm.sector, Sector.healthtech);
    });

    test('the first sector picked is the main one, the rest follow', () async {
      final vm = edit();
      vm.toggleSector('HealthTech'); // untick
      vm.toggleSector('SaaS');
      vm.toggleSector('AI');
      vm.toggleSector('Fintech');
      expect(vm.sectorPicks, ['SaaS', 'AI', 'Fintech']);
      expect(vm.sector, Sector.saas);
      final saved = await vm.save();
      expect(saved!.sector, Sector.saas);
      expect(saved.otherSectors, ['AI', 'Fintech']);
      expect(saved.sectorLabels, ['SaaS', 'AI', 'Fintech']);
      // The card and the header show the main one only.
      expect(saved.sectorLabel, 'SaaS');
    });

    test('unticking the main one makes the next one the main sector', () {
      final vm = edit();
      vm.toggleSector('SaaS');
      vm.toggleSector('AI');
      vm.toggleSector('HealthTech');
      expect(vm.sector, Sector.saas);
      expect(vm.sectorPicks, ['SaaS', 'AI']);
    });

    test('all of them can be picked', () async {
      final vm = edit();
      vm.sectorPicks.clear();
      for (final s in Sector.values) {
        if (s != Sector.other) vm.toggleSector(s.label);
      }
      expect(vm.sectorPicks.length, Sector.values.length - 1);
      final saved = await vm.save();
      expect(saved!.otherSectors.length, Sector.values.length - 2);
    });

    test(
      '"Other" as the main sector keeps the typed text in sectorOther',
      () async {
        final vm = edit();
        vm.toggleSector('HealthTech');
        vm.toggleSector('Other');
        vm.sectorOther.text = 'Beekeeping';
        vm.toggleSector('SaaS');
        final saved = await vm.save();
        expect(saved!.sector, Sector.other);
        expect(saved.sectorOther, 'Beekeeping');
        expect(saved.otherSectors, ['SaaS']);
        expect(saved.sectorLabel, 'Beekeeping');
        expect(saved.sectorLabels, ['Beekeeping', 'SaaS']);
      },
    );

    test('"Other" after the main one goes in the list as its text', () async {
      final vm = edit();
      vm.toggleSector('Other');
      vm.sectorOther.text = 'Beekeeping';
      final saved = await vm.save();
      expect(saved!.sector, Sector.healthtech);
      expect(saved.sectorOther, isNull);
      expect(saved.otherSectors, ['Beekeeping']);
      // And it opens again with the boxes ticked.
      final again = edit(saved);
      expect(again.sectorPicks, ['HealthTech', 'Other']);
      expect(again.sectorOther.text, 'Beekeeping');
    });

    test(
      'a startup saved before (no otherSectors) saves and opens as before',
      () {
        final s = _startup();
        expect(s.otherSectors, isEmpty);
        expect(
          Startup.fromMap(
            'x',
            {...s.toMap()}..remove('otherSectors'),
          )!.otherSectors,
          isEmpty,
        );
        expect(s.sectorLabels, ['HealthTech']);
      },
    );

    test('a draft saved with one sector reopens with it', () {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      vm.loadDraft({'sector': 'saas', 'sectorOther': ''});
      expect(vm.sectorPicks, ['SaaS']);
      vm.loadDraft({
        'sectors': ['AI', 'Other'],
        'sectorOther': 'Beekeeping',
      });
      expect(vm.sectorPicks, ['AI', 'Other']);
    });

    test('the messages', () {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      expect(vm.errorOf(StartupField.sector), isNull, reason: 'untouched');
      vm.next();
      expect(vm.errorOf(StartupField.sector), 'Select at least one sector.');
      vm.toggleSector('Other');
      expect(
        vm.errorOf(StartupField.sectorOther),
        'Tell us your other sector — it can’t be blank.',
      );
      vm.sectorOther.text = 'fintechs';
      expect(vm.errorOf(StartupField.sectorOther), _repeats);
      vm.sectorOther.text = 'Beekeeping';
      expect(vm.errorOf(StartupField.sectorOther), isNull);
    });
  });

  group('where the sectors show', () {
    test('the filters and search find a startup under every sector', () {
      final s = _startup().copyWith(otherSectors: ['SaaS', 'Beekeeping']);
      final item = HomeItem.fromStartup(s);
      expect(item.tag, 'HealthTech', reason: 'cards: the main one only');
      expect(
        item.sectors,
        containsAll(['HealthTech', 'SaaS', 'Beekeeping', 'Other']),
      );
    });

    testWidgets('startup page → Overview: "Sectors" lists them, main first', (
      t,
    ) async {
      t.view.physicalSize = const Size(412, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final s = _startup().copyWith(otherSectors: ['SaaS', 'AI', 'Beekeeping']);
      await t.pumpWidget(MaterialApp(home: StartupProfileScreen(startup: s)));
      await t.pumpAndSettle();
      expect(find.text('Sectors'), findsOneWidget);
      expect(find.text('HealthTech, SaaS, AI, Beekeeping'), findsOneWidget);
      expect(find.text('Sector'), findsNothing);
      // The header sub-line shows the main sector only.
      expect(find.textContaining('HealthTech · Pre-seed'), findsOneWidget);
    });

    testWidgets('a startup with one sector has no Sector box (the header says it)', (t) async {
      t.view.physicalSize = const Size(412, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(home: StartupProfileScreen(startup: _startup())),
      );
      await t.pumpAndSettle();
      expect(find.text('Sector'), findsNothing);
      expect(find.text('Sectors'), findsNothing);
      expect(find.textContaining('HealthTech · Pre-seed'), findsOneWidget);
    });

    testWidgets('a long list wraps instead of being cut off', (t) async {
      final all = [for (final s in Sector.values) s.label].join(', ');
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: BoxGrid(
                  wrap: const {'Sectors'},
                  items: [('Sectors', all), ('Stage', 'Seed')],
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      final text = t.widget<Text>(find.text(all));
      expect(text.maxLines, isNull);
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('Startup Overview: the field lists the picks, no "N selected"', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(412, 2600));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final vm = StartupStepsViewModel();
    addTearDown(vm.dispose);
    Future<void> show() async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StartupStepBody(vm: vm, step: 0),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
    }

    await show();
    expect(find.text('Select sectors'), findsOneWidget);
    expect(find.textContaining('selected'), findsNothing);
    vm.toggleSector('HealthTech');
    vm.toggleSector('SaaS');
    vm.toggleSector('AI');
    await show();
    expect(find.text('HealthTech, SaaS, AI'), findsOneWidget);
    vm.toggleSector('Other');
    vm.sectorOther.text = 'Beekeeping';
    await show();
    expect(
      find.text('HealthTech, SaaS, AI, Other: Beekeeping'),
      findsOneWidget,
    );
  });

  group('matching: the other sectors count less', () {
    MatchStartup startup(Map<String, dynamic> over) =>
        MatchStartup.fromMap('s1', {
          'name': 'Acme',
          'sector': 'fintech',
          'stage': 'seed',
          'businessModel': 'b2b',
          'lookingFor': ['funding'],
          'fundingRequirement': 2000000,
          'isPublic': true,
          ...over,
        });
    MatchInvestor investor(List<String> sectors) =>
        MatchInvestor.fromMap('i1', {
          'fullName': 'Sara',
          'preferredSectors': sectors,
          'preferredStages': ['Seed'],
          'preferredCommerceModels': ['Business-to-Business (B2B)'],
          'ticketSize': 'SAR 100K – 500K',
        });

    test('main sector = full credit, another sector = half, none = 0', () {
      final i = investor(['Fintech']);
      expect(scoreParts(i, startup({}))['sector'], 1.0);
      final j = investor(['AI']);
      expect(scoreParts(j, startup({}))['sector'], 0.0);
      expect(
        scoreParts(
          j,
          startup({
            'otherSectors': ['AI'],
          }),
        )['sector'],
        otherSectorFactor,
      );
      expect(otherSectorFactor, 0.5);
    });

    test(
      'ticking every sector never beats a startup whose main sector fits',
      () {
        final i = investor(['Fintech']);
        final everything = [for (final e in sectorValue.keys) e];
        final greedy = startup({'sector': 'saas', 'otherSectors': everything});
        final focused = startup({});
        expect(
          weightedScore(scoreParts(i, greedy)),
          lessThan(weightedScore(scoreParts(i, focused))),
        );
      },
    );

    test(
      'the main sector is what the hard filter uses (other-only = close)',
      () {
        final i = investor(['AI']);
        final s = startup({
          'otherSectors': ['AI'],
        });
        expect(failedFilters(i, s), contains('sector'));
        expect(sharesOtherSector(i, s), isTrue);
        // The explanation on the profile names the other sector that fits.
        expect(
          '${profileRows(i, s).first}',
          '+ Sector · AI (one of its other sectors)',
        );
      },
    );

    test('a startup with no other sectors scores exactly as before', () {
      final i = investor(['Fintech', 'AI']);
      expect(
        weightedScore(scoreParts(i, startup({}))),
        weightedScore(scoreParts(i, startup({'otherSectors': []}))),
      );
    });
  });
}
