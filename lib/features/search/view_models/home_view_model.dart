import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app_constants/home_strings.dart';
import '../../../data_access/remote/for_you_api.dart';
import '../../../data_access/repositories/bookmark_repository.dart';
import '../../../data_access/repositories/discovery_repository.dart';
import '../../../data_access/repositories/for_you_cache.dart';
import '../../../data_access/repositories/not_interested_repository.dart';
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

class HomeViewModel extends ChangeNotifier with SafeNotifier {
  HomeViewModel({
    required this.role,
    this.user,
    DiscoveryRepository? discovery,
    Set<String> ownStartupIds = const {},
    List<Startup> ownStartups = const [],
    ForYouSource? forYou,
    ForYouCache? forYouCache,
    NotInterestedRepository? notInterested,
    Duration forYouQuietTime = const Duration(seconds: 2),
  }) : _discovery = discovery ?? DiscoveryRepository.instance,
       _ownIds = ownStartupIds,
       _own = ownStartups,
       _server = forYou ?? ForYouApi.instance,
       _cache = forYouCache ?? ForYouCache.instance,
       _notInterested = notInterested ?? NotInterestedRepository.instance,
       _quietTime = forYouQuietTime {
    // The lists fill in when Firestore answers.
    _discovery.changes.addListener(_onDiscovery);
    _seenBookmarks = {..._bookmarks.keys.value};
    _bookmarks.keys.addListener(_onBookmarks);
    _seenNotInterested = {..._notInterested.keys.value};
    _notInterested.keys.addListener(_onNotInterested);
    _server.profileTextDone.addListener(_onProfileTextDone);
    _startForYou();
  }

  final BookmarkRepository _bookmarks = BookmarkRepository.instance;

  void _onDiscovery() {
    _forYou = null;
    notifyListeners();
  }

  /// Loads the public startups and investors (again), and asks the For You
  /// server again.
  Future<void> refreshDirectory() {
    _forYou = null;
    unawaited(refreshForYou());
    return _discovery.refresh();
  }

  bool get isLoadingDirectory => _discovery.isLoading;
  bool get directoryFailed => _discovery.loadFailed;

  final SessionRole role;

  /// The signed-in user.
  AppUser? user;

  /// A new user starts For You over. The same user (an edited or just
  /// reloaded profile) only redraws: the server is asked again once an edit's
  /// profile text has been rebuilt (see [_onProfileTextDone]).
  void setUser(AppUser? value) {
    if (identical(value, user)) return;
    final newUid = value?.uid != user?.uid;
    user = value;
    _forYou = null;
    if (newUid) _startForYou();
    notifyListeners();
  }

  final DiscoveryRepository _discovery;

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
  int? _latestSwitch;

  bool get isGuest => role == SessionRole.guest;
  bool get isFounder => role == SessionRole.founder;
  bool get isInvestor => role == SessionRole.investor;

  /// Founder's own startups (hidden from the lists).
  List<Startup> get ownStartups => _own;

  void setOwnStartups(
    List<Startup> startups, {
    Set<String> alsoHide = const {},
  }) {
    _own = startups;
    _ownIds = {for (final s in startups) s.id, ...alsoHide};
    _forYou = null;
    notifyListeners();
  }

  /// 0 = Startups, 1 = Investors.
  int get _defaultSwitch => isFounder ? 1 : 0;
  int get hubSwitch => _hubSwitch ?? _defaultSwitch;
  int get resultsSwitch => _resultsSwitch ?? _defaultSwitch;
  int get latestSwitch => _latestSwitch ?? _defaultSwitch;

  void setHubSwitch(int v) => _set(() => _hubSwitch = v);
  void setResultsSwitch(int v) => _set(() => _resultsSwitch = v);
  void setLatestSwitch(int v) => _set(() => _latestSwitch = v);

  void _set(VoidCallback f) {
    f();
    notifyListeners();
  }

  int get tabIndex => tab.index;

