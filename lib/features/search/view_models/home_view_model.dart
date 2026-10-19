import 'package:flutter/material.dart';

import '../../../app_constants/home_strings.dart';
import '../../../data_access/repositories/discovery_repository.dart';
import '../../../data_access/repositories/interaction_repository.dart';
import '../../../data_access/repositories/recommendation_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/app_user.dart';
import '../../../models/home_item.dart';
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
    RecommendationRepository? recommendations,
    Set<String> ownStartupIds = const {},
    List<Startup> ownStartups = const [],
  }) : _discovery = discovery ?? DiscoveryRepository.instance,
       _interactions = interactions ?? InteractionRepository.instance,
       _recommendations = recommendations ?? RecommendationRepository.instance,
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
  final AppUser? user;
  final DiscoveryRepository _discovery;
  final InteractionRepository _interactions;
  final RecommendationRepository _recommendations;

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
  int? _forYouSwitch;
  int? _trendingSwitch;

  TrendingRange range = TrendingRange.week;
  bool showAllNew = false;
  int matchFor = 0;

  bool get isGuest => role == SessionRole.guest;
  bool get isFounder => role == SessionRole.founder;
  bool get isInvestor => role == SessionRole.investor;

  /// Founder's own startups (hidden from the lists; the "Matches for" menu).
  List<Startup> get ownStartups => _own;

  void setOwnStartups(List<Startup> startups) {
    _own = startups;
    _ownIds = {for (final s in startups) s.id};
    if (matchFor >= startups.length) matchFor = 0;
    notifyListeners();
  }

  // ---- Switches (a founder starts on Investors; investors and guests on
  // Startups) ----

  /// 0 = Startups, 1 = Investors.
  int get _defaultSwitch => isFounder ? 1 : 0;
  int get hubSwitch => _hubSwitch ?? _defaultSwitch;
  int get resultsSwitch => _resultsSwitch ?? _defaultSwitch;
  int get forYouSwitch => _forYouSwitch ?? _defaultSwitch;
  int get trendingSwitch => _trendingSwitch ?? _defaultSwitch;

  void setHubSwitch(int v) => _set(() => _hubSwitch = v);
  void setResultsSwitch(int v) => _set(() => _resultsSwitch = v);
  void setForYouSwitch(int v) => _set(() => _forYouSwitch = v);
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
    showAllNew = false;
    notifyListeners();
  }

  /// 0 For You, 1 Trending, 2 Matches (guests: always Trending).
  int get effectiveExploreTab => isGuest ? 1 : exploreTab;

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
    };
    notifyListeners();
  }

  /// "Clear all": the filters of this context and the search text.
  void clearAll() {
    _adv[context] = {};
    _clearQuery();
    notifyListeners();
  }

  void removeFilter(String group, String option) {
    final cur = {..._adv[context] ?? <String, Set<String>>{}};
    final set = {...cur[group] ?? <String>{}}..remove(option);
    cur[group] = set;
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
            HomeChip(label: o, onRemove: () => removeFilter(g.title, o)),
  ];

  /// How many items a draft selection gives (the sheet's apply label).
  int countFor(AdvancedSelection draft) {
    final ctx = context;
    final list = switch (ctx) {
      HomeContext.support => _programs,
      HomeContext.investors => _investors,
      HomeContext.explore => [..._startups, ..._investors],
      HomeContext.startups => _startups,
    };
    final g = HomeFilters.groups(ctx);
    return list.where((it) => HomeFilters.passes(it, draft, g, '')).length;
  }

  // ---- Lists ----

  List<HomeItem> get _programs => _discovery.programs();
  List<HomeItem> get _investors => _discovery.investors();
  List<HomeItem> get _startups => _discovery.startups(excludeIds: _ownIds);

  List<HomeItem> _filtered(List<HomeItem> base) => HomeFilters.sorted([
    for (final it in base)
      if (HomeFilters.passes(it, selection, groups, query)) it,
  ], selection);

  /// The cards of the Support Channels page.
  List<HomeItem> get programCards => _filtered(_programs);

  /// The cards of the Hub page (selected side).
  List<HomeItem> get hubCards =>
      _filtered(hubSwitch == 1 ? _investors : _startups);

  /// The Explore results view (search or filters on any sub-tab).
  List<HomeItem> get exploreResults =>
      _filtered(resultsSwitch == 0 ? _startups : _investors);

  /// "New on Start.sa" for the For You switch.
  List<HomeItem> get newItems => forYouSwitch == 0
      ? _discovery.newStartups(excludeIds: _ownIds)
      : _discovery.newInvestors();

  /// "Recommended for you": three cards of the selected side.
  List<HomeItem> get recommended => forYouSwitch == 0
      ? _discovery.recommendedStartups(excludeIds: _ownIds)
      : _discovery.recommendedInvestors();

  void setShowAllNew(bool v) => _set(() => showAllNew = v);

  // ---- Trending ----

  void setRange(int index) => _set(() => range = TrendingRange.values[index]);

  List<HomeItem> get trending => trendingSwitch == 0
      ? _interactions.trendingStartups(range)
      : _interactions.trendingInvestors(range);

  // ---- Matches ----

  void setMatchFor(int index) => _set(() => matchFor = index);

  Startup? get matchStartup =>
      _own.isEmpty ? null : _own[matchFor.clamp(0, _own.length - 1)];

  /// Founder: investors matched to the chosen startup. Investor: startups
  /// matched to their criteria.
  List<HomeItem> get matches {
    if (isFounder) {
      final s = matchStartup;
      return s == null ? const [] : _recommendations.investorsForStartup(s);
    }
    final u = user;
    return u == null ? const [] : _recommendations.startupsForInvestor(u);
  }

  // ---- Page identity (replays the card entrance when it changes) ----

  /// Changes whenever the visible list changes kind, so cards animate in again
  /// (prototype `panes` key).
  String get paneKey =>
      '${tab.name}-$effectiveExploreTab-${role.name}-${filtering ? 'f' : ''}'
      '-$hubSwitch-$resultsSwitch-$forYouSwitch-$trendingSwitch-$showAllNew';

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
