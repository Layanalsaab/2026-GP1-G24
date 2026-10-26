import '../../../app_constants/app_strings.dart';
import '../../../models/home_item.dart';
import '../../../models/investor_criteria.dart';
import '../../../models/startup_enums.dart';
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
enum HomeFilterField {
  sectors,
  stage,
  looking,
  type,
  city,
  model,
  ticket,
  raising,
}

/// The advanced search groups, the filtering and the sorting of the home
/// pages. Pure so it is easy to test (docs/05 section B5).
class HomeFilters {
  HomeFilters._();

  /// The options are the same lists the forms use, so every stored value
  /// can be found.
  static final _sectors = [for (final v in Sector.values) v.label];
  static final _stages = [for (final v in StartupStage.picks) v.label];
  static final _cities = List<String>.of(AppStrings.allCities);
  static const _raising = [
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
        return [
          HomeFilterGroup('Sector', _sectors, field: HomeFilterField.sectors),
          HomeFilterGroup(
            'Stages they invest in',
            _stages,
            field: HomeFilterField.stage,
          ),
          HomeFilterGroup(
            'Ticket size',
            InvestorCriteria.ticketOptions,
            field: HomeFilterField.ticket,
          ),
          HomeFilterGroup('City', _cities, field: HomeFilterField.city),
          _sort,
        ];
      case HomeContext.explore:
        return [
          HomeFilterGroup('Sector', _sectors, field: HomeFilterField.sectors),
          HomeFilterGroup('Stage', _stages, field: HomeFilterField.stage),
          HomeFilterGroup('City', _cities, field: HomeFilterField.city),
          _sort,
        ];
      case HomeContext.startups:
        return [
          HomeFilterGroup('Sector', _sectors, field: HomeFilterField.sectors),
          HomeFilterGroup('Stage', _stages, field: HomeFilterField.stage),
          HomeFilterGroup('Looking for', [
            for (final v in LookingFor.values) v.label,
          ], field: HomeFilterField.looking),
          HomeFilterGroup('Raising', _raising, field: HomeFilterField.raising),
          HomeFilterGroup('Commerce model', [
            for (final v in BusinessModel.picks) v.shortLabel,
          ], field: HomeFilterField.model),
          HomeFilterGroup('City', _cities, field: HomeFilterField.city),
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
        return it.stages.contains(v);
      case HomeFilterField.ticket:
        return it.ticket == v;
      case HomeFilterField.raising:
        final r = it.raising;
        if (r == null || r <= 0) return false;
        return switch (v) {
          'Under SAR 250K' => r < 250000,
          'SAR 250K – 1M' => r >= 250000 && r < 1000000,
          'SAR 1M – 5M' => r >= 1000000 && r <= 5000000,
          'Over SAR 5M' => r > 5000000,
          _ => false,
        };
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

  /// Applies "Sort by": Name A-Z, or Newest (latest createdAt first; items
  /// with no date go last, in their old order).
  static List<HomeItem> sorted(List<HomeItem> list, AdvancedSelection sel) {
    final s = (sel['Sort by'] ?? const <String>{}).firstOrNull;
    if (s == 'Name A–Z') {
      return [...list]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    if (s == 'Newest') {
      // Nothing has a date (e.g. Support Channels): keep the old behaviour.
      if (list.every((it) => it.createdAt == null)) {
        return list.reversed.toList();
      }
      final order = {for (var i = 0; i < list.length; i++) list[i]: i};
      return [...list]..sort((a, b) {
        final da = a.createdAt, db = b.createdAt;
        if (da != null && db != null && da != db) return db.compareTo(da);
        if (da == null && db != null) return 1;
        if (da != null && db == null) return -1;
        return order[a]!.compareTo(order[b]!);
      });
    }
    return list;
  }
}
