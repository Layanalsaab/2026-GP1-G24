import 'package:flutter/material.dart';

import '../../../app_constants/home_strings.dart';
import '../../../data_access/repositories/discovery_repository.dart';
import '../../../data_access/repositories/interaction_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/app_user.dart';
import '../../../models/home_item.dart';
import '../../../models/latest_range.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/widgets/overlays/advanced_search_sheet.dart';
import 'home_filters.dart';

/// The three bottom navigation tabs, in bar order.
enum HomeTab { support, hub, explore }

/// A removable chip of the results row: a selected filter or the search text.
class HomeChip {
  const HomeChip({
    required this.label,
    required this.onRemove,
    this.isQuery = false,
  });

  final String label;
  final bool isQuery;
  final VoidCallback onRemove;
}

/// State and logic of the home shell (Support Channels, Hub, Explore): the
/// selected tab, the search text, the advanced search selection (remembered per
/// context), the Startups | Investors switches (one per place) and the
/// content lists. Presentational screens read it; the tests drive it directly.
class HomeViewModel extends ChangeNotifier with SafeNotifier {
  HomeViewModel({
    required this.role,
    this.user,
    DiscoveryRepository? discovery,
    InteractionRepository? interactions,
    Set<String> ownStartupIds = const {},
    List<Startup> ownStartups = const [],
  }) : _discovery = discovery ?? DiscoveryRepository.instance,
       _interactions = interactions ?? InteractionRepository.instance,
       _ownIds = ownStartupIds,
       _own = ownStartups {
    // The lists fill in when Firestore answers.
    _discovery.changes.addListener(notifyListeners);
  }

  /// Loads the public startups and investors (again).
  Future<void> refreshDirectory() => _discovery.refresh();

  bool get isLoadingDirectory => _discovery.isLoading;
  bool get directoryFailed => _discovery.loadFailed;

  final SessionRole role;

  /// The signed-in user. Replaced by [setUser] when they edit their profile
  /// (e.g. an investor's preferences).
  AppUser? user;

  void setUser(AppUser? value) {
    if (identical(value, user)) return;
    user = value;
    notifyListeners();
  }

  final DiscoveryRepository _discovery;
  final InteractionRepository _interactions;

  Set<String> _ownIds;
  List<Startup> _own;

  /// The search field's controller (owned here, disposed with the model).
  final TextEditingController searchController = TextEditingController();

  HomeTab tab = HomeTab.hub;
  int exploreTab = 0;
  String query = '';

  final Map<HomeContext, AdvancedSelection> _adv = {};

  int? _hubSwitch;
  int? _resultsSwitch;
  int? _trendingSwitch;

  TrendingRange range = TrendingRange.week;

  bool get isGuest => role == SessionRole.guest;
  bool get isFounder => role == SessionRole.founder;
  bool get isInvestor => role == SessionRole.investor;

  /// Founder's own startups (hidden from the lists).
  List<Startup> get ownStartups => _own;

  /// [alsoHide]: the startups the founder belongs to as a co-founder or team
  /// member (hidden from Hub and For You like their own).
  void setOwnStartups(
    List<Startup> startups, {
    Set<String> alsoHide = const {},
  }) {
    _own = startups;
    _ownIds = {for (final s in startups) s.id, ...alsoHide};
    notifyListeners();
  }

  // ---- Switches (a founder starts on Investors; investors and guests on
  // Startups) ----

  /// 0 = Startups, 1 = Investors.
  int get _defaultSwitch => isFounder ? 1 : 0;
  int get hubSwitch => _hubSwitch ?? _defaultSwitch;
  int get resultsSwitch => _resultsSwitch ?? _defaultSwitch;
  int get trendingSwitch => _trendingSwitch ?? _defaultSwitch;

  void setHubSwitch(int v) => _set(() => _hubSwitch = v);
  void setResultsSwitch(int v) => _set(() => _resultsSwitch = v);
  void setTrendingSwitch(int v) => _set(() => _trendingSwitch = v);

  void _set(VoidCallback f) {
    f();
    notifyListeners();
  }

  // ---- Tabs ----

  int get tabIndex => tab.index;