  /// Changing tab clears the search text; switches and filters stay.
  void selectTab(HomeTab value) {
    if (value == tab) return;
    tab = value;
    _forYou = null;
    _clearQuery();
    notifyListeners();
  }

  /// Guests only have Trending.
  void selectExploreTab(int index) {
    if (index == exploreTab) return;
    exploreTab = index;
    _forYou = null;
    notifyListeners();
  }

  /// 0 Latest, 1 Trending, 2 For You.
  int get effectiveExploreTab {
    if (isGuest) return 1;
    return exploreTab.clamp(0, 2);
  }

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

  /// "Clear all": the filters of this context and the search text.
  void clearAll() {
    _adv[context] = {..._keptSort()};
    _clearQuery();
    notifyListeners();
  }

  Map<String, Set<String>> _keptSort() {
    final sort = _adv[context]?['Sort by'];
    return sort == null || sort.isEmpty ? const {} : {'Sort by': sort};
  }

  /// "Newest", "Name A–Z" or null (the default order).
  String? get sortChoice =>
      (selection['Sort by'] ?? const <String>{}).firstOrNull;

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

  List<HomeItem> get _programs => _discovery.programs();
  List<HomeItem> get _investors => _discovery.investors();

  List<HomeItem> get _startups => _discovery.startups();

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

  LatestRange latestRange = LatestRange.months6;

  void setLatestRange(int index) =>
      _set(() => latestRange = LatestRange.values[index]);

  List<HomeItem> get latest => latestSwitch == 0
      ? _discovery.latestStartups(days: latestRange.days)
      : _discovery.latestInvestors(days: latestRange.days);

  /// For You: the server's list from this session, else the list saved on the
  /// phone, else the app's own ranking; never bookmarked, "Not interested" or
  /// unloaded items.
  List<HomeItem> get recommended => _forYou ??= _buildForYou();

  /// The visible For You list (worked out again when set to null).
  List<HomeItem>? _forYou;

  /// The user looks at For You (where cards must not jump).
  bool get _onForYou =>
      tab == HomeTab.explore && effectiveExploreTab == 2 && !filtering;

  List<HomeItem> _buildForYou() {
    // A server answer kept aside while For You was open shows now.
    if (_waitingKeys != null) {
      _serverKeys = _waitingKeys;
      _waitingKeys = null;
    }
    final keys = _serverKeys ?? _savedKeys;
    if (keys != null) {
      final marks = _bookmarks.keys.value;
      final items = [
        for (final k in keys)
          if (!marks.contains(k) && !_notInterested.contains(k)) ?_itemOf(k),
      ];
      if (items.isNotEmpty) return items;
    }
    // No list, or nothing in it to show: the app's own ranking.
    return [
      for (final it in _computeForYou())
        if (!_notInterested.contains(it.bookmarkKey)) it,
    ];
  }

  /// The card of a server key, or null when the app has not loaded it (or it
  /// is closed or the founder's own).
  HomeItem? _itemOf(String key) {
    final id = BookmarkRepository.targetIdOf(key);
    if (key.startsWith('s-')) {
      final s = _discovery.startupById(id);
      if (s == null || !s.isListed || _ownIds.contains(id)) return null;
      return HomeItem.fromStartup(s);
    }
    if (key.startsWith('i-')) {
      final i = _discovery.investorById(id);
      return i == null ? null : HomeItem.fromInvestor(i);
    }
    return null;
  }

  List<HomeItem> _computeForYou() {
    final saved = {
      for (final k in _bookmarks.keys.value)
        k: _bookmarks.savedAt(k) ?? DateTime.now(),
    };
    final hidden = {
      for (final k in _notInterested.keys.value)
        k: _notInterested.savedAt(k) ?? DateTime.now(),
    };
    return isFounder
        ? _discovery.recommendedInvestors(
            own: _own,
            bookmarks: saved,
            notInterested: hidden,
          )
        : _discovery.recommendedStartups(
            excludeIds: _ownIds,
            criteria: user?.investorCriteria,
            investorId: user?.uid,
            bookmarks: saved,
            notInterested: hidden,
          );
  }

