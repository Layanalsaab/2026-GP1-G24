import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/features/search/view_models/home_filters.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/models/investor_profile.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';

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
    expect(passes(startupItem, c, 'City', 'Al Khobar'), isTrue);
    expect(passes(startupItem, c, 'Looking for', 'Mentorship'), isTrue);
    expect(passes(startupItem, c, 'Looking for', 'Talent'), isFalse);
    expect(passes(startupItem, c, 'Commerce model', 'B2B'), isTrue);
    expect(passes(startupItem, c, 'Raising', 'SAR 1M – 5M'), isTrue);
    expect(passes(startupItem, c, 'Raising', 'Under SAR 250K'), isFalse);
    expect(passes(startupItem, c, 'Raising', 'Over SAR 5M'), isFalse);
  });

  test('investor filters read every stage and the ticket', () {
    const c = HomeContext.investors;
    expect(passes(investorItem, c, 'Sector', 'HealthTech'), isTrue);
    expect(passes(investorItem, c, 'Stages they invest in', 'Seed'), isTrue);
    expect(
      passes(investorItem, c, 'Stages they invest in', 'Series B'),
      isFalse,
    );
    expect(passes(investorItem, c, 'Ticket size', 'SAR 100K – 500K'), isTrue);
    expect(passes(investorItem, c, 'Ticket size', 'Over SAR 5M'), isFalse);
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
}
