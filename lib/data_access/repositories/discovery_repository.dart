import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/home_item.dart';
import '../../models/investment_ticket.dart';
import '../../models/investor_criteria.dart';
import '../../models/investor_profile.dart';
import '../../models/program.dart';
import '../../models/startup.dart';
import '../../recommender/for_you.dart';
import '../../recommender/knowledge_filter.dart' show sectorValue;
import '../firebase_services/firestore_service.dart';
import '../mock_data/prototype_seed.dart';
import 'request_repository.dart';

class DiscoveryRepository {
  DiscoveryRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService(),
      sample = false;

  /// Tests: the sample startups and investors, no Firestore.
  DiscoveryRepository.sample({
    List<Startup>? startups,
    List<InvestorProfile>? investors,
    List<InvestmentTicket> tickets = const [],
  }) : _firestore = null,
       sample = true,
       _startups = List.of(startups ?? PrototypeSeed.startups),
       _investors = List.of(investors ?? PrototypeSeed.investors),
       _tickets = List.of(tickets);

  /// The app-wide instance.
  static DiscoveryRepository instance = DiscoveryRepository();

  /// How many documents each list loads.
  static const startupLimit = 2000;
  static const investorLimit = 2000;
  static const ticketLimit = 3000;

  final FirestoreService? _firestore;
  final bool sample;

  List<Startup> _startups = [];
  List<InvestorProfile> _investors = [];
  List<InvestmentTicket> _tickets = [];

  /// The open investment tickets of investorId (what they want right now).
  List<InvestmentTicket> openTicketsOf(String investorId) => [
    for (final t in _tickets)
      if (t.investorId == investorId && t.isOpen) t,
  ];

  /// Bumps whenever the lists were (re)loaded.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  bool isLoading = false;
  bool loadFailed = false;

  /// Loads the public startups and the investors from Firestore.
  Future<void> refresh() async {
    final db = _firestore;
    if (sample || db == null || isLoading) return;
    isLoading = true;
    loadFailed = false;
    changes.value++;
    try {
      final results = await Future.wait([
        db.queryWhereEqual(
          FirestoreCollections.startups,
          StartupFields.isPublic,
          true,
          limit: startupLimit,
        ),
        db.listCollection(FirestoreCollections.investors, limit: investorLimit),
        db
            .queryWhereEqual(
              FirestoreCollections.tickets,
              TicketFields.status,
              TicketFields.open,
              limit: ticketLimit,
            )
            .catchError((_) => <FirestoreDocument>[]),
      ]);
      _startups = [for (final d in results[0]) ?Startup.fromMap(d.id, d.data)];
      _investors = [
        for (final d in results[1]) ?InvestorProfile.fromMap(d.id, d.data),
      ];
      _tickets = [
        for (final d in results[2]) ?InvestmentTicket.fromMap(d.id, d.data),
      ];
    } catch (e) {
      loadFailed = true;
      debugPrint('Loading the directory failed: $e');
    } finally {
      isLoading = false;
      changes.value++;
    }
  }

  void apply(Startup startup) {
    final i = _startups.indexWhere((s) => s.id == startup.id);
    if (!startup.isPublic) {
      if (i < 0) return;
      _startups = [..._startups]..removeAt(i);
    } else if (i < 0) {
      _startups = [startup, ..._startups];
    } else {
      _startups = [..._startups]..[i] = startup;
    }
    changes.value++;
  }

  /// startupId was deleted: it leaves the loaded lists.
  void forget(String startupId) {
    final before = _startups.length;
    _startups = [
      for (final s in _startups)
        if (s.id != startupId) s,
    ];
    if (_startups.length != before) changes.value++;
  }

  /// Every loaded public startup / investor (for matching and ranking).
  List<Startup> get allStartups => List.unmodifiable(_startups);
  List<InvestorProfile> get allInvestors => List.unmodifiable(_investors);

  List<HomeItem> startups({
    Set<String> excludeIds = const {},
    bool includeClosed = false,
  }) => [
    for (final s in _startups)
      if ((includeClosed ? s.isInHub : s.isListed) &&
          !excludeIds.contains(s.id))
        HomeItem.fromStartup(s),
  ];

  /// Hub, Investors side.
  List<HomeItem> investors() => [
    for (final i in _investors) HomeItem.fromInvestor(i),
  ];

  /// Support Channels.
  List<HomeItem> programs() => const [];

