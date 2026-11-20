import 'package:flutter/foundation.dart';

import '../../../data_access/repositories/activity_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/startup_activity.dart';

class ActivityViewModel extends ChangeNotifier with SafeNotifier {
  ActivityViewModel({required this.startupId, ActivityRepository? repository})
    : _repository = repository ?? ActivityRepository.instance;

  final String startupId;
  final ActivityRepository _repository;

  ActivityRange range = ActivityRange.week;

  StartupActivity? get activity => _repository.activityFor(startupId, range);

  void select(ActivityRange value) {
    if (value == range) return;
    range = value;
    notifyListeners();
  }
}
