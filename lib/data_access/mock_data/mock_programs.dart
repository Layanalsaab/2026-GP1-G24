import '../../models/program.dart';

/// Sample support programs for the design phase (text from Figma).
class MockPrograms {
  MockPrograms._();

  static const taqadam = Program(
    id: 'mock-taqadam',
    name: 'TAQADAM by KAUST',
    type: ProgramType.accelerator,
    city: 'Thuwal',
    duration: '6 months',
    sinceYear: 2017,
    about:
        "TAQADAM is KAUST's flagship startup accelerator, supporting "
        'early-stage tech startups with mentorship, funding, and workspace.',
    summary: 'University startup accelerator run by KAUST.',
    focus: 'University and deep-tech startups',
    focusSectors: ['HealthTech', 'DeepTech', 'CleanTech', 'AI'],
    websiteUrl: 'https://taqadam.example.com',
  );

  static const badir = Program(
    id: 'mock-badir',
    name: 'Badir Program',
    type: ProgramType.incubator,
    city: 'Riyadh',
    duration: '12 months',
    sinceYear: 2008,
    about:
        'Badir supports technology startups with incubation, workspace and '
        'access to a network of partners.',
    summary: 'Technology incubator supporting early-stage startups.',
    focus: 'Early-stage tech',
    focusSectors: ['Fintech', 'EdTech', 'Logistics'],
  );

  static const bim = Program(
    id: 'mock-bim',
    name: 'BIM Ventures',
    type: ProgramType.studio,
    city: 'Riyadh',
    duration: '9 months',
    sinceYear: 2019,
    about:
        'BIM Ventures is a startup studio that builds companies together '
        'with founders.',
    summary: 'Venture studio that co-builds new startups.',
    focus: 'Co-building startups',
    logoText: 'BV',
    focusSectors: ['E-commerce', 'SaaS'],
  );

  static const aqal = Program(
    id: 'mock-aqal',
    name: 'Aqal',
    type: ProgramType.angelNetwork,
    city: 'Riyadh',
    duration: 'Ongoing',
    sinceYear: 2020,
    about: 'Aqal is a network connecting angel investors with startups.',
    summary: 'Network connecting angel investors with startups.',
    focus: 'Angel investment',
    logoText: 'AQ',
    focusSectors: ['Fintech', 'HealthTech'],
  );

  static List<Program> get all => [taqadam, badir, bim, aqal];
}
