import '../../models/home_item.dart';
import '../../models/investor_profile.dart';
import '../../models/program.dart';
import '../../models/startup.dart';
import '../mock_data/prototype_seed.dart';
import 'request_repository.dart';

/// Everything the Hub, Explore and Support Channels pages browse, and the
/// lookups behind the startup, investor and program profiles.
///
/// Discovery runs on the sample data in [PrototypeSeed] (there is no public
/// directory in Firestore yet). A founder's own startups come from
/// `StartupRepository` and are never listed here.
class DiscoveryRepository {
  DiscoveryRepository();

  /// The app-wide instance. Tests replace it with a fake.
  static DiscoveryRepository instance = DiscoveryRepository();

  /// Hub, Startups side. [excludeIds] hides the founder's own startups.
  List<HomeItem> startups({Set<String> excludeIds = const {}}) => [
    for (final s in PrototypeSeed.startups)
      if (s.isPublic && !excludeIds.contains(s.id)) HomeItem.fromStartup(s),
  ];

  /// Hub, Investors side.
  List<HomeItem> investors() => [
    for (final i in PrototypeSeed.investors) HomeItem.fromInvestor(i),
  ];

  /// Support Channels.
  List<HomeItem> programs() => [
    for (final p in PrototypeSeed.programs) HomeItem.fromProgram(p),
  ];

  /// "New on Start.sa" rail, Startups side (newest first).
  List<HomeItem> newStartups({Set<String> excludeIds = const {}}) => [
    for (final id in const [
      'mock-sanabil',
      'mock-mizan',
      'mock-naql',
      'mock-daftar',
    ])
      if (!excludeIds.contains(id))
        HomeItem.fromStartup(
          PrototypeSeed.startups.firstWhere((s) => s.id == id),
        ).withJoined(PrototypeSeed.joined[id] ?? 'Joined this week'),
  ];

  /// "New on Start.sa" rail, Investors side (newest first).
  List<HomeItem> newInvestors() => [
    for (final id in const ['nora', 'omar', 'sara'])
      HomeItem.fromInvestor(
        PrototypeSeed.investors.firstWhere((i) => i.id == id),
      ).withJoined(PrototypeSeed.joined[id] ?? 'Joined this week'),
  ];

  /// "Recommended for you": the first three of each side.
  List<HomeItem> recommendedStartups({Set<String> excludeIds = const {}}) =>
      startups(excludeIds: excludeIds).take(3).toList();

  List<HomeItem> recommendedInvestors() => investors().take(3).toList();

  // ---- Profile lookups (sample data) ----

  /// A sample startup by id, or null (a real startup is passed in directly).
  Startup? startupById(String id) {
    for (final s in PrototypeSeed.startups) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// A sample investor by id (including the demo investor), or null.
  InvestorProfile? investorById(String id) {
    for (final i in PrototypeSeed.investors) {
      if (i.id == id) return i;
    }
    return id == PrototypeSeed.layan.id ? PrototypeSeed.layan : null;
  }

  Program? programById(String id) {
    for (final p in PrototypeSeed.programs) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// The sample founder's name for [startup]; null for a real startup.
  String? founderNameOf(Startup startup) =>
      PrototypeSeed.founderNames[startup.founderId];

  /// The investors shown as "associated" on a startup: those whose request the
  /// founder accepted, otherwise its approved sample associations.
  List<InvestorProfile> associatedInvestors(String startupId) {
    final accepted = RequestRepository.instance.acceptedFor(startupId);
    final ids = accepted.isNotEmpty
        ? [for (final r in accepted) r.investorId]
        : (PrototypeSeed.associations[startupId] ?? const <String>[]);
    return [for (final id in ids) ?investorById(id)];
  }

  /// The sample startups an investor is associated with (investor profile ->
  /// "Investment associations").
  List<Startup> associationsOfInvestor(String investorId) => [
    for (final s in PrototypeSeed.startups)
      if (associatedInvestors(s.id).any((i) => i.id == investorId)) s,
  ];
}
