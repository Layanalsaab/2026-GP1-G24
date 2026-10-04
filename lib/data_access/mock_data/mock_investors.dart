import '../../models/investor_profile.dart';

/// Sample investors for the design phase (the names and text come from Figma).
class MockInvestors {
  MockInvestors._();

  static const _matchReason = 'Why: same sector and stage';

  static const ahmad = InvestorProfile(
    id: 'mock-ahmad',
    name: 'Ahmad Hassan',
    title: 'Angel Investor',
    city: 'Riyadh',
    sectors: ['HealthTech', 'Fintech', 'EdTech'],
    stages: ['Pre-seed', 'Seed'],
    ticketRange: 'SAR 100K – 500K',
    locations: ['Riyadh', 'Jeddah'],
  );

  static const sara = InvestorProfile(
    id: 'mock-sara',
    name: 'Sara Al-Mohsen',
    title: 'VC Associate',
    city: 'Jeddah',
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
    sectors: ['Logistics', 'E-commerce'],
    stages: ['Pre-seed'],
    ticketRange: 'SAR 50K – 200K',
    locations: ['Riyadh'],
  );

  /// Explore > For You (founder) and Hub (founder).
  static List<InvestorProfile> get forYou => [ahmad, sara, omar];

  /// Explore > Matches (founder).
  static List<InvestorProfile> get matches => [
        ahmad.withMatch(82, _matchReason),
        sara.withMatch(76, _matchReason),
        omar.withMatch(71, _matchReason),
      ];
}
