import 'package:flutter/foundation.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/interest_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/startup.dart';

/// State of Manage startup (docs/05 D3): the startup as last saved, the
/// current tab, the visibility switch and the delete.
class ManageStartupViewModel extends ChangeNotifier with SafeNotifier {
  ManageStartupViewModel({required this.startup, StartupRepository? repository})
    : _repository = repository ?? StartupRepository.instance;

  final StartupRepository _repository;

  /// The startup as last saved.
  Startup startup;

  /// 0 Dashboard, 1 Details, 2 Rounds, 3 Requests, 4 Interest, 5 Settings.
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
      AppSession.instance.setOwnStartupIds([
        for (final id in AppSession.instance.ownStartupIds)
          if (id != startup.id) id,
      ]);
      return true;
    } catch (_) {
      error = FounderToolsStrings.deleteFailed;
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }
}