  List<HomeItem> latestStartups({
    required int days,
    Set<String> excludeIds = const {},
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final dated = [
      for (final s in _startups)
        if (s.isListed &&
            s.createdAt != null &&
            !excludeIds.contains(s.id) &&
            _daysSince(s.createdAt!, today) <= days)
          s,
    ]..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return [
      for (final s in dated)
        HomeItem.fromStartup(s)
            .withHighlight(joinedAgo(s.createdAt!, now: today)),
    ];
  }

  static int _daysSince(DateTime created, DateTime today) => DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(created.year, created.month, created.day)).inDays;

  static String joinedAgo(DateTime created, {DateTime? now}) {
    final d = _daysSince(created, now ?? DateTime.now());
    if (d < 1) return 'Joined today';
    if (d < 2) return 'Joined yesterday';
    if (d < 7) return 'Joined $d days ago';
    if (d < 30) {
      final w = (d / 7).round();
      return 'Joined $w ${w == 1 ? 'week' : 'weeks'} ago';
    }
    if (d < 365) {
      final m = (d / 30).round();
      return 'Joined $m ${m == 1 ? 'month' : 'months'} ago';
    }
    return 'Joined over a year ago';
  }

  /// "New on Start.sa" rail, Investors side (newest first).
  List<HomeItem> newInvestors() {
    if (sample) {
      return [
        for (final id in const ['nora', 'omar', 'sara'])
          HomeItem.fromInvestor(_investors.firstWhere((i) => i.id == id))
              .withJoined(PrototypeSeed.joined[id] ?? 'Joined this week'),
      ];
    }
    final dated = [
      for (final i in _investors)
        if (i.createdAt != null) i,
    ]..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return [
      for (final i in dated.take(3))
        HomeItem.fromInvestor(i).withJoined(joinedLabel(i.createdAt!)),
    ];
  }

