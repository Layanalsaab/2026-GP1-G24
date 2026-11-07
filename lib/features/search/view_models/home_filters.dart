import '../../../app_constants/app_strings.dart';
import '../../../app_constants/founder_tools_strings.dart';
import '../../../helpers/size_bands.dart';
import '../../../models/home_item.dart';
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
    this.drop = false,
    this.otherHint,
  });

  final String title;
  final List<String> options;

  /// Which item field this group matches; null = display only (the sample
  /// data has no such field; it still counts in the badge and chips).
  final HomeFilterField? field;
  final bool single;

  /// Shown as a dropdown (a long list) instead of chips.
  final bool drop;

  /// A sector dropdown: "Other" shows a text box with this placeholder.
  final String? otherHint;
}

/// The item field a group filters on.
enum HomeFilterField {
  sectors,
  stage,
  looking,
  type,
  city,
  model,

  /// An investor's commerce models (several).
  models,
  ticket,
  raising,
  partner,
  support,
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
  static final _standardSectors = {for (final v in Sector.values) v.label};

  /// The placeholder of the "Other" text box of a sector dropdown.
  static const otherSectorHint = 'Type a sector, e.g. SportsTech';
  static const _commerce = ['B2B', 'B2C', 'B2G'];

  /// The "Looking for" choices of the Hub (a startup may look for more).
  static const _lookingFor = ['Funding', 'Partnership', 'Support'];
  static final _partnerTypes = [
    for (final o in FounderToolsStrings.partnerOptions)
      if (o != 'Other') o,
  ];
  static final _supportTypes = [
    for (final o in FounderToolsStrings.supportOptions)
      if (o != 'Other') o,
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
          HomeFilterGroup(
            'Sectors',
            _sectors,
            field: HomeFilterField.sectors,
            drop: true,
            otherHint: otherSectorHint,
          ),
          HomeFilterGroup('Stages', _stages, field: HomeFilterField.stage),
          HomeFilterGroup(
            'Commerce models',
            _commerce,
            field: HomeFilterField.models,
          ),
          HomeFilterGroup(
            'Investment size',
            SizeBand.labels,
            field: HomeFilterField.ticket,
          ),
          HomeFilterGroup(
            'City',
            _cities,
            field: HomeFilterField.city,
            drop: true,
          ),
        ];
      case HomeContext.explore:
        return [
          HomeFilterGroup(
            'Sector',
            _sectors,
            field: HomeFilterField.sectors,
            drop: true,
            otherHint: otherSectorHint,
          ),
          HomeFilterGroup('Stage', _stages, field: HomeFilterField.stage),
          HomeFilterGroup(
            'City',
            _cities,
            field: HomeFilterField.city,
            drop: true,
          ),
          _sort,
        ];
      case HomeContext.startups:
        return [
          HomeFilterGroup(
            'Sector',
            _sectors,
            field: HomeFilterField.sectors,
            drop: true,
            otherHint: otherSectorHint,
          ),
          HomeFilterGroup('Stage', _stages, field: HomeFilterField.stage),
          HomeFilterGroup(
            'Looking for',
            _lookingFor,
            field: HomeFilterField.looking,
          ),
          HomeFilterGroup(
            'Partner types',
            _partnerTypes,
            field: HomeFilterField.partner,
          ),
          HomeFilterGroup(
            'Support types',
            _supportTypes,
            field: HomeFilterField.support,
          ),
          HomeFilterGroup(
            'Raising',
            SizeBand.labels,
            field: HomeFilterField.raising,
          ),
          HomeFilterGroup(
            'Commerce model',
            _commerce,
            field: HomeFilterField.model,
          ),
          HomeFilterGroup(
            'Headquarters',
            _cities,
            field: HomeFilterField.city,
            drop: true,
          ),
        ];
    }
  }

  /// The groups as the sheet widget wants them.
  static List<AdvancedSearchGroup> sheetGroups(HomeContext ctx) => [
    for (final g in groups(ctx))
      AdvancedSearchGroup(
        title: g.title,
        options: g.options,
        single: g.single,
        drop: g.drop,
        otherHint: g.otherHint,
      ),
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
      final typed =
          (sel[advancedOtherKey(g.title)] ?? const <String>{}).firstOrNull ??
          '';
      final hit = picked.any((v) => _matches(it, g.field!, v, typed));
      if (!hit) return false;
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final hay = '${it.name} ${it.tag} ${it.city} ${it.line}'.toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }

  /// The sector filter's "Other": with text typed, an item whose own
  /// (non-standard) sector contains it; with none, every item that has a sector
  /// outside the standard list.
  static bool _matchesOtherSector(HomeItem it, String typed) {
    final own = [
      for (final s in it.sectors)
        if (s != 'Other' && !_standardSectors.contains(s)) s,
    ];
    final t = typed.trim().toLowerCase();
    if (t.isEmpty) return it.sectors.contains('Other') || own.isNotEmpty;
    return own.any((s) => s.toLowerCase().contains(t));
  }

  static bool _matches(
    HomeItem it,
    HomeFilterField field,
    String v,
    String typed,
  ) {
    switch (field) {
      case HomeFilterField.sectors:
        if (v == 'Other') return _matchesOtherSector(it, typed);
        return it.sectors.contains(v);
      case HomeFilterField.stage:
        return it.stages.contains(v);
      case HomeFilterField.ticket:
        // The investor's usual ticket overlaps the band.
        final lo = it.ticketLow, hi = it.ticketHigh;
        final band = SizeBand.of(v);
        if (lo == null || hi == null || band == null) return false;
        return band.overlaps(lo, hi);
      case HomeFilterField.raising:
        return SizeBand.of(v)?.containsAmount(it.raising) ?? false;
      case HomeFilterField.partner:
        return it.partnerTypes.contains(v);
      case HomeFilterField.support:
        return it.supportTypes.contains(v);
      case HomeFilterField.models:
        return it.models.contains(v);
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
