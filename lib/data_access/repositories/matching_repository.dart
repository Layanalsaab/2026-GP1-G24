import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/investment_ticket.dart';
import '../../models/investor_profile.dart';
import '../../models/startup.dart';
import '../../recommender/content_ranker.dart' as ranker;
import '../../recommender/knowledge_filter.dart';
import '../firebase_services/firestore_service.dart';

/// Matching from the real Firestore data (lib/recommender has the rules).
/// There is no Matches tab: matching lives in two places.
///
/// - Investor: each investment ticket of the Wallet against the listed
///   startups ([publicStartups], [matchesForTicket]). Only `startups` where
///   `isPublic == true` are read (the rules hide private ones anyway); the
///   closed ones (`status == 'closed'`) are dropped here.
/// - Founder: each open round of a startup against the `investors`
///   collection and the open `tickets` ([investorsForStartup]).
///
/// The pools stay up to date by themselves: the public startups, the
/// investors and the open tickets are watched with Firestore listeners,
/// which send the whole list once and then only the documents that change
/// (one read each). [changes] bumps after every change, so an open list is
/// computed again at once (no extra reads). With `live: false` (tests) the
/// pools are read once and kept for [_maxAge]; `refresh: true` reads them
/// again.
///
/// Every method throws AuthException on failure (network, permission, ...),
/// like the other repositories.
class MatchingRepository {
  MatchingRepository({FirestoreService? firestore, this.live = true})
    : _firestore = firestore ?? FirestoreService();

  /// Watch the pools with listeners (the app) or read them once (tests).
  final bool live;

  /// Bumps when a watched startup, investor or ticket changed (not on the
  /// first load). The Wallet and the round's Matches listen.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// How long the first answer of a listener may take.
  static const _firstAnswer = Duration(seconds: 15);

  /// The app-wide instance. Tests replace it with a fake.
  static MatchingRepository instance = MatchingRepository();

  static const _maxAge = Duration(minutes: 10);

  final FirestoreService _firestore;

  _Pool? _startups;
  _Pool? _investors;
  _Pool? _tickets;
  _LivePool? _liveStartups;
  _LivePool? _liveInvestors;
  _LivePool? _liveTickets;

  /// The startups and investors shown in matches, so a tapped card opens
  /// the real profile.
  final Map<String, Startup> _shownStartups = {};
  final Map<String, InvestorProfile> _shownInvestors = {};

  Startup? startupById(String id) => _shownStartups[id];
  InvestorProfile? investorById(String id) => _shownInvestors[id];

  /// Every listed startup: public (only those are read) and not closed. The
  /// pool a ticket is matched against.
  Future<List<Startup>> publicStartups({bool refresh = false}) async {
    final docs = await _pool(
      refresh,
      () => _liveStartups,
      (p) => _liveStartups = p,
      () => _startups,
      (p) => _startups = p,
      () => _firestore.watchWhereEqual(
        FirestoreCollections.startups,
        StartupFields.isPublic,
        true,
      ),
      () => _firestore.queryWhereEqual(
        FirestoreCollections.startups,
        StartupFields.isPublic,
        true,
      ),
    );
    final out = <Startup>[];
    for (final d in docs) {
      // A document the app can't show is never matched.
      final s = Startup.fromMap(d.id, d.data);
      if (s == null || !s.isListed) continue;
      _shownStartups[d.id] = s;
      out.add(s);
    }
    return out;
  }

  /// The matches of one [ticket] among [startups] (from [publicStartups]),
  /// best first. [commerceModels] are the investor's profile commerce models
  /// (labels), the 20% part of the score.
  static List<ranker.MatchResult> matchesForTicket(
    InvestmentTicket ticket,
    List<String> commerceModels,
    List<Startup> startups,
  ) {
    final models = MatchInvestor.fromMap(ticket.investorId, {
      UserFields.preferredCommerceModels: commerceModels,
    }).models;
    return ranker.matchesForTicket(matchTicketOf(ticket), models, [
      for (final s in startups) matchStartupOf(s),
    ]);
  }

  /// A [Startup] as matching reads it (its stored values).
  static MatchStartup matchStartupOf(Startup s) =>
      MatchStartup.fromMap(s.id, s.toMap());

  /// An [InvestmentTicket] as matching reads it.
  static MatchTicket matchTicketOf(InvestmentTicket t) => MatchTicket.fromMap(
    t.id,
    {
      ...t.editableFields(),
      TicketFields.investorId: t.investorId,
      TicketFields.status: t.status.value,
    },
  );

