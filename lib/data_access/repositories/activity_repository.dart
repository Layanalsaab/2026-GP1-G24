import '../../models/startup_activity.dart';
import '../mock_data/prototype_seed.dart';

/// Views, bookmarks and requests of a startup (Manage startup -> Overview -> Activity).
class ActivityRepository {
  ActivityRepository({this.sample = false});

  /// Tests: the sample startup "Rafeeq Health" has numbers.
  final bool sample;

  /// The app-wide instance.
  static ActivityRepository instance = ActivityRepository();

  /// The activity of startupId for range, or null when there is none yet.
  StartupActivity? activityFor(String startupId, ActivityRange range) {
    if (!sample || startupId != 'mock-rafeeq') return null;
    return PrototypeSeed.activity[range];
  }
}
