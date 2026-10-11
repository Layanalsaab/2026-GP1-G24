import '../../models/investor_profile.dart';

/// Sample investors for the design phase (the names and text come from Figma).
class MockInvestors {
  MockInvestors._();

  static const ahmad = InvestorProfile(
    id: 'mock-ahmad',
    name: 'Ahmad Hassan',
    title: 'Angel Investor',
    city: 'Riyadh',
    about:
        'Backing early-stage health and fintech founders building for Saudi '
        'families and small businesses.',
    bio:
        'Ahmad is an angel investor based in Riyadh with ten years in '
        'healthcare operations. He backs pre-seed and seed founders in '
        'health and fintech, and is happy to open doors to hospitals and '
        'banks.',
    sectors: ['HealthTech', 'Fintech'],
    stages: ['Pre-seed', 'Seed'],
    ticketRange: 'SAR 100K – 500K',
    locations: ['Riyadh', 'Jeddah'],
  );

  static const sara = InvestorProfile(
    id: 'mock-sara',
    name: 'Sara Al-Mohsen',
    title: 'VC Associate',
    city: 'Jeddah',
    about:
        'Looking for EdTech and SaaS teams with early traction and a clear '
        'path to Seed.',
    bio:
        'Sara works on the early-stage team of a Jeddah venture fund. She '
        'looks for EdTech and SaaS teams with paying customers and a clear '
        'path to a Seed round.',
    sectors: ['EdTech', 'SaaS'],
    stages: ['Seed', 'Series A'],
    ticketRange: 'SAR 500K – 2M',
    locations: ['Jeddah', 'Riyadh'],
  );

  static const omar = InvestorProfile(
    id: 'mock-omar',
    name: 'Omar Khalid',
    title: 'Angel Investor',
    city: 'Riyadh',
    about: 'Interested in startups solving last-mile delivery in the Kingdom.',
    bio:
        'Omar is a former supply-chain executive turned angel investor. He '
        'invests small tickets in logistics and e-commerce startups that '
        'make delivery cheaper and faster across the Kingdom.',
    sectors: ['Logistics', 'E-commerce'],
    stages: ['Pre-seed'],
    ticketRange: 'SAR 50K – 200K',
    locations: ['Riyadh'],
  );

  static const nora = InvestorProfile(
    id: 'mock-nora',
    name: 'Nora Alqahtani',
    title: 'Angel Investor',
    city: 'Dammam',
    about:
        'Supporting AgriTech and CleanTech teams that save water and '
        'energy across the Eastern Province.',
    bio:
        'Nora is an angel investor in Dammam with a background in '
        'renewable energy projects. She backs AgriTech and CleanTech '
        'founders at Seed and Series A who can show measurable savings.',
    sectors: ['AgriTech', 'CleanTech'],
    stages: ['Seed', 'Series A'],
    ticketRange: 'SAR 300K – 1M',
    locations: ['Dammam', 'Riyadh'],
  );

  /// The sample investor with this exact name, or null (e.g. an investor who
  /// is not part of the sample data).
  static InvestorProfile? byName(String name) {
    final wanted = name.trim().toLowerCase();
    for (final investor in [ahmad, sara, omar, nora]) {
      if (investor.name.toLowerCase() == wanted) return investor;
    }
    return null;
  }

  /// Explore > For You (founder) and Hub (founder).
  static List<InvestorProfile> get forYou => [ahmad, sara, omar, nora];

  /// Explore > Matches (founder).
  static List<InvestorProfile> get matches => [
    ahmad.withMatch(92, 'Same sector and stage'),
    sara.withMatch(81, 'Same sector'),
    omar.withMatch(74, 'Same region'),
  ];
}
