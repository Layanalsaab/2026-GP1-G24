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

/// Everything the Hub, Explore and Support Channels pages browse, and the
/// lookups behind the startup, investor and program profiles.
///
/// The startups and investors come from Firestore: the public `startups`
/// documents and the `investors` documents, loaded by [refresh] and kept in
/// memory. Nothing is invented: until something is loaded the lists are empty.
/// A founder's own startups are hidden from the lists by the caller.
///
/// `DiscoveryRepository.sample()` serves the built-in sample people instead;
/// it exists only so tests have stable data.
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

  /// The app-wide instance. Tests replace it with a fake.
  static DiscoveryRepository instance = DiscoveryRepository();

  /// How many documents each list loads. The dataset has more than 150
  /// public startups, so 150 hid most of them. Cards still show 20 at a
  /// time ("Show more").
  static const startupLimit = 2000;
  static const investorLimit = 2000;
  static const ticketLimit = 3000;

  final FirestoreService? _firestore;
  final bool sample;

  List<Startup> _startups = [];
  List<InvestorProfile> _investors = [];
  List<InvestmentTicket> _tickets = [];

  /// The open investment tickets of [investorId] (what they want right now).
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
        // Signed-in people can read the tickets; for anyone else (or when it
        // fails) For You simply goes without them.
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

  /// The signed-in founder saved [startup] (edited, closed, made public or
  /// private): the loaded lists follow at once, without reading every
  /// startup again. A startup that is no longer public leaves them; one that
  /// became public joins them. Other people's changes still show at the next
  /// load (opening the app, pull to refresh).
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

  /// [startupId] was deleted: it leaves the loaded lists.
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

  /// The public startups: Explore and search ([includeClosed] false), or the
  /// Hub's Startups side ([includeClosed] true: a public closed startup is
  /// shown there, and only there, with its Closed tag). [excludeIds] hides
  /// the founder's own startups.
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

  /// Support Channels. There are none yet: the page says so instead of
  /// showing made-up programs.
  List<HomeItem> programs() => const [];

  /// "New on Start.sa" rail, Startups side (newest first).
  List<HomeItem> newStartups({Set<String> excludeIds = const {}}) {
    if (sample) {
      return [
        for (final id in const [
          'mock-sanabil',
          'mock-mizan',
          'mock-naql',
          'mock-daftar',
        ])
          if (!excludeIds.contains(id))
            HomeItem.fromStartup(_startups.firstWhere((s) => s.id == id))
                .withJoined(PrototypeSeed.joined[id] ?? 'Joined this week'),
      ];
    }
    final dated = [
      for (final s in _startups)
        if (s.isListed && s.createdAt != null && !excludeIds.contains(s.id)) s,
    ]..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return [
      for (final s in dated.take(4))
        HomeItem.fromStartup(s).withJoined(joinedLabel(s.createdAt!)),
    ];
  }

  /// Explore -> Latest: the public startups that joined at most [days] days
  /// ago, newest first, each with its "Joined 2 days ago" line. The founder's
  /// own startups ([excludeIds]) and private or closed ones are left out.
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

  /// "Joined today" / "Joined yesterday" / "Joined 3 days ago" / "Joined 2
  /// weeks ago" / "Joined 4 months ago" / "Joined over a year ago".
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

  /// "Joined today" / "Joined yesterday" / "Joined 3 days ago" / "Joined
  /// October 2026".
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

  /// For You, investor side: startups like the investor's criteria and their
  /// open tickets, pulled toward the startups they bookmarked ([bookmarks]:
  /// key -> when). A startup is left out when its amount is outside their
  /// onboarding amount, unless one of their open tickets takes it; a startup
  /// an open ticket takes (amount, sector, stage) ranks higher. With nothing
  /// to go on it is the first three.
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

  /// For You, founder side: each of the founder's startups ([own]) is its
  /// own taste, pulled toward the investors they bookmarked. An investor is
  /// scored against every startup whose amount their onboarding answers (or
  /// one of their open tickets) take, and ranked by the best of those; an
  /// open ticket that takes the startup's amount, sector and stage ranks the
  /// investor higher. When two investors tie, the one that fits more of the
  /// startups goes first. With no startup, only the bookmarks count.
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

  // ---- Profile lookups ----

  /// A loaded startup by id, or null (a founder's own startup is passed in
  /// directly).
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

  /// An investor's profile by id: the loaded one, else read from
  /// `investors/{id}`. Null when it doesn't exist or can't be read.
  Future<InvestorProfile?> loadInvestor(String id) async {
    final loaded = investorById(id);
    if (loaded != null) return loaded;
    final read = await _read(FirestoreCollections.investors, id);
    return InvestorProfile.fromMap(id, read.data);
  }

  /// The card for bookmark [key] (`s-<id>`, `i-<id>` or `p-<id>`).
  ///
  /// [item] is null when the card can't be shown. [deleted] is true only
  /// when the startup / investor / program doesn't exist anymore; a private
  /// startup or a failed read (offline) is not counted as deleted.
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

  /// Reads one document. [missing] is true only when Firestore says the
  /// document doesn't exist (not when the read is refused or offline).
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

  /// The founder's name for [startup]; null when it is not known (founders'
  /// accounts are private, so only the sample data has names).
  String? founderNameOf(Startup startup) =>
      sample ? PrototypeSeed.founderNames[startup.founderId] : null;

  /// The investors shown as "associated" on a startup: those whose request the
  /// founder accepted.
  List<InvestorProfile> associatedInvestors(String startupId) {
    final accepted = RequestRepository.instance.acceptedFor(startupId);
    final ids = accepted.isNotEmpty
        ? [for (final r in accepted) r.investorId]
        : (sample
              ? (PrototypeSeed.associations[startupId] ?? const <String>[])
              : const <String>[]);
    return [for (final id in ids) ?investorById(id)];
  }

  /// The startups an investor is associated with (investor profile ->
  /// "Investment associations").
  List<Startup> associationsOfInvestor(String investorId) => [
    for (final s in _startups)
      if (associatedInvestors(s.id).any((i) => i.id == investorId)) s,
  ];
}
