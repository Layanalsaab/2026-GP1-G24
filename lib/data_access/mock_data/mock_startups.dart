import '../../models/startup.dart';
import '../../models/startup_association.dart';
import '../../models/startup_enums.dart';
import '../../models/startup_listing.dart';

/// Sample startups for the design phase (the names and text come from Figma).
/// Screens read from here through their view models; once startups are
/// loaded from Firestore, only the view models need to change.
class MockStartups {
  MockStartups._();

  /// True for the built-in sample startups (ids start with "mock-"). A
  /// startup a user created is never a sample, so it shows no sample numbers.
  static bool isSample(Startup startup) => startup.id.startsWith('mock-');

  /// The sample associations of a sample [startup]; empty for a real one.
  static List<StartupAssociation> associationsOf(Startup startup) {
    if (!isSample(startup)) return const [];
    for (final listing in [rafeeq, daftar, naql, mizan, sanabil]) {
      if (listing.startup.id == startup.id) return listing.associations;
    }
    return const [];
  }

  /// Sample founder names for the design phase, by `founderId`. Real startups
  /// don't use this: their founder name is not loaded on the profile.
  static const _founderNames = {
    'mock-founder-1': 'Shahad Alabdulkarim',
    'mock-founder-2': 'Noura Alsubaie',
    'mock-founder-3': 'Faisal Alotaibi',
    'mock-founder-4': 'Reem Alqahtani',
    'mock-founder-5': 'Khalid Alharbi',
  };

  /// The sample founder of a sample [startup]; null for a real startup.
  static String? founderNameOf(Startup startup) =>
      _founderNames[startup.founderId];

  static final rafeeq = StartupListing(
    startup: const Startup(
      id: 'mock-rafeeq',
      founderId: 'mock-founder-1',
      name: 'Rafeeq Health',
      tagline:
          'Home nursing visits booked in minutes. Licensed nurses and '
          'transparent pricing.',
      description:
          'Rafeeq Health is a mobile platform that lets families book '
          'licensed home nurses. Visits are confirmed within minutes, and '
          'every nurse is verified by our clinical team.',
      sector: Sector.healthtech,
      stage: StartupStage.preSeed,
      businessModel: BusinessModel.b2c,
      location: StartupLocation.riyadh,
      foundedYear: 2024,
      websiteUrl: 'https://rafeeq.example.com',
      lookingFor: {LookingFor.funding},
      fundingRequirement: 500000,
      isPublic: true,
    ),
    sectorStage: 'HealthTech · Pre-seed',
    city: 'Riyadh',
    teamSize: 2,
    lookingForNote:
        'A marketing specialist with experience in Saudi healthcare.',
    associations: [
      StartupAssociation(name: 'Ahmad Hassan', subtitle: 'Riyadh'),
      StartupAssociation(
        name: 'Omar Khalid',
        subtitle: 'Riyadh',
        status: AssociationStatus.waiting,
        isPublic: false,
      ),
    ],
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
      stage: StartupStage.preSeed,
      businessModel: BusinessModel.b2b,
      location: StartupLocation.jeddah,
      foundedYear: 2024,
      websiteUrl: 'https://daftar.example.com',
      lookingFor: {LookingFor.partnership},
      isPublic: true,
    ),
    sectorStage: 'Fintech · Pre-seed',
    teamSize: 3,
    lookingForNote: 'A fintech partner to connect Daftar with local banks.',
    associations: [
      StartupAssociation(name: 'Sara Al-Mohsen', subtitle: 'Jeddah'),
      StartupAssociation(
        name: 'Ahmad Hassan',
        subtitle: 'Riyadh',
        isPublic: false,
      ),
    ],
    city: 'Jeddah',
    initialsOverride: 'DF',
  );

  static final naql = StartupListing(
    startup: const Startup(
      id: 'mock-naql',
      founderId: 'mock-founder-3',
      name: 'Naql',
      tagline:
          'Shared last-mile delivery for small shops, pooling routes to cut '
          'costs.',
      description:
          'Naql pools deliveries from small shops into shared routes, '
          'cutting delivery costs for merchants across Riyadh.',
      sector: Sector.logistics,
      stage: StartupStage.seed,
      businessModel: BusinessModel.b2b,
      location: StartupLocation.riyadh,
      foundedYear: 2022,
      websiteUrl: 'https://naql.example.com',
      lookingFor: {LookingFor.funding},
      fundingRequirement: 1200000,
      isPublic: true,
    ),
    sectorStage: 'Logistics · Seed',
    teamSize: 8,
    lookingForNote: 'Growth capital to add routes in Jeddah and Dammam.',
    associations: [StartupAssociation(name: 'Omar Khalid', subtitle: 'Riyadh')],
    city: 'Riyadh',
    initialsOverride: 'NQ',
  );

  static final mizan = StartupListing(
    startup: const Startup(
      id: 'mock-mizan',
      founderId: 'mock-founder-2',
      name: 'Mizan Learn',
      tagline:
          'Tutoring marketplace connecting K-12 students with verified '
          'tutors.',
      description:
          'Mizan Learn connects K-12 students with vetted tutors for live '
          'one-to-one lessons, with progress reports for parents.',
      sector: Sector.edtech,
      stage: StartupStage.seed,
      businessModel: BusinessModel.other,
      location: StartupLocation.jeddah,
      foundedYear: 2023,
      websiteUrl: 'https://mizanlearn.example.com',
      lookingFor: {LookingFor.talent},
      isPublic: true,
    ),
    sectorStage: 'EdTech · Seed',
    teamSize: 6,
    lookingForNote: 'Experienced engineers to build our learning platform.',
    associations: [
      StartupAssociation(name: 'Sara Al-Mohsen', subtitle: 'Jeddah'),
    ],
    city: 'Jeddah',
  );

  static final sanabil = StartupListing(
    startup: Startup(
      id: 'mock-sanabil',
      founderId: 'mock-founder-5',
      name: 'Sanabil Agri',
      tagline: 'Smart irrigation and crop advice for small farms.',
      description:
          'Sanabil Agri helps small farms in Qassim save water with smart '
          'irrigation and simple crop advice.',
      sector: Sector.agritech,
      stage: StartupStage.preSeed,
      businessModel: BusinessModel.b2b,
      location: StartupLocation.values.firstWhere(
        (l) => l.value == 'buraydah',
        orElse: () => StartupLocation.riyadh,
      ),
      foundedYear: 2025,
      websiteUrl: 'https://sanabil.example.com',
      lookingFor: const {LookingFor.mentorship},
      isPublic: true,
    ),
    sectorStage: 'AgriTech · Pre-seed',
    teamSize: 2,
    lookingForNote: 'A mentor with experience scaling hardware startups.',
    associations: [
      StartupAssociation(name: 'Nora Alqahtani', subtitle: 'Dammam'),
    ],
    city: 'Qassim',
  );

  /// Explore > For You (investor) and Hub (investor, guest).
  static List<StartupListing> get forYou => [
    rafeeq,
    daftar,
    naql,
    mizan,
    sanabil,
  ];

  /// Explore > Trending, ranked 1 to 5.
  static List<StartupListing> get trending => [
    rafeeq,
    daftar,
    naql,
    mizan,
    sanabil,
  ];

  /// Explore > Matches (investor).
  static List<StartupListing> get matches => [
    rafeeq.withMatch(94, 'Same sector, stage and region'),
    daftar.withMatch(86, 'Same sector and stage'),
    naql.withMatch(71, 'Same stage and region'),
  ];
}
