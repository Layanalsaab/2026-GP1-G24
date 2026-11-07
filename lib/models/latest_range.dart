/// The time ranges of the Latest tab dropdown (Explore).
enum LatestRange {
  week('Last week', 7),
  months3('Last 3 months', 90),
  months6('Last 6 months', 180),
  year('Last year', 365);

  const LatestRange(this.label, this.days);

  /// The text in the dropdown.
  final String label;

  /// A startup that joined at most this many days ago is shown.
  final int days;
}
