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
    focusSectors: ['E-commerce', 'SaaS'],
  );

  static List<Program> get all => [taqadam, badir, bim];
}
