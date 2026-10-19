/// The ranges of Manage startup -> Overview -> Activity.
enum ActivityRange {
  today('Today'),
  week('7D'),
  month('30D'),
  year('12M');

  const ActivityRange(this.label);

  /// The text on the segmented control.
  final String label;
}

/// One figure of the activity card: "128" with a "+18%" delta pill.
class ActivityFigure {
  const ActivityFigure(this.value, this.delta);

  final String value;
  final String delta;
}

/// Views, bookmarks and requests for one [ActivityRange], plus the chart
/// series and its axis labels (docs/07 §6).
class StartupActivity {
  const StartupActivity({
    required this.range,
    required this.views,
    required this.bookmarks,
    required this.requests,
    required this.series,
    required this.axis,
  });

  final ActivityRange range;
  final ActivityFigure views;
  final ActivityFigure bookmarks;
  final ActivityFigure requests;

  /// Chart points (any positive scale; the chart normalises them).
  final List<double> series;
  final List<String> axis;
}
