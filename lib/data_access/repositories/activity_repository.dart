import '../../models/startup_activity.dart';
import '../mock_data/prototype_seed.dart';

/// Views, bookmarks and requests of a startup (Manage startup -> Overview ->
/// Activity).
///
/// Until analytics exist (docs/07 §Analytics), only the sample startup
/// "Rafeeq Health" has numbers; every real startup returns null and the
/// screen shows "Views, bookmarks and requests will show here once people
/// discover your startup."
///
/// TODO(backend): aggregate profile-view events from `InteractionRepository`.
class ActivityRepository {
  ActivityRepository();

  /// The app-wide instance. Tests replace it with a fake.
  static ActivityRepository instance = ActivityRepository();

  /// The activity of [startupId] for [range], or null when there is none yet.
  StartupActivity? activityFor(String startupId, ActivityRange range) {
    if (startupId != 'mock-rafeeq') return null;
    return PrototypeSeed.activity[range];
  }
}
