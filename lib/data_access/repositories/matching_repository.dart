import 'dart:async';

import 'package:flutter/foundation.dart';

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
/// The pools stay up to date by themselves: the public startups and the
/// investors are watched with Firestore listeners, which send the whole list
/// once and then only the documents that change (one read each). [changes]
/// bumps after every change, so an open Matches list is computed again at
/// once (no extra reads). With `live: false` (tests) the pools are read once
/// and kept for [_maxAge]; `refresh: true` reads them again.
///
/// Every method throws AuthException on failure (network, permission, ...),
/// like the other repositories.
class MatchingRepository {
  MatchingRepository({FirestoreService? firestore, this.live = true})
    : _firestore = firestore ?? FirestoreService();

  /// Watch the pools with listeners (the app) or read them once (tests).
  final bool live;

  /// Bumps when a watched startup or investor changed (not on the first
  /// load). HomeViewModel listens and computes its Matches again.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// How long the first answer of a listener may take.
  static const _firstAnswer = Duration(seconds: 15);

  /// The app-wide instance. Tests replace it with a fake.
  static MatchingRepository instance = MatchingRepository();

  static const _maxAge = Duration(minutes: 10);

  final FirestoreService _firestore;

  _Pool? _startups;
  _Pool? _investors;
  _LivePool? _liveStartups;
  _LivePool? _liveInvestors;

  /// The startups and investors shown on Matches cards, so a tapped card
  /// opens the real profile (see navigation/open_item.dart).
  final Map<String, Startup> _shownStartups = {};
  final Map<String, InvestorProfile> _shownInvestors = {};

  Startup? startupById(String id) => _shownStartups[id];
  InvestorProfile? investorById(String id) => _shownInvestors[id];

  /// Startups matched to the signed-in [investor], best first: only the
  /// ones raising now. Empty until they have chosen sectors and stages.
  Future<List<HomeItem>> startupsForInvestor(
    AppUser investor, {
    bool refresh = false,
  }) async {
    final criteria = investor.investorCriteria;
    if (criteria == null) return const [];
    final me = MatchInvestor.fromMap(investor.uid, {
      ...criteria.toFields(),
      UserFields.fullName: investor.fullName,
    });
    if (!me.interestsComplete) return const [];

    final docs = live
        ? await _watch(
            _liveStartups,
            () => _firestore.watchWhereEqual(
              FirestoreCollections.startups,
              StartupFields.isPublic,
              true,
            ),
            (pool) => _liveStartups = pool,
          )
        : await _load(
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
      for (final r in ranker.matchesForInvestor(me, pool))
        HomeItem.fromStartup(_shownStartups[r.id] = startups[r.id]!)
            .withMatch(r.percent, ranker.shortReason(me, byId[r.id]!)),
    ];
  }

  /// Investors matched to the founder's [startup] (public or private), best
  /// first.
  Future<List<HomeItem>> investorsForStartup(
    Startup startup, {
    bool refresh = false,
  }) async {
    // Every investor profile has role "investor", so this reads them all.
    final docs = live
        ? await _watch(
            _liveInvestors,
            () => _firestore.watchWhereEqual(
              FirestoreCollections.investors,
              UserFields.role,
              'investor',
            ),
            (pool) => _liveInvestors = pool,
          )
        : await _load(
            _investors,
            refresh,
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

  /// Forgets the loaded pools and stops the listeners (e.g. on sign-out).
  void clear() {
    _liveStartups?.cancel();
    _liveInvestors?.cancel();
    _liveStartups = null;
    _liveInvestors = null;
    _startups = null;
    _investors = null;
    _shownStartups.clear();
    _shownInvestors.clear();
  }

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
