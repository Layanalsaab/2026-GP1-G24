import '../../../models/home_item.dart';
import '../../../shared_ui/widgets/overlays/advanced_search_sheet.dart';

/// Which list the search bar and the advanced search sheet act on
/// (prototype `homeCtx`).
enum HomeContext { support, explore, investors, startups }

/// One advanced-search group plus how it filters a [HomeItem].
class HomeFilterGroup {
  const HomeFilterGroup(
    this.title,
    this.options, {
    this.field,
    this.single = false,
  });

  final String title;
  final List<String> options;

  /// Which item field this group matches; null = display only (the sample
  /// data has no such field; it still counts in the badge and chips).
  final HomeFilterField? field;
  final bool single;
}

/// The item field a group filters on.
enum HomeFilterField { sectors, stage, looking, type, city, model }

/// The advanced search groups, the filtering and the sorting of the home
/// pages. Pure so it is easy to test (docs/05 section B5).
class HomeFilters {
  HomeFilters._();

  static const _sectors = [
    'HealthTech',
    'Fintech',
    'EdTech',
    'Logistics',
    'AgriTech',
    'SaaS',
    'E-commerce',
  ];
  static const _stages = ['Pre-seed', 'Seed', 'Series A', 'Series B+'];
  static const _money = [
    'Under SAR 250K',
    'SAR 250K – 1M',
    'SAR 1M – 5M',
    'Over SAR 5M',
  ];
  static const _sort = HomeFilterGroup('Sort by', [
    'Newest',
    'Name A–Z',
  ], single: true);

  /// The groups shown in the sheet for [ctx].
  static List<HomeFilterGroup> groups(HomeContext ctx) {
    switch (ctx) {
      case HomeContext.support:
        return const [
          HomeFilterGroup('Type', [
            'Accelerator',
            'Incubator',
            'Startup studio',
          ], field: HomeFilterField.type),
          HomeFilterGroup('Sector focus', [
            'HealthTech',
            'Fintech',
            'EdTech',
            'Logistics',
            'AgriTech',
            'SaaS',
            'DeepTech',
          ], field: HomeFilterField.sectors),
          HomeFilterGroup('Program length', [
            'Under 6 months',
            '6 – 12 months',
            'Ongoing',
          ]),
          HomeFilterGroup('City', [
            'Riyadh',
            'Jeddah',
            'Thuwal',
            'Dammam',
          ], field: HomeFilterField.city),
          HomeFilterGroup('Sort by', ['Name A–Z', 'Newest'], single: true),
        ];
      case HomeContext.investors:
        return const [
          HomeFilterGroup('Sector', _sectors, field: HomeFilterField.sectors),
          HomeFilterGroup(
            'Stages they invest in',
            _stages,
            field: HomeFilterField.stage,
          ),
          HomeFilterGroup('Investor type', [
            'Angel investor',
            'VC firm',
            'Angel network',
            'Corporate',
          ]),
          HomeFilterGroup('Ticket size', _money),
          HomeFilterGroup('City', [
            'Riyadh',
            'Jeddah',
            'Dammam',
            'Khobar',
          ], field: HomeFilterField.city),
          _sort,
        ];
      case HomeContext.explore:
        return const [
          HomeFilterGroup('Sector', _sectors, field: HomeFilterField.sectors),
          HomeFilterGroup('Stage', _stages, field: HomeFilterField.stage),
          HomeFilterGroup('City', [
            'Riyadh',
            'Jeddah',
            'Dammam',
            'Qassim',
          ], field: HomeFilterField.city),
          _sort,
        ];
      case HomeContext.startups:
        return const [
          HomeFilterGroup('Sector', _sectors, field: HomeFilterField.sectors),
          HomeFilterGroup('Stage', _stages, field: HomeFilterField.stage),
          HomeFilterGroup('Looking for', [
            'Funding',
            'Talent',
            'Partnership',
            'Mentorship',
          ], field: HomeFilterField.looking),
          HomeFilterGroup('Raising', _money),
          HomeFilterGroup('Commerce model', [
            'B2B',
            'B2C',
            'B2B2C',
            'C2C',
          ], field: HomeFilterField.model),
          HomeFilterGroup('City', [
            'Riyadh',
            'Jeddah',
            'Dammam',
            'Qassim',
          ], field: HomeFilterField.city),
          _sort,
        ];
    }
  }

  /// The groups as the sheet widget wants them.
  static List<AdvancedSearchGroup> sheetGroups(HomeContext ctx) => [
    for (final g in groups(ctx))
      AdvancedSearchGroup(title: g.title, options: g.options, single: g.single),
  ];

  /// Does [it] pass the selection and the search text? Within a group any
  /// option matches; across groups all must.
  static bool passes(
    HomeItem it,
    AdvancedSelection sel,
    List<HomeFilterGroup> groups,
    String query,
  ) {
    for (final g in groups) {
      final picked = sel[g.title] ?? const <String>{};
      if (picked.isEmpty || g.field == null || g.single) continue;
      final hit = picked.any((v) => _matches(it, g.field!, v));
      if (!hit) return false;
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final hay = '${it.name} ${it.tag} ${it.city} ${it.line}'.toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }

  static bool _matches(HomeItem it, HomeFilterField field, String v) {
    switch (field) {
      case HomeFilterField.sectors:
        return it.sectors.contains(v);
      case HomeFilterField.stage:
        return it.stage.contains(v.replaceAll('+', ''));
      case HomeFilterField.looking:
        return it.lookingFor.contains(v);
      case HomeFilterField.type:
        return it.programType == v;
      case HomeFilterField.city:
        return it.city == v;
      case HomeFilterField.model:
        return it.commerceModel == v;
    }
  }

  /// Applies "Sort by" (Name A-Z, or Newest = reversed).
  static List<HomeItem> sorted(List<HomeItem> list, AdvancedSelection sel) {
    final s = (sel['Sort by'] ?? const <String>{}).firstOrNull;
    if (s == 'Name A–Z') {
      return [...list]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    if (s == 'Newest') return list.reversed.toList();
    return list;
  }
}
