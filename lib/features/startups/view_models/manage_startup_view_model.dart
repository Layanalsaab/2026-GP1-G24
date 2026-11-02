import 'package:flutter/foundation.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/mock_data/prototype_seed.dart';
import '../../../data_access/repositories/interest_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/connection_request.dart';
import '../../../models/startup.dart';

/// State of Manage startup (docs/05 D3): the startup as last saved, the
/// current tab, the visibility switch and the delete.
class ManageStartupViewModel extends ChangeNotifier with SafeNotifier {
  ManageStartupViewModel({required this.startup, StartupRepository? repository})
    : _repository = repository ?? StartupRepository.instance;

  final StartupRepository _repository;

  /// The startup as last saved.
  Startup startup;

  /// 0 Dashboard, 1 Details, 2 Rounds, 3 Interest, 4 Settings. (The requests
  /// of a round will live inside the round, not in a tab.)
  int tab = 0;

  bool isDeleting = false;
  bool isSavingVisibility = false;
  String? error;

  void selectTab(int index) {
    if (index == tab) return;
    tab = index;
    notifyListeners();
  }

  /// The startup was edited elsewhere.
  void replace(Startup updated) {
    startup = updated;
    notifyListeners();
  }

  /// Flips Public / Private and saves it. Returns the new value, or null
  /// when saving failed (the switch goes back).
  Future<bool?> setPublic(bool value) async {
    if (isSavingVisibility || value == startup.isPublic) return null;
    final before = startup;
    startup = startup.copyWith(isPublic: value);
    isSavingVisibility = true;
    error = null;
    notifyListeners();
    try {
      startup = await _repository.update(startup);
      return value;
    } catch (_) {
      startup = before;
      error = FounderToolsStrings.saveFailed;
      return null;
    } finally {
      isSavingVisibility = false;
      notifyListeners();
    }
  }

  /// Deletes the startup (and its logo). True on success.
  Future<bool> delete() async {
    if (isDeleting) return false;
    isDeleting = true;
    error = null;
    notifyListeners();
    try {
      await _repository.delete(startup);
      // Nothing of it is left behind: its requests and interest messages go
      // too. (Its funding rounds are deleted by the repository; other
      // people's bookmarks and the team memberships belong to the backend.)
      RequestRepository.instance.removeForStartup(startup.id);
      InterestRepository.instance.removeForStartup(startup.id);
      _forget(startup.id);
      return true;
    } catch (_) {
      error = FounderToolsStrings.deleteFailed;
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  /// A change (transfer, close, leave) is being saved.
  bool isBusy = false;

  /// The joined co-founders who can become the owner: (uid, name), in the
  /// order of the team list.
  List<(String, String)> get newOwnerChoices => [
    for (final uid in startup.coFoundersInTeamOrder)
      (uid, startup.nameOf(uid, fallback: FounderToolsStrings.roleCoFounder)),
  ];

  /// Gives the startup to the co-founder [uid]. True on success.
  Future<bool> transferTo(String uid) =>
      _run(FounderToolsStrings.transferFailed, () async {
        startup = await _repository.transferOwnership(startup, uid);
      });

  /// Closes the startup (its owner, with no co-founder on it): pending
  /// requests are declined too. True on success.
  Future<bool> close() => _run(FounderToolsStrings.closeFailed, () async {
    startup = await _repository.close(startup);
    final requests = RequestRepository.instance;
    for (final r in requests.inboxFor(startup.id)) {
      if (r.status == RequestStatus.pending) {
        requests.setStatus(r.id, RequestStatus.declined);
      }
    }
  });

  /// Opens the closed startup again (as Private). True on success.
  Future<bool> reopen() => _run(FounderToolsStrings.reopenFailed, () async {
    startup = await _repository.reopen(startup);
  });

  /// Leaves the startup. [keepFounderName]: the person who created it stays on
  /// its team as "Founder (former)". Sample startups (interface only) are
  /// left by the screen that listed them. True on success.
  Future<bool> leave({bool keepFounderName = false}) =>
      _run(FounderToolsStrings.leaveFailed, () async {
        if (!PrototypeSeed.isSampleStartup(startup.id)) {
          await _repository.leave(startup, keepFounderName: keepFounderName);
        }
        _forget(startup.id);
      });

  Future<bool> _run(String failed, Future<void> Function() action) async {
    if (isBusy) return false;
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (_) {
      error = failed;
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// The session stops listing [id] as one of my startups.
  void _forget(String id) {
    final session = AppSession.instance;
    session.setOwnStartupIds([
      for (final own in session.ownStartupIds)
        if (own != id) own,
    ]);
    session.setMemberStartupIds({
      for (final m in session.memberStartupIds)
        if (m != id) m,
    });
  }
}
