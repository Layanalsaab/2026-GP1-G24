import 'package:flutter/foundation.dart';

import '../../../data_access/repositories/activity_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/startup_activity.dart';

/// State of the Activity card in Manage startup -> Overview: the range
/// (Today / 7D / 30D / 12M, default 7D) and its figures. [activity] is null
/// for startups without analytics yet (the card shows its empty text).
class ActivityViewModel extends ChangeNotifier with SafeNotifier {
  ActivityViewModel({required this.startupId, ActivityRepository? repository})
    : _repository = repository ?? ActivityRepository.instance;

  final String startupId;
  final ActivityRepository _repository;

  ActivityRange range = ActivityRange.week;

  StartupActivity? get activity => _repository.activityFor(startupId, range);

  /// True when the startup has any analytics at all.
  bool get hasActivity =>
      _repository.activityFor(startupId, ActivityRange.week) != null;

  void select(ActivityRange value) {
    if (value == range) return;
    range = value;
    notifyListeners();
  }
}
