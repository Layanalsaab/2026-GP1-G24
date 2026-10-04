import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';

void main() {
  const startup = Startup(
    id: 's1',
    founderId: 'u1',
    name: 'Nakhla Pay',
    tagline: 'Payments for small shops',
    description: 'A description that is long enough to pass validation rules.',
    sector: Sector.fintech,
    stage: StartupStage.mvp,
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
    expect(restored.stage, StartupStage.mvp);
    expect(restored.lookingFor, startup.lookingFor);
    expect(restored.fundingRequirement, 500000);
    expect(restored.isPublic, isFalse);
  });

  test('stores enum values, in a stable order', () {
    final map = startup.toMap();
    expect(map[StartupFields.sector], 'fintech');
    expect(map[StartupFields.lookingFor], ['funding', 'mentorship']);
  });

  test('drops the funding amount when not looking for funding', () {
    const noFunding = Startup(
      id: 's2',
      founderId: 'u1',
      name: 'Abc',
      description: 'x',
      sector: Sector.other,
      stage: StartupStage.idea,
      businessModel: BusinessModel.b2c,
      location: StartupLocation.other,
      lookingFor: {LookingFor.services},
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
}