  static String joinedLabel(DateTime created, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final days = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime(created.year, created.month, created.day)).inDays;
    if (days <= 0) return 'Joined today';
    if (days == 1) return 'Joined yesterday';
    if (days < 7) return 'Joined $days days ago';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return 'Joined ${months[created.month - 1]} ${created.year}';
  }

  List<HomeItem> recommendedStartups({
    Set<String> excludeIds = const {},
    InvestorCriteria? criteria,
    String? investorId,
    Map<String, DateTime> bookmarks = const {},
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final tickets = investorId == null
        ? const <InvestmentTicket>[]
        : openTicketsOf(investorId);
    final taste = Taste.build(
      criteria == null ? Features.empty : criteriaFeatures(criteria),
      [
        for (final e in bookmarks.entries)
          if (e.key.startsWith('s-'))
            if (startupById(e.key.substring(2)) case final s?)
              Signal(startupFeatures(s), e.value),
        for (final t in tickets)
          Signal(
            ticketFeatures(t),
            t.createdAt ?? at,
            strength: ticketStrength,
          ),
      ],
      now: at,
    );
    final candidates = <Candidate<Startup>>[
      for (final s in _startups)
        if (s.isListed &&
            !excludeIds.contains(s.id) &&
            !bookmarks.containsKey('s-${s.id}') &&
            amountFits(
              s,
              tickets: tickets,
              ticketBand: criteria?.ticketBand,
              roundMin: criteria?.roundMin,
              roundMax: criteria?.roundMax,
            ))
          Candidate(s, s.name, startupFeatures(s), s.sector.value),
    ];
    final picks = recommendBest<Startup>(
      [taste],
      candidates,
      bonus: (c, _) => ticketBonus(c.item, tickets),
    );
    if (picks.isEmpty) return startups(excludeIds: excludeIds).take(3).toList();
    return [for (final p in picks) HomeItem.fromStartup(p.item)];
  }

  List<HomeItem> recommendedInvestors({
    List<Startup> own = const [],
    Map<String, DateTime> bookmarks = const {},
    DateTime? now,
  }) {
    final signals = [
      for (final e in bookmarks.entries)
        if (e.key.startsWith('i-'))
          if (investorById(e.key.substring(2)) case final i?)
            Signal(investorFeatures(i), e.value),
    ];
    final at = now ?? DateTime.now();
    final tastes = own.isEmpty
        ? [Taste.build(Features.empty, signals, now: at)]
        : [
            for (final s in own)
              Taste.build(startupFeatures(s), signals, now: at),
          ];
    final tickets = <String, List<InvestmentTicket>>{};
    for (final t in _tickets) {
      if (t.isOpen) (tickets[t.investorId] ??= []).add(t);
    }
    final candidates = <Candidate<InvestorProfile>>[
      for (final i in _investors)
        if (!bookmarks.containsKey('i-${i.id}'))
          Candidate(
            i,
            i.name,
            investorFeatures(i),
            i.sectors.isEmpty ? null : sectorValue[i.sectors.first],
          ),
    ];
    final picks = recommendBest<InvestorProfile>(
      tastes,
      candidates,
      allowed: own.isEmpty
          ? null
          : (c, t) => amountFits(
              own[t],
              tickets: tickets[c.item.id] ?? const [],
              ticketBand: c.item.ticketBand,
              roundMin: c.item.roundMin,
              roundMax: c.item.roundMax,
            ),
      bonus: own.isEmpty
          ? null
          : (c, t) => ticketBonus(own[t], tickets[c.item.id] ?? const []),
    );
    if (picks.isEmpty) return investors().take(3).toList();
    return [for (final p in picks) HomeItem.fromInvestor(p.item)];
  }

  Startup? startupById(String id) {
    for (final s in _startups) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// A loaded investor by id, or null.
  InvestorProfile? investorById(String id) {
    for (final i in _investors) {
      if (i.id == id) return i;
    }
    return sample && id == PrototypeSeed.layan.id ? PrototypeSeed.layan : null;
  }

  Future<InvestorProfile?> loadInvestor(String id) async {
    final loaded = investorById(id);
    if (loaded != null) return loaded;
    final read = await _read(FirestoreCollections.investors, id);
    return InvestorProfile.fromMap(id, read.data);
  }

  /// The card for bookmark key (s-{id}, i-{id} or p-{id}).
  Future<({HomeItem? item, bool deleted})> itemForBookmark(String key) async {
    final dash = key.indexOf('-');
    if (dash < 0) return (item: null, deleted: true);
    final id = key.substring(dash + 1);
    switch (key.substring(0, dash)) {
      case 's':
        final loaded = startupById(id);
        if (loaded != null) {
          return (item: HomeItem.fromStartup(loaded), deleted: false);
        }
        final read = await _read(FirestoreCollections.startups, id);
        final startup = Startup.fromMap(id, read.data);
        return (
          item: startup != null && startup.isPublic
              ? HomeItem.fromStartup(startup)
              : null,
          deleted: read.missing,
        );
      case 'i':
        final loaded = investorById(id);
        if (loaded != null) {
          return (item: HomeItem.fromInvestor(loaded), deleted: false);
        }
        final read = await _read(FirestoreCollections.investors, id);
        final investor = InvestorProfile.fromMap(id, read.data);
        return (
          item: investor == null ? null : HomeItem.fromInvestor(investor),
          deleted: read.missing,
        );
      case 'p':
        final program = programById(id);
        return (
          item: program == null ? null : HomeItem.fromProgram(program),
          deleted: program == null,
        );
    }
    return (item: null, deleted: true);
  }

  /// Reads one document.
  Future<({Map<String, dynamic>? data, bool missing})> _read(
    String collection,
    String id,
  ) async {
    final db = _firestore;
    if (sample || db == null) return (data: null, missing: false);
    try {
      final data = await db.getDocument(collection, id);
      return (data: data, missing: data == null);
    } catch (e) {
      debugPrint('Reading $collection/$id failed: $e');
      return (data: null, missing: false);
    }
  }

  Program? programById(String id) {
    for (final p in PrototypeSeed.programs) {
      if (p.id == id) return p;
    }
    return null;
  }

  String? founderNameOf(Startup startup) =>
      sample ? PrototypeSeed.founderNames[startup.founderId] : null;

  List<InvestorProfile> associatedInvestors(String startupId) {
    final accepted = RequestRepository.instance.acceptedFor(startupId);
    final ids = accepted.isNotEmpty
        ? [for (final r in accepted) r.investorId]
        : (sample
              ? (PrototypeSeed.associations[startupId] ?? const <String>[])
              : const <String>[]);
    return [for (final id in ids) ?investorById(id)];
  }

  List<Startup> associationsOfInvestor(String investorId) => [
    for (final s in _startups)
      if (associatedInvestors(s.id).any((i) => i.id == investorId)) s,
  ];
}