  /// Changing tab clears the search text; switches and filters stay.
  void selectTab(HomeTab value) {
    if (value == tab) return;
    tab = value;
    _clearQuery();
    notifyListeners();
  }

  /// Guests only have Trending (index 0 of their single tab).
  void selectExploreTab(int index) {
    if (index == exploreTab) return;
    exploreTab = index;
    notifyListeners();
  }

  /// 0 Latest, 1 Trending, 2 For You. Guests only have Trending, so they
  /// always see it.
  int get effectiveExploreTab {
    if (isGuest) return 1;
    return exploreTab.clamp(0, 2);
  }

  // ---- Search and advanced search ----

  HomeContext get context {
    switch (tab) {
      case HomeTab.support:
        return HomeContext.support;
      case HomeTab.explore:
        return HomeContext.explore;
      case HomeTab.hub:
        return hubSwitch == 1 ? HomeContext.investors : HomeContext.startups;
    }
  }

  List<HomeFilterGroup> get groups => HomeFilters.groups(context);

  AdvancedSelection get selection => _adv[context] ?? const {};

  /// Selected multi-choice options (the badge count).
  int get selectionCount =>
      advancedSelectionCount(HomeFilters.sheetGroups(context), selection);

  bool get filtering => selectionCount > 0 || query.trim().isNotEmpty;

  void setQuery(String value) {
    if (value == query) return;
    query = value;
    notifyListeners();
  }

  void _clearQuery() {
    query = '';
    searchController.clear();
  }

  void applySelection(AdvancedSelection value) {
    _adv[context] = {
      for (final e in value.entries)
        if (e.value.isNotEmpty) e.key: {...e.value},
      ..._keptSort(),
    };
    notifyListeners();
  }

  /// "Clear all": the filters of this context and the search text. The Hub's
  /// sort stays: it is not a filter.
  void clearAll() {
    _adv[context] = {..._keptSort()};
    _clearQuery();
    notifyListeners();
  }

  // ---- Sort (the Hub's sort button) ----

  /// The Hub has its own sort button, so its filter sheet has no "Sort by"
  /// group; the chosen sort is kept when the filters change.
  bool get hasSortButton => tab == HomeTab.hub;

  Map<String, Set<String>> _keptSort() {
    if (groups.any((g) => g.title == 'Sort by')) return const {};
    final sort = _adv[context]?['Sort by'];
    return sort == null || sort.isEmpty ? const {} : {'Sort by': sort};
  }

  /// "Newest", "Name A–Z" or null (the default order).
  String? get sortChoice =>
      (selection['Sort by'] ?? const <String>{}).firstOrNull;

  /// Chooses [value]; the same one again, or null, goes back to the default
  /// order.
  void setSort(String? value) {
    final cur = {...(_adv[context] ?? <String, Set<String>>{})};
    if (value == null || value == sortChoice) {
      cur.remove('Sort by');
    } else {
      cur['Sort by'] = {value};
    }
    _adv[context] = cur;
    notifyListeners();
  }

  /// "Other: SportsTech" when something was typed for Other.
  String _chipLabel(HomeFilterGroup g, String option) {
    if (option != 'Other') return option;
    final typed =
        (selection[advancedOtherKey(g.title)] ?? const <String>{}).firstOrNull;
    return typed == null ? option : 'Other: $typed';
  }

  void removeFilter(String group, String option) {
    final cur = {..._adv[context] ?? <String, Set<String>>{}};
    final set = {...cur[group] ?? <String>{}}..remove(option);
    cur[group] = set;
    if (option == 'Other') cur.remove(advancedOtherKey(group));
    _adv[context] = cur;
    notifyListeners();
  }

  void clearQuery() {
    _clearQuery();
    notifyListeners();
  }

  /// The chips of the results row: the search text first, then each selected
  /// option (single-choice groups such as "Sort by" show no chip).
  List<HomeChip> get chips => [
    if (query.trim().isNotEmpty)
      HomeChip(label: query.trim(), isQuery: true, onRemove: clearQuery),
    for (final g in groups)
      if (!g.single)
        for (final o in g.options)
          if ((selection[g.title] ?? const <String>{}).contains(o))
            HomeChip(
              label: _chipLabel(g, o),
              onRemove: () => removeFilter(g.title, o),
            ),
  ];

