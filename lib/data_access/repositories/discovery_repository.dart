import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/home_item.dart';
import '../../models/investor_profile.dart';
import '../../models/program.dart';
import '../../models/startup.dart';
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
  DiscoveryRepository.sample()
    : _firestore = null,
      sample = true,
      _startups = List.of(PrototypeSeed.startups),
      _investors = List.of(PrototypeSeed.investors);

  /// The app-wide instance. Tests replace it with a fake.
  static DiscoveryRepository instance = DiscoveryRepository();

  /// How many documents each list loads (the lists render as plain columns,
  /// so they are capped).
  static const startupLimit = 150;
  static const investorLimit = 150;

  final FirestoreService? _firestore;
  final bool sample;

  List<Startup> _startups = [];
  List<InvestorProfile> _investors = [];

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
      ]);
      _startups = [for (final d in results[0]) ?Startup.fromMap(d.id, d.data)];
      _investors = [
        for (final d in results[1]) ?InvestorProfile.fromMap(d.id, d.data),
      ];
    } catch (e) {
      loadFailed = true;
      debugPrint('Loading the directory failed: $e');
    } finally {
      isLoading = false;
      changes.value++;
    }
  }

  /// Every loaded public startup / investor (for matching and ranking).
  List<Startup> get allStartups => List.unmodifiable(_startups);
  List<InvestorProfile> get allInvestors => List.unmodifiable(_investors);

  /// Hub, Startups side. [excludeIds] hides the founder's own startups.
  List<HomeItem> startups({Set<String> excludeIds = const {}}) => [
    for (final s in _startups)
      if (s.isPublic && !excludeIds.contains(s.id)) HomeItem.fromStartup(s),
  ];

  /// Hub, Investors side.
  List<HomeItem> investors() => [
    for (final i in _investors) HomeItem.fromInvestor(i),
  ];

  /// Support Channels (fixed reference content, not people).
  List<HomeItem> programs() => [
    for (final p in PrototypeSeed.programs) HomeItem.fromProgram(p),
  ];

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
        if (s.isPublic && s.createdAt != null && !excludeIds.contains(s.id)) s,
    ]..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return [
      for (final s in dated.take(4))
        HomeItem.fromStartup(s).withJoined(joinedLabel(s.createdAt!)),
    ];
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

  /// "Recommended for you": the first three of each side.
  List<HomeItem> recommendedStartups({Set<String> excludeIds = const {}}) =>
      startups(excludeIds: excludeIds).take(3).toList();

  List<HomeItem> recommendedInvestors() => investors().take(3).toList();

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
