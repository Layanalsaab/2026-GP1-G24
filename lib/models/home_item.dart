import '../helpers/size_bands.dart';
import 'investor_profile.dart';
import 'program.dart';
import 'startup.dart';
import 'startup_enums.dart';

/// What a Hub / Explore / Support Channels card shows.
enum HomeItemKind { startup, investor, program }

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
    this.matchPercent,
    this.matchReason,
    this.highlight,
    this.highlightReason,
    this.imageData,
    this.createdAt,
    this.closed = false,
  });

  final HomeItemKind kind;
  final String id;
  final String name;
  final String initials;

  final String tag;
  final String city;

  /// The body line: tagline, "about" or summary.
  final String line;

  final String stage;

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

  final List<String> partnerTypes;
  final List<String> supportTypes;

  final int? ticketLow;
  final int? ticketHigh;

  final int? matchPercent;
  final String? matchReason;

  final String? highlight;
  final String? highlightReason;

  /// The saved logo or photo (base64); null: the default picture.
  final String? imageData;

  /// When the startup / investor joined Start.sa (Explore -> Latest).
  final DateTime? createdAt;

  /// A closed startup (shown in the Hub only, with a Closed tag).
  final bool closed;

  /// s-{id}, i-{id}, p-{id}: the key a bookmark is stored under.
  String get bookmarkKey => switch (kind) {
    HomeItemKind.startup => 's-$id',
    HomeItemKind.investor => 'i-$id',
    HomeItemKind.program => 'p-$id',
  };

  HomeItem withMatch(int percent, String reason) =>
      _copy(matchPercent: percent, matchReason: reason);

  HomeItem withHighlight(String text, {String? reason}) =>
      _copy(highlight: text, highlightReason: reason);

  HomeItem _copy({
    int? matchPercent,
    String? matchReason,
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
    matchPercent: matchPercent ?? this.matchPercent,
    matchReason: matchReason ?? this.matchReason,
    highlight: highlight ?? this.highlight,
    highlightReason: highlightReason ?? this.highlightReason,
    imageData: imageData,
    createdAt: createdAt,
    closed: closed,
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
    sectors: [
      ...s.sectorLabels,
      if (s.sector == Sector.other ||
          s.otherSectors.any((o) => Sector.fromLabel(o) == null))
        'Other',
    ],
    lookingFor: [for (final l in s.lookingFor) s.lookingForLabelOf(l)],
    commerceModel: s.commerceModelLabel,
    partnerTypes: s.partnerTypes,
    supportTypes: s.supportTypes,
    imageData: s.logoData,
    createdAt: s.createdAt,
    closed: s.isClosed,
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
  );
}
