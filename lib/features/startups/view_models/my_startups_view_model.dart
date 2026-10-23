import 'package:flutter/foundation.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/mock_data/prototype_seed.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/list_entries.dart';
import '../../../models/startup.dart';

/// "VISIBILITY" group of the My Startups filter.
enum VisibilityFilter {
  all(FounderToolsStrings.optionAll),
  public(FounderToolsStrings.optionPublic),
  private(FounderToolsStrings.optionPrivate);

  const VisibilityFilter(this.label);
  final String label;
}

/// "MY ROLE" group of the My Startups filter.
enum RoleFilter {
  all(FounderToolsStrings.optionAll),
  founder(FounderToolsStrings.roleFounder),
  member(FounderToolsStrings.roleMember);

  const RoleFilter(this.label);
  final String label;
}

enum StartupSort {
  newest('Newest first'),
  oldest('Oldest first'),
  name('Name (A–Z)');

  const StartupSort(this.label);
  final String label;
}

/// State of the My Startups list (docs/05 D1): loads the founder's startups
/// and publishes their ids to [AppSession] so Hub and Explore hide them.
///
/// The list shows the founder's own startups plus the startups they were
/// added to as a team member (view only). INTERFACE ONLY for the second
/// part: [teamStartups] defaults to the mockup list in
/// `PrototypeSeed.sampleTeamStartups`; the backend passes the real
/// memberships instead. Filtering and sorting happen here, in memory.
class MyStartupsViewModel extends ChangeNotifier with SafeNotifier {
  MyStartupsViewModel({
    StartupRepository? repository,
    List<MyStartupEntry>? teamStartups,
  }) : _repository = repository ?? StartupRepository.instance,
       teamStartups = teamStartups ?? PrototypeSeed.sampleTeamStartups;

  final StartupRepository _repository;

  /// Startups the user was added to as a team member (view only).
  final List<MyStartupEntry> teamStartups;

  /// The founder's own startups (as loaded).
  List<Startup> startups = const [];

  VisibilityFilter visibility = VisibilityFilter.all;
  RoleFilter role = RoleFilter.all;
  StartupSort sort = StartupSort.newest;

  /// True only until the first load finishes.
  bool isLoading = true;

  /// Set when the last load failed.
  String? error;

  /// Own startups first (as founder), then the team-member ones.
  List<MyStartupEntry> get entries => [
    for (final s in startups)
      MyStartupEntry(
        startup: s,
        isFounder: true,
        addedAt: s.createdAt ?? DateTime.now(),
      ),
    ...teamStartups,
  ];

  /// There is nothing at all (no own startup and no membership).
  bool get isEmpty => !isLoading && error == null && entries.isEmpty;

  /// Any filter other than the default is on.
  bool get filtered =>
      visibility != VisibilityFilter.all || role != RoleFilter.all;

  /// "All startups", the single active option ("Private", "Team member") or
  /// "2 filters".
  String get filterLabel {
    final v = visibility != VisibilityFilter.all;
    final r = role != RoleFilter.all;
    if (v && r) return FounderToolsStrings.filtersCount(2);
    if (v) return visibility.label;
    if (r) return role.label;
    return FounderToolsStrings.allStartups;
  }

  /// The entries after the filters and the sort.
  List<MyStartupEntry> get visible {
    final list = [
      for (final e in entries)
        if (_matches(e)) e,
    ];
    switch (sort) {
      case StartupSort.newest:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case StartupSort.oldest:
        list.sort((a, b) => a.addedAt.compareTo(b.addedAt));
      case StartupSort.name:
        list.sort(
          (a, b) => a.startup.name.toLowerCase().compareTo(
            b.startup.name.toLowerCase(),
          ),
        );
    }
    return list;
  }

  bool _matches(MyStartupEntry e) {
    switch (visibility) {
      case VisibilityFilter.all:
        break;
      case VisibilityFilter.public:
        if (!e.startup.isPublic) return false;
      case VisibilityFilter.private:
        if (e.startup.isPublic) return false;
    }
    switch (role) {
      case RoleFilter.all:
        return true;
      case RoleFilter.founder:
        return e.isFounder;
      case RoleFilter.member:
        return !e.isFounder;
    }
  }

  void setVisibility(VisibilityFilter value) {
    visibility = value;
    notifyListeners();
  }

  void setRole(RoleFilter value) {
    role = value;
    notifyListeners();
  }

  void setSort(StartupSort value) {
    sort = value;
    notifyListeners();
  }

  void resetFilters() {
    visibility = VisibilityFilter.all;
    role = RoleFilter.all;
    notifyListeners();
  }

  /// Loads (or reloads) the list. Never throws.
  Future<void> load() async {
    error = null;
    if (startups.isEmpty) isLoading = true;
    notifyListeners();
    try {
      startups = await _repository.fetchMyStartups();
      AppSession.instance.setOwnStartupIds([for (final s in startups) s.id]);
    } catch (_) {
      error = FounderToolsStrings.loadFailed;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
