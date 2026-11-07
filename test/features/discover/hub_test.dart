import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/search/view_models/home_filters.dart';
import 'package:startsa/features/search/view_models/home_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/helpers/size_bands.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/models/investor_profile.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/navigation/main_screen.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';

import '../../support/fakes.dart';

HomeItem startupItem({
  int? raising,
  Set<LookingFor> looking = const {LookingFor.funding},
  List<String> partners = const [],
  List<String> support = const [],
  BusinessModel model = BusinessModel.b2b,
}) => HomeItem.fromStartup(
  Startup(
    id: 's',
    founderId: 'f',
    name: 'Nakhla',
    description: 'd',
    sector: Sector.fintech,
    stage: StartupStage.seed,
    businessModel: model,
    location: StartupLocation.riyadh,
    lookingFor: looking,
    fundingRequirement: raising,
    partnerTypes: partners,
    supportTypes: support,
  ),
);

HomeItem investorItem({
  String ticket = 'SAR 100K – 500K',
  List<String> models = const ['B2B', 'B2C'],
  List<String> sectors = const ['Fintech'],
}) => HomeItem.fromInvestor(
  InvestorProfile(
    id: 'i',
    name: 'Ahmad',
    title: 'Angel Investor',
    city: 'Riyadh',
    sectors: sectors,
    stages: const ['Seed'],
    ticketRange: ticket,
    locations: const ['Riyadh'],
    commerceModels: models,
  ),
);

