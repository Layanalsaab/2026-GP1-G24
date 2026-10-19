import 'investor_profile.dart';
import 'program.dart';
import 'startup.dart';

/// What a Hub / Explore / Support Channels card shows.
enum HomeItemKind { startup, investor, program }

/// One card of the home pages, built from a [Startup], an [InvestorProfile]
/// or a [Program] so the cards, search, filters and bookmarks work the same
/// for all three.
class HomeItem {
  const HomeItem({
    required this.kind,
    required this.id,
    required this.name,
    required this.initials,
    required this.tag,
    required this.city,
    required this.line,
    this.stage = '',
    this.sectors = const [],
    this.lookingFor = const [],
    this.commerceModel = '',
    this.programType,
    this.matchPercent,
    this.matchReason,
    this.joinedLabel,
    this.isNew = false,
  });

  final HomeItemKind kind;
  final String id;
  final String name;
  final String initials;

  /// The chip on the card: a startup's sector, an investor's first sector, a
  /// program's type.
  final String tag;
  final String city;

  /// The body line: tagline, "about" or summary.
  final String line;

  /// A startup's stage ("Pre-seed") or an investor's stage range
  /// ("Pre-seed – Seed").
  final String stage;
  final List<String> sectors;
  final List<String> lookingFor;

  /// "B2C" (startups only).
  final String commerceModel;

  /// "Accelerator" / "Incubator" / "Startup studio" (programs only).
  final String? programType;
  final int? matchPercent;
  final String? matchReason;

  /// "Joined yesterday" on the "New on Start.sa" rail.
  final String? joinedLabel;
  final bool isNew;

  /// `s-<id>`, `i-<id>`, `p-<id>`: the key a bookmark is stored under.
  String get bookmarkKey => switch (kind) {
    HomeItemKind.startup => 's-$id',
    HomeItemKind.investor => 'i-$id',
    HomeItemKind.program => 'p-$id',
  };

  HomeItem withMatch(int percent, String reason) => HomeItem(
    kind: kind,
    id: id,
    name: name,
    initials: initials,
    tag: tag,
    city: city,
    line: line,
    stage: stage,
    sectors: sectors,
    lookingFor: lookingFor,
    commerceModel: commerceModel,
    programType: programType,
    matchPercent: percent,
    matchReason: reason,
    joinedLabel: joinedLabel,
    isNew: isNew,
  );

  HomeItem withJoined(String label) => HomeItem(
    kind: kind,
    id: id,
    name: name,
    initials: initials,
    tag: tag,
    city: city,
    line: line,
    stage: stage,
    sectors: sectors,
    lookingFor: lookingFor,
    commerceModel: commerceModel,
    programType: programType,
    matchPercent: matchPercent,
    matchReason: matchReason,
    joinedLabel: label,
    isNew: true,
  );

  factory HomeItem.fromStartup(Startup s) => HomeItem(
    kind: HomeItemKind.startup,
    id: s.id,
    name: s.name,
    initials: s.initials,
    tag: s.sectorLabel,
    city: s.location.label,
    line: s.summary,
    stage: s.stageLabel,
    sectors: [s.sectorLabel],
    lookingFor: [for (final l in s.lookingFor) s.lookingForLabelOf(l)],
    commerceModel: s.businessModelLabel,
  );

  factory HomeItem.fromInvestor(InvestorProfile i) => HomeItem(
    kind: HomeItemKind.investor,
    id: i.id,
    name: i.name,
    initials: i.initials,
    tag: i.sectors.isEmpty ? '' : i.sectors.first,
    city: i.city,
    line: i.about ?? i.profileBio,
    stage: i.stageRange,
    sectors: i.sectors,
    matchPercent: i.matchPercent,
    matchReason: i.matchReason,
    joinedLabel: i.joinedLabel,
  );

  factory HomeItem.fromProgram(Program p) => HomeItem(
    kind: HomeItemKind.program,
    id: p.id,
    name: p.name,
    initials: p.initial,
    tag: p.type.label,
    city: p.city,
    line: p.cardSummary,
    sectors: p.focusSectors,
    programType: p.type.label,
  );
}