  /// How many items a draft selection gives (the sheet's apply label).
  int countFor(AdvancedSelection draft) {
    final ctx = context;
    final list = switch (ctx) {
      HomeContext.support => _programs,
      HomeContext.investors => _investors,
      HomeContext.explore => [..._startups, ..._investors],
      HomeContext.startups => _hubStartups,
    };
    final g = HomeFilters.groups(ctx);
    return list.where((it) => HomeFilters.passes(it, draft, g, '')).length;
  }

  // ---- Lists ----

  List<HomeItem> get _programs => _discovery.programs();
  List<HomeItem> get _investors => _discovery.investors();

  /// Every public startup that isn't closed, the user's own included
  /// (Explore and its search). Only For You ("New" and "Recommended") leaves
  /// the user's own out.
  List<HomeItem> get _startups => _discovery.startups();

  /// The Hub's Startups side: every public startup, closed ones included
  /// (with their Closed tag): the Hub is the full directory.
  List<HomeItem> get _hubStartups => _discovery.startups(includeClosed: true);

  List<HomeItem> _filtered(List<HomeItem> base) => HomeFilters.sorted([
    for (final it in base)
      if (HomeFilters.passes(it, selection, groups, query)) it,
  ], selection);

  /// The cards of the Support Channels page.
  List<HomeItem> get programCards => _filtered(_programs);

  /// There are no support channels at all yet (the page says so).
  bool get noSupportChannels => _programs.isEmpty;

  /// The cards of the Hub page (selected side).
  List<HomeItem> get hubCards =>
      _filtered(hubSwitch == 1 ? _investors : _hubStartups);

  /// The Explore results view (search or filters on any sub-tab).
  List<HomeItem> get exploreResults =>
      _filtered(resultsSwitch == 0 ? _startups : _investors);

  // ---- Latest ----

  /// How far back "Newest startups" goes (Last week by default).
  LatestRange latestRange = LatestRange.week;

  void setLatestRange(int index) =>
      _set(() => latestRange = LatestRange.values[index]);

  /// Explore -> Latest: the newest public startups in the chosen range. A
  /// founder's own startups and private ones are left out.
  List<HomeItem> get latest =>
      _discovery.latestStartups(days: latestRange.days, excludeIds: _ownIds);

  // ---- For You ----

  /// "Recommended startups for you" (investor) or "Recommended investors for
  /// you" (founder): one list, no switch.
  List<HomeItem> get recommended => isFounder
      ? _discovery.recommendedInvestors()
      : _discovery.recommendedStartups(excludeIds: _ownIds);

  /// The heading of For You and the text of its (i) button.
  String get recommendedTitle => isFounder
      ? HomeStrings.recommendedInvestors
      : HomeStrings.recommendedStartups;
  String get recommendedInfo => isFounder
      ? HomeStrings.forYouInfoFounder
      : HomeStrings.forYouInfoInvestor;

  // ---- Trending ----

  void setRange(int index) => _set(() => range = TrendingRange.values[index]);

  /// The top 30, each with its rank and growth ("#1 · +38%") and the reason
  /// ("more views than last week").
  List<HomeItem> get trending {
    final items = trendingSwitch == 0
        ? _interactions.trendingStartups(range)
        : _interactions.trendingInvestors(range);
    return [
      for (var i = 0; i < items.length; i++)
        items[i].withHighlight(
          '#${i + 1} · ${InteractionRepository.growthOf(i)}',
          reason: 'more views ${range.compare}',
        ),
    ];
  }

  // ---- Page identity (replays the card entrance when it changes) ----

  /// Changes whenever the visible list changes kind, so cards animate in again
  /// (prototype `panes` key).
  String get paneKey =>
      '${tab.name}-$effectiveExploreTab-${role.name}-${filtering ? 'f' : ''}'
      '-$hubSwitch-$resultsSwitch-$trendingSwitch-${latestRange.name}';

  String get title => switch (tab) {
    HomeTab.support => HomeStrings.supportTitle,
    HomeTab.hub => HomeStrings.hubTitle,
    HomeTab.explore => HomeStrings.exploreTitle,
  };

  @override
  void dispose() {
    _discovery.changes.removeListener(notifyListeners);
    searchController.dispose();
    super.dispose();
  }
}
