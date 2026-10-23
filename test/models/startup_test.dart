import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/models/team_member.dart';

void main() {
  const startup = Startup(
    id: 's1',
    founderId: 'u1',
    name: 'Nakhla Pay',
    description: 'A description that is long enough to pass validation rules.',
    sector: Sector.fintech,
    stage: StartupStage.preSeed,
    businessModel: BusinessModel.b2b,
    location: StartupLocation.riyadh,
    foundedYear: 2023,
    websiteUrl: 'https://nakhlapay.sa',
    lookingFor: {LookingFor.mentorship, LookingFor.funding},
    fundingRequirement: 500000,
  );

  test('stores the field names the database uses', () {
    final full = startup.copyWith(
      tagline: 'Card payments on a phone',
      problem: 'p',
      solution: 's',
      customers: 'c',
      advantage: 'a',
      tam: 1,
      sam: 2,
      som: 3,
      growth: 'g',
      capital: 4,
      revenueYear1: 5,
      revenueYear2: 6,
      revenueYear3: 7,
      valuation: 8,
      team: const [
        TeamMember(
          name: 'Faisal Alkhaldi',
          role: 'CTO',
          specialization: 'Cloud',
          yearsExperience: 10,
          bio: 'Short bio',
        ),
      ],
    );
    final map = full.toMap();
    expect(
      map.keys,
      containsAll([
        'oneLinePitch',
        'problem',
        'solution',
        'targetCustomers',
        'differentiation',
        'marketSizeTam',
        'marketSizeSam',
        'marketSizeSom',
        'teamMembers',
        'expectedGrowth',
        'currentAvailableCapital',
        'expectedRevenueYear1',
        'expectedRevenueYear2',
        'expectedRevenueYear3',
        'valuation',
        'founderId',
        'name',
        'description',
        'sector',
        'stage',
        'businessModel',
        'location',
        'foundedYear',
        'websiteUrl',
        'lookingFor',
        'fundingRequirement',
        'isPublic',
        'logoUrl',
      ]),
    );
    expect(map.keys, isNot(contains('tagline')));
    expect(map['teamMembers'], [
      {
        'fullName': 'Faisal Alkhaldi',
        'role': 'CTO',
        'specialization': 'Cloud',
        'yearsOfExperience': 10,
        'shortBio': 'Short bio',
      },
    ]);
    final back = Startup.fromMap('s1', map)!;
    expect(back.team.single.name, 'Faisal Alkhaldi');
    expect(back.tam, 1);
    expect(back.revenueYear3, 7);
  });

  test('sector stored values match the database list', () {
    expect(Sector.values.map((e) => e.value), [
      'healthtech',
      'fintech',
      'edtech',
      'ecommerce',
      'logistics',
      'agritech',
      'proptech',
      'cleantech',
      'tourism',
      'saas',
      'ai',
      'cybersecurity',
      'gaming',
      'media',
      'foodtech',
      'mobility',
      'retail',
      'energy',
      'insurtech',
      'legaltech',
      'hr_tech',
      'biotech',
      'manufacturing',
      'sports',
      'other',
    ]);
    expect(Sector.fromValue('hrtech'), Sector.hrtech);
  });

  test('round-trips through a Firestore map', () {
    final map = startup.toMap();
    final restored = Startup.fromMap('s1', map)!;
    expect(restored.name, startup.name);
    expect(restored.sector, Sector.fintech);
    expect(restored.stage, StartupStage.preSeed);
    expect(restored.businessModel, BusinessModel.b2b);
    expect(restored.location, StartupLocation.riyadh);
    expect(restored.lookingFor, startup.lookingFor);
    expect(restored.fundingRequirement, 500000);
    expect(restored.isPublic, isFalse);
  });

  test('stores the new enum values, in a stable order', () {
    final map = startup.toMap();
    expect(map[StartupFields.sector], 'fintech');
    expect(map[StartupFields.stage], 'pre_seed');
    expect(map[StartupFields.businessModel], 'b2b');
    expect(map[StartupFields.location], 'riyadh');
    expect(map[StartupFields.lookingFor], ['funding', 'mentorship']);
  });

  test('keeps the funding amount whatever is ticked (it is required)', () {
    const noFunding = Startup(
      id: 's2',
      founderId: 'u1',
      name: 'Abc',
      description: 'x',
      sector: Sector.other,
      stage: StartupStage.other,
      businessModel: BusinessModel.b2c,
      location: StartupLocation.other,
      lookingFor: {LookingFor.techDevelopment},
      fundingRequirement: 100,
    );
    expect(noFunding.toMap()[StartupFields.fundingRequirement], 100);
  });

  test('a document with an unknown sector is skipped, not a crash', () {
    final map = {...startup.toMap(), StartupFields.sector: 'space'};
    expect(Startup.fromMap('s1', map), isNull);
  });

  test("initials are the first letters of the first two words (Figma RH)", () {
    expect(startup.initials, "NP"); // Nakhla Pay
    expect(Startup.initialsOf("rafeeq health app"), "RH");
    expect(Startup.initialsOf("  Naql "), "N");
    expect(Startup.initialsOf(""), "?");
  });

  group('Figma lists', () {
    test('sectors are the Figma list', () {
      expect(Sector.values.map((s) => s.label), [
        'HealthTech',
        'Fintech',
        'EdTech',
        'E-commerce',
        'Logistics',
        'AgriTech',
        'PropTech',
        'CleanTech',
        'Tourism',
        'SaaS',
        'AI',
        'Cybersecurity',
        'Gaming',
        'Media',
        'FoodTech',
        'Mobility',
        'Retail',
        'Energy',
        'InsurTech',
        'LegalTech',
        'HR Tech',
        'Biotech',
        'Manufacturing',
        'Sports',
        'Other',
      ]);
    });

    test('cities are exactly the signup city list', () {
      expect(StartupLocation.values.map((c) => c.label), AppStrings.allCities);
    });

    test('stage, commerce model and looking-for options', () {
      expect(StartupStage.values.map((s) => s.label), [
        'Pre-seed',
        'Seed',
        'Series A',
        'Series B',
        'Series C',
        'Other',
      ]);
      expect(BusinessModel.values.map((m) => m.label), [
        'Business-to-Government (B2G)',
        'Business-to-Business (B2B)',
        'Business-to-Business-to-Consumer (B2B2C)',
        'Direct-to-Consumer (D2C)',
        'Business-to-Consumer (B2C)',
        'Consumer-to-Consumer (C2C)',
        'Business-to-Employee (B2E)',
        'Consumer-to-Business (C2B)',
        'Government-to-Citizen (G2C)',
        'Government-to-Government (G2G)',
        'Other',
      ]);
      expect(LookingFor.values.map((l) => l.label), [
        'Funding',
        'Co-founder',
        'Talent',
        'Partnership',
        'Mentorship',
        'Advisors',
        'Marketing',
        'Tech development',
        'Other',
      ]);
    });

    test('commerce model short label is the abbreviation', () {
      expect(BusinessModel.b2c.shortLabel, 'B2C');
      expect(BusinessModel.b2b2c.shortLabel, 'B2B2C');
      expect(BusinessModel.other.shortLabel, 'Other');
    });
  });

  group('legacy values still load', () {
    test('sector', () {
      expect(Sector.fromValue('fintech'), Sector.fintech);
      expect(Sector.fromValue('ecommerce_retail'), Sector.ecommerce);
      expect(Sector.fromValue('logistics_transport'), Sector.logistics);
      expect(Sector.fromValue('food_beverage'), Sector.foodtech);
      expect(Sector.fromValue('software_cloud'), Sector.saas);
      expect(Sector.fromValue('space'), isNull);
    });

    test('stage', () {
      expect(StartupStage.fromValue('idea'), StartupStage.preSeed);
      expect(StartupStage.fromValue('mvp'), StartupStage.preSeed);
      expect(StartupStage.fromValue('early_revenue'), StartupStage.seed);
      expect(StartupStage.fromValue('growth'), StartupStage.seriesA);
      expect(StartupStage.fromValue('series_b'), StartupStage.seriesB);
    });

    test('commerce model', () {
      expect(BusinessModel.fromValue('b2b'), BusinessModel.b2b);
      expect(BusinessModel.fromValue('marketplace'), BusinessModel.other);
    });

    test('location', () {
      expect(StartupLocation.fromValue('riyadh'), StartupLocation.riyadh);
      expect(StartupLocation.fromValue('khobar'), StartupLocation.alKhobar);
      expect(StartupLocation.fromValue('mecca'), StartupLocation.makkah);
      expect(StartupLocation.fromValue('medina'), StartupLocation.madinah);
      expect(StartupLocation.fromValue('other'), StartupLocation.other);
      expect(StartupLocation.fromValue('al_khobar'), StartupLocation.alKhobar);
      // An imported city outside the picker list stays readable.
      expect(StartupLocation.fromValue('al_ula')!.label, 'Al Ula');
      expect(StartupLocation.fromValue('not a city'), isNull);
    });

    test('looking for', () {
      expect(LookingFor.fromValue('partnerships'), LookingFor.partnership);
      expect(LookingFor.fromValue('team_members'), LookingFor.talent);
      expect(LookingFor.fromValue('services'), LookingFor.techDevelopment);
      expect(LookingFor.fromValue('funding'), LookingFor.funding);
    });

    test('a whole old document loads and is rewritten with new values', () {
      final old = {
        StartupFields.founderId: 'u1',
        StartupFields.name: 'Old Co',
        StartupFields.tagline: 'Old one-liner',
        StartupFields.description: 'An old description of a startup.',
        StartupFields.sector: 'logistics_transport',
        StartupFields.stage: 'early_revenue',
        StartupFields.businessModel: 'marketplace',
        StartupFields.location: 'khobar',
        StartupFields.lookingFor: ['funding', 'team_members', 'services'],
        StartupFields.fundingRequirement: 1000,
        StartupFields.isPublic: true,
      };
      final loaded = Startup.fromMap('old', old)!;
      expect(loaded.tagline, 'Old one-liner');
      final saved = loaded.toMap();
      expect(saved[StartupFields.sector], 'logistics');
      expect(saved[StartupFields.stage], 'seed');
      expect(saved[StartupFields.businessModel], 'other');
      expect(saved[StartupFields.location], 'al_khobar');
      expect(saved[StartupFields.lookingFor], [
        'funding',
        'talent',
        'tech_development',
      ]);
      // The tagline is carried over untouched.
      expect(saved[StartupFields.tagline], 'Old one-liner');
    });
  });

  group('summary (the short line on cards)', () {
    Startup withText({String? tagline, String description = ''}) => Startup(
      id: 's',
      founderId: 'u',
      name: 'N',
      tagline: tagline,
      description: description,
      sector: Sector.other,
      stage: StartupStage.other,
      businessModel: BusinessModel.other,
      location: StartupLocation.riyadh,
      lookingFor: const {LookingFor.funding},
    );

    test('is the brief description', () {
      expect(withText(description: ' Short line ').summary, 'Short line');
    });

    test('line breaks collapse into one flowing text', () {
      expect(
        withText(description: 'First line.\n\nSecond   line.').summary,
        'First line. Second line.',
      );
    });

    test('an older startup with only a pitch falls back to it', () {
      expect(withText(tagline: ' Old pitch ').briefDescription, 'Old pitch');
      expect(withText().summary, '');
    });
  });

  group('redesign fields', () {
    test('round-trip through the map', () {
      final full = startup.copyWith(
        problem: 'p',
        solution: 's',
        customers: 'c',
        advantage: 'a',
        tam: 2400000000,
        sam: 600000000,
        som: 24000000,
        team: const [
          TeamMember(
            name: 'Faisal Alkhaldi',
            role: 'CTO',
            specialization: 'Mobile',
            yearsExperience: 10,
            bio: 'b',
          ),
        ],
        growth: 'g',
        capital: 350000,
        revenueYear1: 1,
        revenueYear2: 2,
        revenueYear3: 3,
        valuation: 0,
        wantsLeadInvestor: true,
      );
      final back = Startup.fromMap('s1', full.toMap())!;
      expect(back.tam, 2400000000);
      expect(back.team.single.meta, 'CTO · 10 yrs · Mobile');
      expect(back.team.single.initials, 'FA');
      expect(back.valuation, 0);
      expect(back.wantsLeadInvestor, isTrue);
      expect(back.expectedRevenue, [1, 2, 3]);
      expect(back.hasBusinessDetails, isTrue);
    });

    test('an old document without them still loads', () {
      final back = Startup.fromMap('s1', startup.toMap())!;
      expect(back.team, isEmpty);
      expect(back.tam, isNull);
      expect(back.wantsLeadInvestor, isNull);
      expect(back.problem, '');
    });
  });
}
