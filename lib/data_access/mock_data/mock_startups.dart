import '../../models/startup.dart';
import '../../models/startup_enums.dart';
import '../../models/startup_listing.dart';

/// Sample startups for the design phase (the names and text come from Figma).
/// Screens read from here through their view models; once startups are
/// loaded from Firestore, only the view models need to change.
class MockStartups {
  MockStartups._();

  static const _matchReason = 'Why: matches your investment preferences';

  static final rafeeq = StartupListing(
    startup: const Startup(
      id: 'mock-rafeeq',
      founderId: 'mock-founder-1',
      name: 'Rafeeq Health',
      tagline: 'Home nursing visits booked in minutes across Riyadh.',
      description:
          'Rafeeq Health is a mobile platform that lets families book '
          'licensed home nurses. Visits are confirmed within minutes, and '
          'every nurse is verified by our clinical team.',
      sector: Sector.healthtech,
      stage: StartupStage.mvp,
      businessModel: BusinessModel.b2c,
      location: StartupLocation.riyadh,
      foundedYear: 2024,
      websiteUrl: 'https://rafeeq.example.com',
      lookingFor: {LookingFor.funding, LookingFor.teamMembers},
      fundingRequirement: 500000,
      isPublic: true,
    ),
    sectorStage: 'HealthTech · Pre-seed',
    city: 'Riyadh',
    teamSize: 2,
    lookingForNote: 'A marketing specialist with experience in Saudi healthcare.',
    associations: [
      (name: 'Ahmad Hassan', subtitle: 'Angel Investor · Invested 2026'),
    ],
  );

  static final mizan = StartupListing(
    startup: const Startup(
      id: 'mock-mizan',
      founderId: 'mock-founder-2',
      name: 'Mizan Learn',
      tagline: 'Tutoring marketplace for K-12 students.',
      description:
          'Mizan Learn connects K-12 students with vetted tutors for live '
          'one-to-one lessons, with progress reports for parents.',
      sector: Sector.edtech,
      stage: StartupStage.earlyRevenue,
      businessModel: BusinessModel.marketplace,
      location: StartupLocation.jeddah,
      foundedYear: 2023,
      lookingFor: {LookingFor.funding},
      fundingRequirement: 1200000,
      isPublic: true,
    ),
    sectorStage: 'EdTech · Seed',
    city: 'Jeddah',
  );

  static final naql = StartupListing(
    startup: const Startup(
      id: 'mock-naql',
      founderId: 'mock-founder-3',
      name: 'Naql',
      tagline: 'Shared last-mile delivery for small shops.',
      description:
          'Naql pools deliveries from small shops into shared routes, '
          'cutting delivery costs for merchants across Riyadh.',
      sector: Sector.logisticsTransport,
      stage: StartupStage.earlyRevenue,
      businessModel: BusinessModel.b2b,
      location: StartupLocation.riyadh,
      foundedYear: 2022,
      lookingFor: {LookingFor.funding, LookingFor.partnerships},
      fundingRequirement: 2000000,
      isPublic: true,
    ),
    sectorStage: 'Logistics · Seed',
    city: 'Riyadh',
    initialsOverride: 'NQ',
  );

  static final daftar = StartupListing(
    startup: const Startup(
      id: 'mock-daftar',
      founderId: 'mock-founder-4',
      name: 'Daftar',
      tagline: 'Bookkeeping and e-invoicing for micro businesses.',
      description:
          'Daftar gives micro businesses simple bookkeeping and ZATCA-ready '
          'e-invoicing from their phone.',
      sector: Sector.fintech,
      stage: StartupStage.mvp,
      businessModel: BusinessModel.b2b,
      location: StartupLocation.jeddah,
      foundedYear: 2024,
      lookingFor: {LookingFor.funding},
      fundingRequirement: 400000,
      isPublic: true,
    ),
    sectorStage: 'Fintech · Pre-seed',
    city: 'Jeddah',
    initialsOverride: 'DF',
  );

  /// Explore > For You (investor) and Hub (investor).
  static List<StartupListing> get forYou => [rafeeq, naql, daftar];

  /// Explore > Trending, ranked 1 to 3.
  static List<StartupListing> get trending => [rafeeq, mizan, naql];

  /// Explore > Matches (investor).
  static List<StartupListing> get matches => [
        rafeeq.withMatch(82, _matchReason),
        mizan.withMatch(76, _matchReason),
        naql.withMatch(71, _matchReason),
      ];
}
