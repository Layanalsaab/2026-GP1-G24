import '../../models/home_item.dart';
import '../mock_data/prototype_seed.dart';

/// The ranges of the Trending range dropdown.
enum TrendingRange {
  today('Today', 'today'),
  week('Last 7 days', 'in the last 7 days'),
  month('Last 30 days', 'in the last 30 days'),
  year('This year', 'this year');

  const TrendingRange(this.label, this.noteText);

  /// The text in the dropdown.
  final String label;

  /// The tail of "Ranked by profile views ...".
  final String noteText;

  /// "Ranked by profile views in the last 7 days".
  String get note => 'Ranked by profile views $noteText';
}

/// Profile views and the Trending ranking (Explore -> Trending, top 30 per
/// side, ranked by profile views, no counts shown).
///
/// TODO(backend): record a view event per profile open and rank by the views
/// in the selected range (docs/08 section 5); until then the order is the
/// sample order, nudged by the views recorded in this session.
class InteractionRepository {
  InteractionRepository();

  /// The app-wide instance. Tests replace it with a fake.
  static InteractionRepository instance = InteractionRepository();

  static const topCount = 30;

  final Map<String, int> _views = {};

  /// Counts a profile open. [key] is `s-<id>` or `i-<id>`.
  void recordProfileView(String key) => _views[key] = (_views[key] ?? 0) + 1;

  List<HomeItem> _rank(List<HomeItem> items) {
    final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
    indexed.sort((a, b) {
      final byViews = (_views[b.$2.bookmarkKey] ?? 0).compareTo(
        _views[a.$2.bookmarkKey] ?? 0,
      );
      return byViews != 0 ? byViews : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed.take(topCount)) e.$2];
  }

  /// The top startups for [range] (the sample order for every range).
  List<HomeItem> trendingStartups(TrendingRange range) =>
      _rank([for (final s in PrototypeSeed.startups) HomeItem.fromStartup(s)]);

  /// The top investors for [range].
  List<HomeItem> trendingInvestors(TrendingRange range) => _rank([
    for (final i in PrototypeSeed.investors) HomeItem.fromInvestor(i),
  ]);
}
