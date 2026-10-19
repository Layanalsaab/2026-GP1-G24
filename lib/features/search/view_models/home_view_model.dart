import 'package:flutter/material.dart';

import '../../../app_constants/home_strings.dart';
import '../../../data_access/repositories/discovery_repository.dart';
import '../../../data_access/repositories/interaction_repository.dart';
import '../../../data_access/repositories/matching_repository.dart';
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
    MatchingRepository? matching,
    Set<String> ownStartupIds = const {},
    List<Startup> ownStartups = const [],
  }) : _discovery = discovery ?? DiscoveryRepository.instance,
       _interactions = interactions ?? InteractionRepository.instance,
       _matching = matching ?? MatchingRepository.instance,
       _ownIds = ownStartupIds,
       _own = ownStartups;

  final SessionRole role;
  final AppUser? user;
  final DiscoveryRepository _discovery;
  final InteractionRepository _interactions;
  final MatchingRepository _matching;

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
  int _forYouSwitch = 1;
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

  // ---- Switches (defaults: guest -> Startups, others -> Investors) ----

  /// 0 = Startups, 1 = Investors.
  int get hubSwitch => _hubSwitch ?? (isGuest ? 0 : 1);
  int get resultsSwitch => _resultsSwitch ?? (isGuest ? 0 : 1);
  int get forYouSwitch => _forYouSwitch;
  int get trendingSwitch => _trendingSwitch ?? (isGuest ? 0 : 1);

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

  /// Matches come from Firestore (MatchingRepository), so they load in the
  /// background: [matches] starts the load the first time it is read for a
  /// startup / investor and the page rebuilds when the cards arrive.
  List<HomeItem> _matchItems = const [];
  String? _matchKey;
  bool matchesLoading = false;
  bool matchesFailed = false;

  /// What [matches] is for: the chosen startup (founder) or the investor.
  String? get _currentMatchKey {
    if (isFounder) {
      final s = matchStartup;
      return s == null ? null : 's-${s.id}-${s.updatedAt}';
    }
    final u = user;
    return isInvestor && u != null ? 'i-${u.uid}' : null;
  }

  /// Founder: investors matched to the chosen startup. Investor: startups
  /// matched to their criteria. Empty while [matchesLoading].
  List<HomeItem> get matches {
    final key = _currentMatchKey;
    if (key == null) return const [];
    if (key != _matchKey) _loadMatches(key);
    return _matchItems;
  }

  /// Pull-to-refresh / "Try again": reads the data again.
  Future<void> refreshMatches() async {
    final key = _currentMatchKey;
    if (key == null) return;
    final load = _loadMatches(key, refresh: true);
    notifyListeners(); // shows the loading state
    await load;
  }

  Future<void> _loadMatches(String key, {bool refresh = false}) async {
    // Called while building: change state now, notify only after the await.
    _matchKey = key;
    _matchItems = const [];
    matchesLoading = true;
    matchesFailed = false;
    final startup = isFounder ? matchStartup : null;
    final investor = user;
    List<HomeItem> items = const [];
    var failed = false;
    try {
      items = startup != null
          ? await _matching.investorsForStartup(startup, refresh: refresh)
          : await _matching.startupsForInvestor(investor!, refresh: refresh);
    } catch (e) {
      debugPrint('Matches failed to load: $e');
      failed = true;
    }
    if (_matchKey != key) return; // the choice changed meanwhile
    _matchItems = items;
    matchesFailed = failed;
    matchesLoading = false;
    notifyListeners();
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
    searchController.dispose();
    super.dispose();
  }
}
