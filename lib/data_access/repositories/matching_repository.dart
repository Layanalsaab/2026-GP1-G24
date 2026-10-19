import '../../app_constants/firestore_collections.dart';
import '../../models/app_user.dart';
import '../../models/home_item.dart';
import '../../models/investor_profile.dart';
import '../../models/startup.dart';
import '../../recommender/content_ranker.dart' as ranker;
import '../../recommender/knowledge_filter.dart';
import '../firebase_services/firestore_service.dart';

/// Explore -> Matches from the real Firestore data (lib/recommender has the
/// rules). Hub, For You and Trending keep the sample data for now.
///
/// - Investor: their answers (saved on `users/{uid}`, read through
///   [AppUser.investorCriteria]) against the public startups.
/// - Founder: the chosen startup against the `investors` collection.
///
/// The pools are kept for [_maxAge] so switching tabs does not read the
/// whole collection again (about 1,000 reads per load on the free plan);
/// pass `refresh: true` for pull-to-refresh.
///
/// Every method throws AuthException on failure (network, permission, ...),
/// like the other repositories.
class MatchingRepository {
  MatchingRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  /// The app-wide instance. Tests replace it with a fake.
  static MatchingRepository instance = MatchingRepository();

  static const _maxAge = Duration(minutes: 10);

  final FirestoreService _firestore;

  _Pool? _startups;
  _Pool? _investors;

  /// The startups and investors shown on Matches cards, so a tapped card
  /// opens the real profile (see navigation/open_item.dart).
  final Map<String, Startup> _shownStartups = {};
  final Map<String, InvestorProfile> _shownInvestors = {};

  Startup? startupById(String id) => _shownStartups[id];
  InvestorProfile? investorById(String id) => _shownInvestors[id];

  /// Startups matched to the signed-in [investor], best first. Empty until
  /// they have chosen sectors and stages.
  Future<List<HomeItem>> startupsForInvestor(
    AppUser investor, {
    bool raisingOnly = false,
    bool refresh = false,
  }) async {
    final criteria = investor.investorCriteria;
    if (criteria == null) return const [];
    final me = MatchInvestor.fromMap(investor.uid, {
      ...criteria.toFields(),
      UserFields.fullName: investor.fullName,
      UserFields.city: investor.city,
    });
    if (!me.interestsComplete) return const [];

    final docs = await _load(
      _startups,
      refresh,
      () => _firestore.queryWhereEqual(
        FirestoreCollections.startups,
        StartupFields.isPublic,
        true,
      ),
      (pool) => _startups = pool,
    );
    final startups = <String, Startup>{};
    final pool = <MatchStartup>[];
    for (final d in docs) {
      // A document the app can't show is never matched.
      final s = Startup.fromMap(d.id, d.data);
      if (s == null) continue;
      startups[d.id] = s;
      pool.add(MatchStartup.fromMap(d.id, d.data));
    }
    final byId = {for (final s in pool) s.id: s};
    return [
      for (final r in ranker.matchesForInvestor(
        me,
        pool,
        raisingOnly: raisingOnly,
      ))
        HomeItem.fromStartup(
          _shownStartups[r.id] = startups[r.id]!,
        ).withMatch(r.percent, ranker.shortReason(me, byId[r.id]!)),
    ];
  }

  /// Investors matched to the founder's [startup] (public or private), best
  /// first.
  Future<List<HomeItem>> investorsForStartup(
    Startup startup, {
    bool refresh = false,
  }) async {
    final docs = await _load(
      _investors,
      refresh,
      // Every investor profile has role "investor", so this reads them all
      // with the existing query method.
      () => _firestore.queryWhereEqual(
        FirestoreCollections.investors,
        UserFields.role,
        'investor',
      ),
      (pool) => _investors = pool,
    );
    // toMap() holds the stored values matching reads (sector, stage,
    // businessModel, location, lookingFor, fundingRequirement).
    final target = MatchStartup.fromMap(startup.id, startup.toMap());
    final investors = {
      for (final d in docs) d.id: MatchInvestor.fromMap(d.id, d.data),
    };
    final data = {for (final d in docs) d.id: d.data};
    return [
      for (final r in ranker.matchesForStartup(
        target,
        investors.values.toList(),
      ))
        HomeItem.fromInvestor(
          _shownInvestors[r.id] = _profile(r.id, data[r.id]!),
        ).withMatch(r.percent, ranker.shortReason(investors[r.id]!, target)),
    ];
  }

  /// Forgets the loaded pools (e.g. on sign-out).
  void clear() {
    _startups = null;
    _investors = null;
    _shownStartups.clear();
    _shownInvestors.clear();
  }

  Future<List<FirestoreDocument>> _load(
    _Pool? cached,
    bool refresh,
    Future<List<FirestoreDocument>> Function() read,
    void Function(_Pool) keep,
  ) async {
    if (!refresh &&
        cached != null &&
        DateTime.now().difference(cached.at) < _maxAge) {
      return cached.docs;
    }
    final docs = await read();
    keep(_Pool(docs, DateTime.now()));
    return docs;
  }

  /// Longest bio shown whole on a card.
  static const cardBioMax = 120;

  /// The bio on one card: whole when it is at most [cardBioMax] characters,
  /// otherwise cut at a word and ended with "…" (so a cut text always shows
  /// that there is more on the profile).
  static String cardPreview(String bio) {
    final flat = bio.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.length <= cardBioMax) return flat;
    var cut = flat.substring(0, cardBioMax);
    final space = cut.lastIndexOf(' ');
    if (space > cardBioMax ~/ 2) cut = cut.substring(0, space);
    return '${cut.replaceFirst(RegExp(r'[\s.,;:!?-]+$'), '')}…';
  }

  /// An `investors/{id}` document as the profile founders see.
  static InvestorProfile _profile(String id, Map<String, dynamic> d) {
    List<String> labels(Object? raw) => [
      if (raw is List)
        for (final v in raw)
          if (v is String && v != 'Other') v,
    ];
    String? text(String field) {
      final v = d[field];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    final city = text(UserFields.city) ?? '';
    final bio = text(UserFields.bio);
    return InvestorProfile(
      id: id,
      name: text(UserFields.fullName) ?? 'Investor',
      title: text(UserFields.title) ?? 'Investor',
      city: city,
      sectors: labels(d[UserFields.preferredSectors]),
      stages: labels(d[UserFields.preferredStages]),
      ticketRange: text(UserFields.ticketSize) ?? '',
      locations: [if (city.isNotEmpty) city],
      // The card shows the start of the bio; the profile page shows it all.
      about: bio == null ? null : cardPreview(bio),
      bio: bio,
      linkedin: text(UserFields.linkedin),
      valueOffered: text(UserFields.valueOffered),
      hopeToGain: text(UserFields.lookingFor),
    );
  }
}

class _Pool {
  const _Pool(this.docs, this.at);

  final List<FirestoreDocument> docs;
  final DateTime at;
}
