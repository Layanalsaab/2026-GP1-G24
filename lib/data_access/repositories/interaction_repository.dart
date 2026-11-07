import '../../models/home_item.dart';
import 'discovery_repository.dart';

/// The ranges of the Trending range dropdown.
enum TrendingRange {
  today('Today', 'today', 'than yesterday'),
  week('Last 7 days', 'in the last 7 days', 'than last week'),
  month('Last 30 days', 'in the last 30 days', 'than last month'),
  year('This year', 'this year', 'than last year');

  const TrendingRange(this.label, this.noteText, this.compare);

  /// The text in the dropdown.
  final String label;

  /// The tail of "Ranked by profile views ...".
  final String noteText;

  /// "more views [compare]" on a Trending card ("than last week").
  final String compare;

  /// "Ranked by profile views in the last 7 days".
  String get note => 'Ranked by profile views $noteText';

  /// The text of the (i) button next to "Top 30 trending".
  String get info =>
      'Based on profile views $noteText. The more a profile’s views grew '
      'compared with the previous period, the higher it ranks.';
}

/// Profile views and the Trending ranking (Explore -> Trending, top 30 per
/// side, ranked by profile views, no counts shown).
///
/// TODO(backend): record a view event per profile open and rank by the views
/// in the selected range (docs/08 section 5); until then the order is the
/// loaded order, nudged by the views recorded in this session.
class InteractionRepository {
  InteractionRepository({DiscoveryRepository? discovery})
    // ignore: prefer_initializing_formals
    : _discovery = discovery;

  final DiscoveryRepository? _discovery;
  DiscoveryRepository get _d => _discovery ?? DiscoveryRepository.instance;

  /// The app-wide instance. Tests replace it with a fake.
  static InteractionRepository instance = InteractionRepository();

  static const topCount = 30;

  final Map<String, int> _views = {};

  /// PLACEHOLDER growth numbers for the Trending cards ("#1 · +38%") until
  /// profile views are recorded and compared with the previous period.
  static const _growth = [
    '+38%',
    '+24%',
    '+19%',
    '+12%',
    '+9%',
    '+31%',
    '+7%',
    '+16%',
    '+22%',
    '+11%',
    '+5%',
    '+27%',
    '+14%',
    '+8%',
    '+18%',
  ];

  /// The growth shown for rank [index] (0 is #1).
  static String growthOf(int index) => _growth[index % _growth.length];


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
  List<HomeItem> trendingStartups(TrendingRange range) => _rank([
    // A private or closed startup is never trending.
    for (final s in _d.allStartups)
      if (s.isListed) HomeItem.fromStartup(s),
  ]);

  /// The top investors for [range].
  List<HomeItem> trendingInvestors(TrendingRange range) =>
      _rank([for (final i in _d.allInvestors) HomeItem.fromInvestor(i)]);
}