  /// The investors matched to the founder's [startup] (public or private)
  /// for its open round, best first: [startup] carries the round (stage =
  /// the round type, fundingRequirement = its amount, raisedInRound = what
  /// it raised). Investors with an open ticket that fits come first. A
  /// closed startup gets none. The profiles are kept for [investorById].
  Future<List<ranker.MatchResult>> investorsForStartup(
    Startup startup, {
    bool refresh = false,
  }) async {
    if (startup.isClosed) return const [];
    // Every investor profile has role "investor", so this reads them all.
    final docs = await _pool(
      refresh,
      () => _liveInvestors,
      (p) => _liveInvestors = p,
      () => _investors,
      (p) => _investors = p,
      () => _firestore.watchWhereEqual(
        FirestoreCollections.investors,
        UserFields.role,
        'investor',
      ),
      () => _firestore.queryWhereEqual(
        FirestoreCollections.investors,
        UserFields.role,
        'investor',
      ),
    );
    final ticketDocs = await _pool(
      refresh,
      () => _liveTickets,
      (p) => _liveTickets = p,
      () => _tickets,
      (p) => _tickets = p,
      () => _firestore.watchWhereEqual(
        FirestoreCollections.tickets,
        TicketFields.status,
        TicketFields.open,
      ),
      () => _firestore.queryWhereEqual(
        FirestoreCollections.tickets,
        TicketFields.status,
        TicketFields.open,
      ),
    );
    final data = {for (final d in docs) d.id: d.data};
    final results = ranker.matchesForStartup(
      matchStartupOf(startup),
      [for (final d in docs) MatchInvestor.fromMap(d.id, d.data)],
      tickets: [for (final d in ticketDocs) MatchTicket.fromMap(d.id, d.data)],
    );
    for (final r in results) {
      _shownInvestors[r.id] = _profile(r.id, data[r.id]!);
    }
    return results;
  }

  /// Forgets the loaded pools and stops the listeners (e.g. on sign-out).
  void clear() {
    _liveStartups?.cancel();
    _liveInvestors?.cancel();
    _liveTickets?.cancel();
    _liveStartups = null;
    _liveInvestors = null;
    _liveTickets = null;
    _startups = null;
    _investors = null;
    _tickets = null;
    _shownStartups.clear();
    _shownInvestors.clear();
  }

  /// One pool's documents: watched ([live]) or read once and cached.
  Future<List<FirestoreDocument>> _pool(
    bool refresh,
    _LivePool? Function() liveNow,
    void Function(_LivePool) keepLive,
    _Pool? Function() cachedNow,
    void Function(_Pool) keepCached,
    Stream<List<FirestoreDocument>> Function() watch,
    Future<List<FirestoreDocument>> Function() read,
  ) => live
      ? _watch(liveNow(), watch, keepLive)
      : _load(cachedNow(), refresh, read, keepCached);

  /// The latest documents of a watched pool; starts the listener the first
  /// time (or again after it failed) and waits for its first answer.
  Future<List<FirestoreDocument>> _watch(
    _LivePool? current,
    Stream<List<FirestoreDocument>> Function() watch,
    void Function(_LivePool) keep,
  ) async {
    var pool = current;
    if (pool == null || pool.failed) {
      pool?.cancel();
      pool = _LivePool(watch(), () => changes.value++);
      keep(pool);
    }
    try {
      await pool.ready.timeout(_firstAnswer);
    } catch (_) {
      pool.failed = true;
      pool.cancel();
      rethrow;
    }
    return pool.docs;
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

/// A pool kept up to date by a Firestore listener.
class _LivePool {
  _LivePool(Stream<List<FirestoreDocument>> stream, this._onChange) {
    _sub = stream.listen(
      (docs) {
        this.docs = docs;
        if (_ready.isCompleted) {
          _onChange();
        } else {
          _ready.complete();
        }
      },
      onError: (Object e) {
        failed = true;
        if (!_ready.isCompleted) _ready.completeError(e);
      },
    );
  }

  final VoidCallback _onChange;
  final Completer<void> _ready = Completer<void>();
  late final StreamSubscription<List<FirestoreDocument>> _sub;
  List<FirestoreDocument> docs = const [];
  bool failed = false;

  Future<void> get ready => _ready.future;

  void cancel() => _sub.cancel();
}
