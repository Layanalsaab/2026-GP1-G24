import 'package:flutter/foundation.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/startup.dart';

/// State of the My Startups list (docs/05 D1): loads the founder's startups
/// and publishes their ids to [AppSession] so Hub and Explore hide them.
class MyStartupsViewModel extends ChangeNotifier with SafeNotifier {
  MyStartupsViewModel({StartupRepository? repository})
    : _repository = repository ?? StartupRepository.instance;

  final StartupRepository _repository;

  List<Startup> startups = const [];

  /// True only until the first load finishes.
  bool isLoading = true;

  /// Set when the last load failed.
  String? error;

  bool get isEmpty => !isLoading && error == null && startups.isEmpty;

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