  Set<String> _seenBookmarks = {};
  Set<String> _seenNotInterested = {};

  void _onBookmarks() {
    final now = _bookmarks.keys.value;
    _onTasteChanged(_seenBookmarks, now);
    _seenBookmarks = {...now};
  }

  void _onNotInterested() {
    final now = _notInterested.keys.value;
    _onTasteChanged(_seenNotInterested, now);
    _seenNotInterested = {...now};
  }

  /// A bookmark or "Not interested" change. While the user is on For You one
  /// change leaves the cards where they are (the bookmarked card stays; a
  /// hidden one was already taken out by [hideForYou]); a bulk change (load,
  /// sign-out) or a change made elsewhere redraws the list. One change also
  /// asks the server again once things have been quiet for a while.
  void _onTasteChanged(Set<String> before, Set<String> now) {
    final added = now.difference(before).length;
    final removed = before.difference(now).length;
    // A reload that found the same keys (a new but equal set): nothing to do.
    if (added == 0 && removed == 0) return;
    final bulk = added > 1 || removed > 1;
    if (bulk || !_onForYou) {
      _forYou = null;
      if (bulk) notifyListeners();
    }
    if (!bulk) _askWhenQuiet();
  }

  // For You from the server, the saved list and the fallback.

  final ForYouSource _server;
  final ForYouCache _cache;
  final NotInterestedRepository _notInterested;
  final Duration _quietTime;

  /// The server's list for this user in this session (keys like `s-<id>`).
  List<String>? _serverKeys;

  /// A newer server answer kept aside while For You is open.
  List<String>? _waitingKeys;

  /// The list saved on the phone for this user.
  List<String>? _savedKeys;

  /// Where each hidden card was, for Undo.
  final Map<String, int> _hiddenAt = {};

  Future<void>? _request;
  bool _askAgain = false;
  bool _answerAtOnce = false;

  /// The answer of the request asked again (after the running one) shows at
  /// once.
  bool _againAtOnce = false;
  Timer? _quietTimer;
  bool _closed = false;

  /// Signed in and a server address is set (otherwise the Dart list only).
  bool get _serverOn => !_closed && user?.uid != null && _server.enabled;

  /// A new user (or the first one): forget the last one's lists, show this
  /// one's saved list and ask the server.
  void _startForYou() {
    _serverKeys = null;
    _waitingKeys = null;
    _savedKeys = null;
    _hiddenAt.clear();
    _quietTimer?.cancel();
    _quietTimer = null;
    _answerAtOnce = false;
    _againAtOnce = false;
    if (!_serverOn) return;
    unawaited(_readSaved(user!.uid));
    // A request still running is for the last user: ask again after it.
    unawaited(_ask(atOnce: true, again: true));
  }

  Future<void> _readSaved(String uid) async {
    final keys = await _cache.read(uid);
    if (_closed || uid != user?.uid) return;
    _savedKeys = keys;
    if (_serverKeys == null && _waitingKeys == null && keys.isNotEmpty) {
      _forYou = null;
      notifyListeners();
    }
  }

  /// Asks the server for a new list; its answer shows at once. A request
  /// already running is joined (the server reads Firestore itself, so a
  /// directory reload changes nothing it sees). A profile edit is not asked
  /// for here: a same-user [setUser] sends nothing, and the server is asked
  /// again when the edit's profile text is rebuilt ([_onProfileTextDone]).
  Future<void> refreshForYou() => _ask(atOnce: true, again: false);

  /// A `/profile-text` call finished (a profile was edited on another
  /// screen): ask again now, or once the running request is done. The answer
  /// shows at once (nothing jumps under the user's finger: the edit happened
  /// elsewhere).
  void _onProfileTextDone() => unawaited(_ask(atOnce: true, again: true));

