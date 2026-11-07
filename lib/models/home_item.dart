import '../helpers/size_bands.dart';
import 'investor_profile.dart';
import 'program.dart';
import 'startup.dart';
import 'startup_enums.dart';

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
    this.stages = const [],
    this.ticket = '',
    this.raising,
    this.sectors = const [],
    this.lookingFor = const [],
    this.commerceModel = '',
    this.models = const [],
    this.partnerTypes = const [],
    this.supportTypes = const [],
    this.ticketLow,
    this.ticketHigh,
    this.programType,
    this.matchPercent,
    this.matchReason,
    this.joinedLabel,
    this.isNew = false,
    this.highlight,
    this.highlightReason,
    this.imageUrl,
    this.imageData,
    this.createdAt,
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

  /// Every stage the item has / invests in (matched one by one by the
  /// "Stage" filters).
  final List<String> stages;

  /// An investor's ticket size as stored ("SAR 100K – 500K").
  final String ticket;

  /// A startup's funding ask in SAR (null when none).
  final int? raising;

  final List<String> sectors;
  final List<String> lookingFor;

  /// "B2C" (startups only).
  final String commerceModel;

  /// The commerce models an investor invests in ("B2B", "B2C"...).
  final List<String> models;

  /// What a startup looks for in partners and in support (its stored lists).
  final List<String> partnerTypes;
  final List<String> supportTypes;

  /// An investor's usual ticket in SAR, read from [ticket] (null when it is
  /// not a range).
  final int? ticketLow;
  final int? ticketHigh;

  /// "Accelerator" / "Incubator" / "Startup studio" (programs only).
  final String? programType;
  final int? matchPercent;
  final String? matchReason;

  /// "Joined yesterday" on the "New on Start.sa" rail.
  final String? joinedLabel;
  final bool isNew;

  /// A line shown in the match pill's style instead of "N% match" (Latest:
  /// "Joined 2 days ago"; Trending: "#1 · +38%").
  final String? highlight;
  final String? highlightReason;

  /// The startup's logo or the person's photo (null: the default picture).
  final String? imageUrl;

  /// The saved logo (base64), shown before [imageUrl].
  final String? imageData;

  /// When the startup / investor joined Start.sa (for "Newest"). Null when
  /// unknown (programs, older documents).
  final DateTime? createdAt;

  /// `s-<id>`, `i-<id>`, `p-<id>`: the key a bookmark is stored under.
  String get bookmarkKey => switch (kind) {
    HomeItemKind.startup => 's-$id',
    HomeItemKind.investor => 'i-$id',
    HomeItemKind.program => 'p-$id',
  };

  HomeItem withMatch(int percent, String reason) =>
      _copy(matchPercent: percent, matchReason: reason);

  HomeItem withJoined(String label) => _copy(joinedLabel: label, isNew: true);

  /// A line under the body in the match pill's style: "Joined 2 days ago"
  /// (Latest) or "#1 · +38%" with its [reason] (Trending).
  HomeItem withHighlight(String text, {String? reason}) =>
      _copy(highlight: text, highlightReason: reason);

  HomeItem _copy({
    int? matchPercent,
    String? matchReason,
    String? joinedLabel,
    bool? isNew,
    String? highlight,
    String? highlightReason,
  }) => HomeItem(
    kind: kind,
    id: id,
    name: name,
    initials: initials,
    tag: tag,
    city: city,
    line: line,
    stage: stage,
    stages: stages,
    ticket: ticket,
    raising: raising,
    sectors: sectors,
    lookingFor: lookingFor,
    commerceModel: commerceModel,
    models: models,
    partnerTypes: partnerTypes,
    supportTypes: supportTypes,
    ticketLow: ticketLow,
    ticketHigh: ticketHigh,
    programType: programType,
    matchPercent: matchPercent ?? this.matchPercent,
    matchReason: matchReason ?? this.matchReason,
    joinedLabel: joinedLabel ?? this.joinedLabel,
    isNew: isNew ?? this.isNew,
    highlight: highlight ?? this.highlight,
    highlightReason: highlightReason ?? this.highlightReason,
    imageUrl: imageUrl,
    imageData: imageData,
    createdAt: createdAt,
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
    stages: [s.stageLabel, if (s.stage == StartupStage.other) 'Other'],
    raising: s.fundingRequirement,
    // Every sector, so the startup shows under each of them in the filters
    // and in search. (A typed "Other" sector also counts as "Other".)
    sectors: [
      ...s.sectorLabels,
      if (s.sector == Sector.other ||
          s.otherSectors.any((o) => Sector.fromLabel(o) == null))
        'Other',
    ],
    lookingFor: [for (final l in s.lookingFor) s.lookingForLabelOf(l)],
    commerceModel: s.businessModelLabel,
    partnerTypes: s.partnerTypes,
    supportTypes: s.supportTypes,
    imageUrl: s.logoUrl,
    imageData: s.logoData,
    createdAt: s.createdAt,
  );

  factory HomeItem.fromInvestor(InvestorProfile i) {
    final range = SizeBand.parseRange(i.ticketRange);
    return HomeItem(
      kind: HomeItemKind.investor,
      id: i.id,
      name: i.name,
      initials: i.initials,
      tag: i.sectors.isEmpty ? '' : i.sectors.first,
      city: i.city,
      line: i.about ?? i.profileBio,
      stage: i.stageRange,
      stages: i.stages,
      ticket: i.ticketRange,
      sectors: i.sectors,
      models: i.commerceModels,
      ticketLow: range?.low,
      ticketHigh: range?.high,
      matchPercent: i.matchPercent,
      matchReason: i.matchReason,
      joinedLabel: i.joinedLabel,
      imageUrl: i.photoUrl,
      createdAt: i.createdAt,
    );
  }

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
