import 'package:flutter/foundation.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../app_constants/home_strings.dart';
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

/// "STATUS" group of the My Startups filter.
enum StatusFilter {
  all(FounderToolsStrings.optionAll),
  active(FounderToolsStrings.statusActive),
  closed(FounderToolsStrings.statusClosed);

  const StatusFilter(this.label);
  final String label;
}

/// "MY ROLE" group of the My Startups filter.
enum RoleFilter {
  all(FounderToolsStrings.optionAll),
  founder(FounderToolsStrings.roleFounder),
  coFounder(FounderToolsStrings.roleCoFounder),
  member(FounderToolsStrings.roleMember);

  const RoleFilter(this.label);
  final String label;
}

enum StartupSort {
  newest(HomeStrings.sortNewest),
  oldest(HomeStrings.sortOldest),
  name(HomeStrings.sortNameAZ),
  nameDesc(HomeStrings.sortNameZA);

  const StartupSort(this.label);
  final String label;
}

class MyStartupsViewModel extends ChangeNotifier with SafeNotifier {
  MyStartupsViewModel({
    StartupRepository? repository,
    List<MyStartupEntry>? teamStartups,
  }) : _repository = repository ?? StartupRepository.instance,
       teamStartups = [...(teamStartups ?? const <MyStartupEntry>[])];

  final StartupRepository _repository;

  /// Startups the user was added to as a team member (view only).
  final List<MyStartupEntry> teamStartups;

  Future<void> leave(String startupId, {bool alreadyLeft = false}) async {
    final entry = [
      ...teamStartups,
      ...memberStartups,
    ].where((e) => e.startup.id == startupId).firstOrNull;
    teamStartups.removeWhere((e) => e.startup.id == startupId);
    memberStartups = [
      for (final e in memberStartups)
        if (e.startup.id != startupId) e,
    ];
    _publishMemberIds();
    notifyListeners();
    if (entry != null &&
        !alreadyLeft &&
        !PrototypeSeed.isSampleStartup(startupId)) {
      try {
        await _repository.leave(entry.startup);
      } catch (_) {
        // Put it back: the membership was not removed.
        memberStartups = [...memberStartups, entry];
        error = FounderToolsStrings.saveFailed;
        notifyListeners();
      }
    }
  }

  void _publishMemberIds() {
    AppSession.instance.setMemberRoles({
      for (final e in [...memberStartups, ...teamStartups])
        e.startup.id: e.role,
    });
    AppSession.instance.setMemberStartupIds({
      for (final e in [...memberStartups, ...teamStartups]) e.startup.id,
    });
  }

  List<MyStartupEntry> memberStartups = const [];

  /// The founder's own startups (as loaded).
  List<Startup> startups = const [];

  VisibilityFilter visibility = VisibilityFilter.all;
  RoleFilter role = RoleFilter.all;
  StatusFilter status = StatusFilter.all;
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
        role: StartupRole.founder,
        addedAt: s.createdAt ?? DateTime.now(),
      ),
    ...memberStartups,
    ...teamStartups,
  ];

  /// The user's title in e (what its capsule says).
  StartupRole titleOf(MyStartupEntry e) =>
      StartupRole.titleOf(e.startup, AppSession.instance.user?.uid) ?? e.role;

  /// There is nothing at all (no own startup and no membership).
  bool get isEmpty => !isLoading && error == null && entries.isEmpty;

  /// Any filter other than the default is on.
  bool get filtered =>
      visibility != VisibilityFilter.all ||
      role != RoleFilter.all ||
      status != StatusFilter.all;

  String get filterLabel {
    final on = [
      if (visibility != VisibilityFilter.all) visibility.label,
      if (role != RoleFilter.all) role.label,
      if (status != StatusFilter.all) status.label,
    ];
    if (on.length > 1) return FounderToolsStrings.filtersCount(on.length);
    if (on.length == 1) return on.first;
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
      case StartupSort.nameDesc:
        list.sort(
          (a, b) => b.startup.name.toLowerCase().compareTo(
            a.startup.name.toLowerCase(),
          ),
        );
    }
    return [
      for (final e in list)
        if (!e.startup.isClosed) e,
      for (final e in list)
        if (e.startup.isClosed) e,
    ];
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
    switch (status) {
      case StatusFilter.all:
        break;
      case StatusFilter.active:
        if (e.startup.isClosed) return false;
      case StatusFilter.closed:
        if (!e.startup.isClosed) return false;
    }
    final title = titleOf(e);
    switch (role) {
      case RoleFilter.all:
        return true;
      case RoleFilter.founder:
        return title == StartupRole.founder;
      case RoleFilter.coFounder:
        return title == StartupRole.coFounder;
      case RoleFilter.member:
        return title == StartupRole.member;
    }
  }

  void setVisibility(VisibilityFilter value) {
    visibility = value;
    notifyListeners();
  }

  void setStatus(StatusFilter value) {
    status = value;
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
    status = StatusFilter.all;
    notifyListeners();
  }

  Future<void> _loadMemberStartups() async {
    final uid = AppSession.instance.user?.uid;
    try {
      final joined = await _repository.fetchMemberStartups();
      memberStartups = [
        for (final s in joined)
          MyStartupEntry(
            startup: s,
            role: s.memberRoles[uid] == 'coFounder'
                ? StartupRole.coFounder
                : StartupRole.member,
            addedAt: s.updatedAt ?? s.createdAt ?? DateTime.now(),
          ),
      ];
    } catch (_) {
      memberStartups = const [];
    }
  }

  /// Loads (or reloads) the list.
  Future<void> load() async {
    error = null;
    if (startups.isEmpty) isLoading = true;
    notifyListeners();
    try {
      startups = await _repository.fetchMyStartups();
      await _loadMemberStartups();
      AppSession.instance.setOwnStartupIds([for (final s in startups) s.id]);
      _publishMemberIds();
    } catch (_) {
      error = FounderToolsStrings.loadFailed;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
