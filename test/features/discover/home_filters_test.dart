import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/features/search/view_models/home_filters.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/models/investor_profile.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/shared_ui/widgets/overlays/advanced_search_sheet.dart';

void main() {
  const startup = Startup(
    id: 's1',
    founderId: 'f',
    name: 'Nakhla Pay',
    description: 'd',
    sector: Sector.fintech,
    stage: StartupStage.seed,
    businessModel: BusinessModel.b2b,
    location: StartupLocation.alKhobar,
    lookingFor: {LookingFor.funding, LookingFor.mentorship},
    fundingRequirement: 1500000,
  );
  final startupItem = HomeItem.fromStartup(startup);
  const investor = InvestorProfile(
    id: 'i1',
    name: 'Ahmad Hassan',
    title: 'Angel Investor',
    city: 'Riyadh',
    sectors: ['Fintech', 'HealthTech'],
    stages: ['Pre-seed', 'Seed', 'Series A'],
    ticketRange: 'SAR 100K – 500K',
    locations: ['Riyadh'],
  );
  final investorItem = HomeItem.fromInvestor(investor);

  bool passes(HomeItem it, HomeContext ctx, String group, String option) =>
      HomeFilters.passes(
        it,
        {
          group: {option},
        },
        HomeFilters.groups(ctx),
        '',
      );

  test('startup filters read the stored values', () {
    const c = HomeContext.startups;
    expect(passes(startupItem, c, 'Sector', 'Fintech'), isTrue);
    expect(passes(startupItem, c, 'Sector', 'HealthTech'), isFalse);
    expect(passes(startupItem, c, 'Stage', 'Seed'), isTrue);
    expect(passes(startupItem, c, 'Stage', 'Series A'), isFalse);
    expect(passes(startupItem, c, 'Headquarters', 'Al Khobar'), isTrue);
    expect(passes(startupItem, c, 'Looking for', 'Mentorship'), isTrue);
    expect(passes(startupItem, c, 'Looking for', 'Talent'), isFalse);
    expect(passes(startupItem, c, 'Commerce model', 'B2B'), isTrue);
    expect(passes(startupItem, c, 'Raising', 'SAR 1M – 5M'), isTrue);
    expect(passes(startupItem, c, 'Raising', 'Under SAR 100K'), isFalse);
    expect(passes(startupItem, c, 'Raising', 'Over SAR 5M'), isFalse);
  });

  test('investor filters read every stage and the ticket', () {
    const c = HomeContext.investors;
    expect(passes(investorItem, c, 'Sectors', 'HealthTech'), isTrue);
    expect(passes(investorItem, c, 'Stages', 'Seed'), isTrue);
    expect(passes(investorItem, c, 'Stages', 'Series B'), isFalse);
    expect(passes(investorItem, c, 'Investment size', 'SAR 100K – 500K'), isTrue);
    expect(passes(investorItem, c, 'Investment size', 'Over SAR 5M'), isFalse);
    expect(
      HomeFilters.groups(c).map((g) => g.title),
      isNot(contains('Investor type')),
      reason: 'every investor is an angel investor: nothing to filter',
    );
    expect(passes(investorItem, c, 'City', 'Riyadh'), isTrue);
  });

  test('the sheet offers every sector and city the data can hold', () {
    final sectors = HomeFilters.groups(HomeContext.startups).first.options;
    expect(sectors, containsAll(['HR Tech', 'Manufacturing', 'Other']));
    final cities = HomeFilters.groups(HomeContext.investors)
        .firstWhere((g) => g.title == 'City')
        .options;
    expect(cities, contains('Al Khobar'));
  });

  group('Explore filters: dropdowns and Other', () {
    test('Sector and City are dropdowns with every option; Stage stays chips', () {
      final g = {for (final x in HomeFilters.groups(HomeContext.explore)) x.title: x};
      expect(g.keys, ['Sector', 'Stage', 'City', 'Sort by']);
      expect(g['Sector']!.drop, isTrue);
      expect(g['Sector']!.options.length, 25);
      expect(g['Sector']!.options.last, 'Other');
      expect(g['Sector']!.otherHint, 'Type a sector, e.g. SportsTech');
      expect(g['City']!.drop, isTrue);
      expect(g['City']!.options.length, 22);
      expect(g['Stage']!.drop, isFalse);
      expect(g['Stage']!.options, [
        'Pre-seed',
        'Seed',
        'Series A',
        'Series B',
        'Series C',
      ]);
      expect(g['Sort by']!.single, isTrue);
      expect(g['Sort by']!.options, ['Newest', 'Name A–Z']);
    });

    test('the sheet groups carry the dropdown and the Other placeholder', () {
      final sheet = HomeFilters.sheetGroups(HomeContext.explore);
      expect(sheet.first.drop, isTrue);
      expect(sheet.first.hasOther, isTrue);
      expect(sheet[1].drop, isFalse);
      expect(sheet[2].hasOther, isFalse);
    });

    // A startup whose sector is not in the standard list (typed by its founder).
    final custom = HomeItem.fromStartup(
      startup.copyWith(
        sector: Sector.other,
        sectorOther: 'SportsTech',
        otherSectors: const ['Esports'],
      ),
    );

    bool other(HomeItem it, [String typed = '']) => HomeFilters.passes(
      it,
      {
        'Sector': {'Other'},
        if (typed.isNotEmpty) '__other:Sector': {typed},
      },
      HomeFilters.groups(HomeContext.explore),
      '',
    );

    test('Other with no text: every item with a sector outside the list', () {
      expect(other(custom), isTrue);
      expect(other(startupItem), isFalse);
      expect(other(investorItem), isFalse);
    });

    test('Other with text: what is typed, any case, part of a word', () {
      expect(other(custom, 'SportsTech'), isTrue);
      expect(other(custom, 'sports'), isTrue);
      expect(other(custom, 'ESPORTS'), isTrue);
      expect(other(custom, 'Fashion'), isFalse);
      // A standard sector is not an "Other" match, even if typed.
      expect(other(startupItem, 'Fintech'), isFalse);
    });

    test('Other together with a listed sector is either / or', () {
      final both = HomeFilters.passes(
        startupItem,
        {
          'Sector': {'Fintech', 'Other'},
        },
        HomeFilters.groups(HomeContext.explore),
        '',
      );
      expect(both, isTrue);
    });

    test('the typed text is never counted as a filter', () {
      final groups = HomeFilters.sheetGroups(HomeContext.explore);
      expect(
        advancedSelectionCount(groups, {
          'Sector': {'Other'},
          '__other:Sector': {'SportsTech'},
        }),
        1,
      );
    });
  });
}
