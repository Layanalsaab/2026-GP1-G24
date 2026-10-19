import '../../models/startup_activity.dart';
import '../mock_data/prototype_seed.dart';

/// Views, bookmarks and requests of a startup (Manage startup -> Overview ->
/// Activity).
///
/// Until analytics exist (docs/07 §Analytics) every startup returns null and
/// the screen shows "Views, bookmarks and requests will show here once people
/// discover your startup."
///
/// TODO(backend): aggregate profile-view events from `InteractionRepository`.
class ActivityRepository {
  ActivityRepository({this.sample = false});

  /// Tests: the sample startup "Rafeeq Health" has numbers.
  final bool sample;

  /// The app-wide instance. Tests replace it with a fake.
  static ActivityRepository instance = ActivityRepository();

  /// The activity of [startupId] for [range], or null when there is none yet.
  StartupActivity? activityFor(String startupId, ActivityRange range) {
    if (!sample || startupId != 'mock-rafeeq') return null;
    return PrototypeSeed.activity[range];
  }
}