bool passes(HomeItem it, HomeContext ctx, String group, String option) =>
    HomeFilters.passes(
      it,
      {
        group: {option},
      },
      HomeFilters.groups(ctx),
      '',
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('size bands', () {
    test('an amount is in exactly one band', () {
      String? bandOf(int a) => SizeBand.all
          .where((b) => b.containsAmount(a))
          .map((b) => b.label)
          .singleOrNull;
      expect(bandOf(50000), 'Under SAR 100K');
      expect(bandOf(100000), 'SAR 100K – 500K');
      expect(bandOf(499999), 'SAR 100K – 500K');
      expect(bandOf(500000), 'SAR 500K – 1M');
      expect(bandOf(1000000), 'SAR 1M – 5M');
      expect(bandOf(5000000), 'Over SAR 5M');
      expect(bandOf(900000000), 'Over SAR 5M');
      expect(bandOf(0), isNull);
      expect(SizeBand.all.first.containsAmount(null), isFalse);
    });

    test('a ticket range is read from its text', () {
      ({int low, int high})? p(String t) => SizeBand.parseRange(t);
      expect(p('SAR 100K – 500K'), (low: 100000, high: 500000));
      expect(p('SAR 500K – 1M'), (low: 500000, high: 1000000));
      expect(p('SAR 1M – 5M'), (low: 1000000, high: 5000000));
      expect(p('SAR 1.5M – 3M'), (low: 1500000, high: 3000000));
      expect(p('Under SAR 100K'), (low: 0, high: 100000));
      expect(p('Over SAR 5M')!.low, 5000000);
      expect(p('SAR 100,000 – 500,000'), (low: 100000, high: 500000));
      expect(p('Other'), isNull);
      expect(p(''), isNull);
    });

    test('overlap: a ticket range touches a band', () {
      final mid = SizeBand.of('SAR 100K – 500K')!;
      expect(mid.overlaps(50000, 150000), isTrue);
      expect(mid.overlaps(400000, 2000000), isTrue);
      expect(mid.overlaps(500000, 900000), isFalse);
      expect(mid.overlaps(10000, 99999), isFalse);
    });
  });

  group('Hub startup filters', () {
    const c = HomeContext.startups;

    test('Looking for: Funding, Partnership, Support', () {
      final it = startupItem(looking: {LookingFor.funding, LookingFor.support});
      expect(passes(it, c, 'Looking for', 'Funding'), isTrue);
      expect(passes(it, c, 'Looking for', 'Support'), isTrue);
      expect(passes(it, c, 'Looking for', 'Partnership'), isFalse);
    });

    test('Partner types and Support types read the startup lists', () {
      final it = startupItem(
        partners: ['Distributor', 'Supplier'],
        support: ['Mentorship'],
      );
      expect(passes(it, c, 'Partner types', 'Distributor'), isTrue);
      expect(passes(it, c, 'Partner types', 'Co-founder'), isFalse);
      expect(passes(it, c, 'Support types', 'Mentorship'), isTrue);
      expect(passes(it, c, 'Support types', 'Hiring'), isFalse);
      // "Other" is not offered.
      final titles = {for (final g in HomeFilters.groups(c)) g.title: g};
      expect(titles['Partner types']!.options, isNot(contains('Other')));
      expect(titles['Support types']!.options, isNot(contains('Other')));
    });

    test('Raising: the five bands, none for a startup that is not raising', () {
      expect(
        passes(startupItem(raising: 50000), c, 'Raising', 'Under SAR 100K'),
        isTrue,
      );
      expect(
        passes(startupItem(raising: 100000), c, 'Raising', 'SAR 100K – 500K'),
        isTrue,
      );
      expect(
        passes(startupItem(raising: 750000), c, 'Raising', 'SAR 500K – 1M'),
        isTrue,
      );
      expect(
        passes(startupItem(raising: 3000000), c, 'Raising', 'SAR 1M – 5M'),
        isTrue,
      );
      expect(
        passes(startupItem(raising: 9000000), c, 'Raising', 'Over SAR 5M'),
        isTrue,
      );
      expect(
        passes(startupItem(raising: 9000000), c, 'Raising', 'SAR 1M – 5M'),
        isFalse,
      );
      for (final b in SizeBand.labels) {
        expect(passes(startupItem(), c, 'Raising', b), isFalse);
      }
    });

    test('Commerce model: B2B, B2C, B2G', () {
      final it = startupItem(model: BusinessModel.b2g);
      expect(passes(it, c, 'Commerce model', 'B2G'), isTrue);
      expect(passes(it, c, 'Commerce model', 'B2B'), isFalse);
    });

    test('Headquarters is a dropdown with all 22 cities', () {
      final g = HomeFilters.groups(c)
          .firstWhere((g) => g.title == 'Headquarters');
      expect(g.drop, isTrue);
      expect(g.options.length, 22);
      expect(passes(startupItem(), c, 'Headquarters', 'Riyadh'), isTrue);
      expect(passes(startupItem(), c, 'Headquarters', 'Jeddah'), isFalse);
    });

    test('there is no Sort by group: the sort has its own button', () {
      expect(
        HomeFilters.groups(c).map((g) => g.title),
        isNot(contains('Sort by')),
      );
    });
  });

  group('Hub investor filters', () {
    const c = HomeContext.investors;

    test('Commerce models: any of the investor\'s', () {
      final it = investorItem(models: ['B2B', 'B2C']);
      expect(passes(it, c, 'Commerce models', 'B2C'), isTrue);
      expect(passes(it, c, 'Commerce models', 'B2G'), isFalse);
    });

    test('Investment size: matched when the range overlaps the band', () {
      final it = investorItem(ticket: 'SAR 100K – 500K');
      expect(passes(it, c, 'Investment size', 'SAR 100K – 500K'), isTrue);
      expect(passes(it, c, 'Investment size', 'Under SAR 100K'), isFalse);
      expect(passes(it, c, 'Investment size', 'SAR 1M – 5M'), isFalse);
      final wide = investorItem(ticket: 'SAR 500K – 2M');
      expect(passes(wide, c, 'Investment size', 'SAR 500K – 1M'), isTrue);
      expect(passes(wide, c, 'Investment size', 'SAR 1M – 5M'), isTrue);
      expect(passes(wide, c, 'Investment size', 'Over SAR 5M'), isFalse);
      // A ticket that is not a range matches no band.
      final other = investorItem(ticket: 'Other');
      for (final b in SizeBand.labels) {
        expect(passes(other, c, 'Investment size', b), isFalse);
      }
    });

    test('Sectors: a dropdown with all 25, and Other with text', () {
      final g = HomeFilters.groups(c).firstWhere((g) => g.title == 'Sectors');
      expect(g.drop, isTrue);
      expect(g.options.length, 25);
      expect(g.otherHint, 'Type a sector, e.g. SportsTech');
      final custom = investorItem(sectors: ['Fintech', 'SportsTech']);
      bool other([String typed = '']) => HomeFilters.passes(
        custom,
        {
          'Sectors': {'Other'},
          if (typed.isNotEmpty) '__other:Sectors': {typed},
        },
        HomeFilters.groups(c),
        '',
      );
      expect(other(), isTrue);
      expect(other('sports'), isTrue);
      expect(other('Fashion'), isFalse);
      expect(
        HomeFilters.passes(
          investorItem(),
          {
            'Sectors': {'Other'},
          },
          HomeFilters.groups(c),
          '',
        ),
        isFalse,
      );
    });
  });

  group('Hub sort', () {
    late HomeViewModel vm;

    setUp(() {
      DiscoveryRepository.instance = DiscoveryRepository.sample();
      vm = HomeViewModel(role: SessionRole.investor)..setHubSwitch(0);
    });

    tearDown(() => vm.dispose());

    test('only the Hub has the sort button', () {
      vm.selectTab(HomeTab.hub);
      expect(vm.hasSortButton, isTrue);
      vm.selectTab(HomeTab.explore);
      expect(vm.hasSortButton, isFalse);
      vm.selectTab(HomeTab.support);
      expect(vm.hasSortButton, isFalse);
    });

    test('Name A–Z sorts, the same choice again goes back, null clears', () {
      expect(vm.sortChoice, isNull);
      vm.setSort('Name A–Z');
      expect(vm.sortChoice, 'Name A–Z');
      final names = [for (final i in vm.hubCards) i.name.toLowerCase()];
      expect([...names]..sort(), names);
      vm.setSort('Name A–Z');
      expect(vm.sortChoice, isNull);
      vm.setSort('Newest');
      expect(vm.sortChoice, 'Newest');
      vm.setSort(null);
      expect(vm.sortChoice, isNull);
    });

    test(
      'a sort is not a filter: not counted, kept when the filters change',
      () {
        vm.setSort('Name A–Z');
        expect(vm.selectionCount, 0);
        expect(vm.filtering, isFalse);
        vm.applySelection({
          'Sector': {'Fintech'},
        });
        expect(vm.selectionCount, 1);
        expect(vm.sortChoice, 'Name A–Z');
        // The sheet's "Clear all" sends an empty draft.
        vm.applySelection({});
        expect(vm.selectionCount, 0);
        expect(vm.sortChoice, 'Name A–Z');
        vm.clearAll();
        expect(vm.sortChoice, 'Name A–Z');
      },
    );

    test('the sort is remembered per side (startups / investors)', () {
      vm.setSort('Name A–Z');
      vm.setHubSwitch(1);
      expect(vm.sortChoice, isNull);
      vm.setHubSwitch(0);
      expect(vm.sortChoice, 'Name A–Z');
    });
  });

  group('the Hub screen', () {
    const investor = AppUser(
      uid: 'uid2',
      role: AccountRole.investor,
      fullName: 'Layan Alsaab',
      email: 'layan@example.com',
      city: 'Riyadh',
    );

    Future<void> pumpMain(WidgetTester t) async {
      t.view.physicalSize = const Size(824, 1784);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      StartupRepository.instance = FakeStartupRepository();
      DiscoveryRepository.instance = DiscoveryRepository.sample();
      AppSession.instance.reset();
      AppSession.instance.signIn(investor);
      await t.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MainScreen()),
      );
      await t.pump(const Duration(milliseconds: 500));
    }

    testWidgets('named Start.sa Hub in the title and the bottom tab', (
      t,
    ) async {
      await pumpMain(t);
      expect(find.text('Start.sa Hub'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Start.sa Hub')), findsWidgets);
      expect(find.text('Hub'), findsNothing);
      // The posts feed is not built: the cards of the directory.
      expect(find.text('Startups'), findsOneWidget);
      expect(find.text('Investors'), findsOneWidget);
    });

    testWidgets('the sort button sits next to the filter button', (t) async {
      await pumpMain(t);
      final sort = find.bySemanticsLabel('Sort');
      final filter = find.bySemanticsLabel('Advanced search');
      expect(sort, findsOneWidget);
      expect(filter, findsOneWidget);
      expect(t.getCenter(sort).dx, lessThan(t.getCenter(filter).dx));
      expect(
        (t.getCenter(sort).dy - t.getCenter(filter).dy).abs(),
        lessThan(2),
      );
    });

    testWidgets('Sort opens Newest and Name A–Z and the button fills', (
      t,
    ) async {
      await pumpMain(t);
      await t.tap(find.bySemanticsLabel('Sort'));
      await t.pumpAndSettle();
      expect(find.text('Sort by'), findsOneWidget);
      expect(find.text('Newest'), findsOneWidget);
      expect(find.text('Name A–Z'), findsOneWidget);
      await t.tap(find.text('Name A–Z'));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Sort, a sort is chosen'), findsOneWidget);
    });

    testWidgets('the filter sheet has no "Sort by" on the Hub', (t) async {
      await pumpMain(t);
      await t.tap(find.bySemanticsLabel('Advanced search'));
      await t.pumpAndSettle();
      expect(find.text('Advanced search'), findsWidgets);
      expect(find.text('Sort by'), findsNothing);
      expect(find.text('Select sector'), findsOneWidget);
    });

    testWidgets('Support Channels: no mock programs, a calm empty state', (
      t,
    ) async {
      await pumpMain(t);
      await t.tap(find.bySemanticsLabel('Support Channels').last);
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('No support channels yet'), findsOneWidget);
      expect(
        find.text('Support channels are not available yet. Check back soon.'),
        findsOneWidget,
      );
      expect(find.text('Taqadam'), findsNothing);
    });
  });
}