  void _askWhenQuiet() {
    if (!_serverOn) return;
    _quietTimer?.cancel();
    _quietTimer = Timer(_quietTime, () {
      _quietTimer = null;
      unawaited(_ask(atOnce: false, again: true));
    });
  }

  /// One request at a time. During one, a call with again asks once more when
  /// it is done; any other call just waits for it. atOnce: the answer of the
  /// request this call is served by (the one asked again, or the running one
  /// it joined) shows at once, even while For You is open.
  Future<void> _ask({required bool atOnce, required bool again}) {
    if (!_serverOn) return Future.value();
    final running = _request;
    if (running != null) {
      if (again) {
        _askAgain = true;
        if (atOnce) _againAtOnce = true;
      } else if (atOnce) {
        _answerAtOnce = true;
      }
      return running;
    }
    if (atOnce) _answerAtOnce = true;
    return _request = _askUntilDone();
  }

  Future<void> _askUntilDone() async {
    try {
      do {
        _askAgain = false;
        await _askOnce();
        if (_againAtOnce) {
          _againAtOnce = false;
          _answerAtOnce = true;
        }
      } while (_askAgain && !_closed);
    } finally {
      _request = null;
    }
  }

  Future<void> _askOnce() async {
    final uid = user?.uid;
    if (uid == null || !_serverOn) return;
    final picks = await _server.forYou();
    // Closed, or another user signed in meanwhile: dropped.
    if (_closed || uid != user?.uid) return;
    final atOnce = _answerAtOnce;
    _answerAtOnce = false;
    if (picks == null) return; // No answer: the list shown stays.
    final keys = [for (final p in picks) p.key];
    unawaited(_cache.write(uid, keys));
    if (!atOnce && _onForYou) {
      _waitingKeys = keys;
      return;
    }
    _serverKeys = keys;
    _waitingKeys = null;
    _forYou = null;
    notifyListeners();
  }

  /// "Not interested" (the card's ✕): the card leaves For You at once.
  void hideForYou(HomeItem item) {
    final key = item.bookmarkKey;
    final list = [...recommended];
    final at = list.indexWhere((it) => it.bookmarkKey == key);
    if (at >= 0) {
      list.removeAt(at);
      _hiddenAt[key] = at;
    }
    _forYou = list;
    notifyListeners();
    unawaited(_notInterested.add(key));
  }

  /// Undo of [hideForYou]: the card comes back where it was.
  void undoHideForYou(HomeItem item) {
    final key = item.bookmarkKey;
    final list = [
      for (final it in recommended)
        if (it.bookmarkKey != key) it,
    ];
    final at = (_hiddenAt.remove(key) ?? 0).clamp(0, list.length);
    list.insert(at, item);
    _forYou = list;
    notifyListeners();
    unawaited(_notInterested.remove(key));
  }

  /// The heading of For You and the text of its (i) button.
  String get recommendedTitle => isFounder
      ? HomeStrings.recommendedInvestors
      : HomeStrings.recommendedStartups;
  String get recommendedInfo => isFounder
      ? HomeStrings.forYouInfoFounder
      : HomeStrings.forYouInfoInvestor;

  String get paneKey =>
      '${tab.name}-$effectiveExploreTab-${role.name}-${filtering ? 'f' : ''}'
      '-$hubSwitch-$resultsSwitch-$latestSwitch'
      '-${latestRange.name}';

  String get title => switch (tab) {
    HomeTab.support => HomeStrings.supportTitle,
    HomeTab.hub => HomeStrings.hubTitle,
    HomeTab.explore => HomeStrings.exploreTitle,
  };

  @override
  void dispose() {
    _closed = true;
    _quietTimer?.cancel();
    _discovery.changes.removeListener(_onDiscovery);
    _bookmarks.keys.removeListener(_onBookmarks);
    _notInterested.keys.removeListener(_onNotInterested);
    _server.profileTextDone.removeListener(_onProfileTextDone);
    searchController.dispose();
    super.dispose();
  }
}
