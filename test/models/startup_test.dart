import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';

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

  test('drops the funding amount when not looking for funding', () {
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
    expect(noFunding.toMap()[StartupFields.fundingRequirement], isNull);
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
      expect(Sector.fromValue('food_beverage'), Sector.other);
      expect(Sector.fromValue('software_cloud'), Sector.other);
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
      expect(StartupLocation.fromValue('atlantis'), isNull);
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

    test('uses the legacy tagline when there is one', () {
      expect(
        withText(tagline: ' Short line ', description: 'Other text.').summary,
        'Short line',
      );
    });

    test('otherwise the first sentence of the description', () {
      expect(
        withText(
          description:
              'Rafeeq Health connects families with nurses. Book in minutes.',
        ).summary,
        'Rafeeq Health connects families with nurses.',
      );
      expect(
        withText(description: 'No full stop here').summary,
        'No full stop here',
      );
      expect(withText().summary, '');
    });

    test('long sentences are cut at a word boundary with an ellipsis', () {
      final summary = withText(description: 'word ' * 60).summary;
      expect(summary.length, lessThanOrEqualTo(Startup.summaryMaxLength + 1));
      expect(summary, endsWith('…'));
      expect(summary, isNot(contains('wor…')));
    });
  });
}
