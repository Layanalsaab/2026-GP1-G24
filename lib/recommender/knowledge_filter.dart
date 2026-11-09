/// Matching, part 1: reading the documents and the hard filters
/// (knowledge-based). Part 2, the score, the order and the explanation, is
/// content_ranker.dart.
///
/// Matching lives in two places (there is no Matches tab):
/// - inside each investment ticket of the Wallet (the investor), and
/// - inside each open funding round of a startup (the founder).
///
/// Works on the Firestore documents as stored (field names agreed on
/// 19 Oct 2026, see firestore-field-names-v1.md):
/// - `startups/{id}`: stored values ('fintech', 'seed', 'b2b').
/// - `investors/{id}` (and the investor's own `users/{uid}`): labels
///   ('Fintech', 'Seed', 'SAR 100K – 500K').
/// - `tickets/{investorId}-T{n}`: labels ('Fintech', 'Seed') and SAR amounts.
///
/// A startup never matches when it is private (`isPublic` is not true),
/// closed (`status` is 'closed') or not raising (Funding unticked, or nothing
/// left to raise in its round).
///
/// The Python reference is matching_v2.py; test/recommender/matching_test.dart
/// checks that both give the same results.
library;

import '../helpers/other_check.dart';

/// Investor sector label -> the startups' stored value (the 25 sectors).
const Map<String, String> sectorValue = {
  'HealthTech': 'healthtech',
  'Fintech': 'fintech',
  'EdTech': 'edtech',
  'E-commerce': 'ecommerce',
  'Logistics': 'logistics',
  'AgriTech': 'agritech',
  'PropTech': 'proptech',
  'CleanTech': 'cleantech',
  'Tourism': 'tourism',
  'SaaS': 'saas',
  'AI': 'ai',
  'Cybersecurity': 'cybersecurity',
  'Gaming': 'gaming',
  'Media': 'media',
  'FoodTech': 'foodtech',
  'Mobility': 'mobility',
  'Retail': 'retail',
  'Energy': 'energy',
  'InsurTech': 'insurtech',
  'LegalTech': 'legaltech',
  'HR Tech': 'hr_tech',
  'Biotech': 'biotech',
  'Manufacturing': 'manufacturing',
  'Sports': 'sports',
  'Other': 'other',
};

/// Investor stage label -> the startups' stored value.
const Map<String, String> stageValue = {
  'Pre-seed': 'pre_seed',
  'Seed': 'seed',
  'Series A': 'series_a',
  'Series B': 'series_b',
  'Series C': 'series_c',
  'Other': 'other',
};

/// Investor commerce-model label -> the startups' stored `businessModel`.
const Map<String, String> modelValue = {
  'Business-to-Government (B2G)': 'b2g',
  'Business-to-Business (B2B)': 'b2b',
  'Business-to-Business-to-Consumer (B2B2C)': 'b2b2c',
  'Direct-to-Consumer (D2C)': 'd2c',
  'Business-to-Consumer (B2C)': 'b2c',
  'Consumer-to-Consumer (C2C)': 'c2c',
  'Business-to-Employee (B2E)': 'b2e',
  'Consumer-to-Business (C2B)': 'c2b',
  'Government-to-Citizen (G2C)': 'g2c',
  'Government-to-Government (G2G)': 'g2g',
  'Other': 'other',
};

/// "How much do you usually invest in one startup?" -> the band's minimum
/// in SAR. Null (Other, or no answer) means the ticket is not checked.
const Map<String, int?> ticketMin = {
  'Under SAR 100K': 0,
  'SAR 100K – 500K': 100000,
  'SAR 500K – 1M': 500000,
  'SAR 1M – 5M': 1000000,
  'Over SAR 5M': 5000000,
  'Other': null,
};

int? _int(Object? raw) => raw is num ? raw.toInt() : null;

/// Sector value -> its label ('fintech' -> 'Fintech').
final Map<String, String> sectorLabelOf = {
  for (final e in sectorValue.entries) e.value: e.key,
};

/// The fields of a `startups/{id}` document that matching reads.
class MatchStartup {
  MatchStartup.fromMap(this.id, Map<String, dynamic> data)
    : name = (data['name'] as String?) ?? '',
      sector = data['sector'] as String?,
      sectorOther = _text(data['sectorOther']),
      otherSectors = {
        for (final v in (data['otherSectors'] as List?) ?? const [])
          if (v is String && sectorValue[v] != null) sectorValue[v]!,
      },
      stage = data['stage'] as String?,
      businessModel = data['businessModel'] as String?,
      lookingFor = [
        for (final v in (data['lookingFor'] as List?) ?? const [])
          if (v is String) v,
      ],
      fundingRequirement = _int(data['fundingRequirement']),
      raisedInRound = _int(data['raisedInRound']),
      isPublic = data['isPublic'] == true,
      isClosed = data['status'] == 'closed';

  final String id;
  final String name;

  /// The main sector (the first one the founder picked), as a stored value.
  final String? sector;

  /// What the founder typed when the main sector is "Other".
  final String? sectorOther;

  /// The sectors picked after the main one (stored values; a typed "Other"
  /// sector can't be matched). They count as a WEAKER match than [sector].
  final Set<String> otherSectors;
  final String? stage;
  final String? businessModel;
  final List<String> lookingFor;

  /// The open round's amount (SAR); only set while raising.
  final int? fundingRequirement;

  /// What the open round has raised so far (SAR).
  final int? raisedInRound;

  /// `isPublic == true`. A private startup is never shown to an investor.
  final bool isPublic;

  /// `status == 'closed'` (older startups have no status: active).
  final bool isClosed;

  /// Shown to investors at all: public and not closed.
  bool get isListed => isPublic && !isClosed;

  /// What the open round still needs: the amount minus what is raised
  /// (0 when not raising or fully raised).
  int get remaining {
    if (!lookingFor.contains('funding')) return 0;
    final left = (fundingRequirement ?? 0) - (raisedInRound ?? 0);
    return left > 0 ? left : 0;
  }

  /// Funding is ticked and the round still needs money.
  bool get isRaising => !isClosed && remaining > 0;

  /// The main sector as people read it ("Fintech", or the typed Other).
  String get sectorLabel => sector == 'other'
      ? (sectorOther ?? 'Other')
      : sectorLabelOf[sector] ?? sector ?? '';
}

String? _text(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

/// The fields of an `investors/{id}` document (or the investor's own
/// `users/{uid}`) that matching reads. The lists are turned into the
/// startups' stored values once, here.
class MatchInvestor {
  MatchInvestor.fromMap(this.id, Map<String, dynamic> data)
    : name = (data['fullName'] as String?) ?? '',
      sectors = _values(data['preferredSectors'], sectorValue),
      stages = _values(data['preferredStages'], stageValue),
      models = _values(data['preferredCommerceModels'], modelValue),
      ticketSize = data['ticketSize'] as String?,
      roundSizeMin = _int(data['roundSizeMin']),
      roundSizeMax = _int(data['roundSizeMax']);

  final String id;
  final String name;
  final Set<String> sectors;
  final Set<String> stages;

  /// The commerce models; also the 20% part of a ticket's score.
  final Set<String> models;
  final String? ticketSize;
  final int? roundSizeMin;
  final int? roundSizeMax;

  static Set<String> _values(Object? raw, Map<String, String> toValue) => {
    if (raw is List)
      for (final label in raw)
        if (label is String && toValue.containsKey(label)) toValue[label]!,
  };

  /// Profile matching needs sectors and stages.
  bool get interestsComplete => sectors.isNotEmpty && stages.isNotEmpty;
}

/// The fields of a `tickets/{investorId}-T{n}` document that matching reads.
class MatchTicket {
  MatchTicket.fromMap(this.id, Map<String, dynamic> data)
    : investorId = (data['investorId'] as String?) ?? '',
      name = (data['name'] as String?)?.trim() ?? '',
      sectors = [
        for (final v in (data['sectors'] as List?) ?? const [])
          if (v is String && v.trim().isNotEmpty) v.trim(),
      ],
      stages = _stageValues(data['stages']),
      amountMin = _int(data['amountMin']) ?? 0,
      amountMax = _int(data['amountMax']) ?? 0,
      isOpen = (data['status'] ?? 'open') == 'open';

  final String id;
  final String investorId;
  final String name;

  /// Sector labels as saved ("Logistics", or a typed "Other" sector).
  final List<String> sectors;

  /// Stage values ('seed').
  final Set<String> stages;
  final int amountMin;
  final int amountMax;

  /// Only open tickets match (used and closed ones don't).
  final bool isOpen;

  static Set<String> _stageValues(Object? raw) => {
    if (raw is List)
      for (final label in raw)
        if (label is String && stageValue.containsKey(label.trim()))
          stageValue[label.trim()]!,
  };

  /// The ticket's sectors that are one of the app's options, as values.
  Set<String> get sectorValues => {
    for (final x in sectors)
      for (final e in sectorValue.entries)
        if (e.key != 'Other' && OtherCheck.same(x, e.key)) e.value,
  };
}

// ------------------------------------------------------- profile filters

/// Null = not checked (the startup isn't raising, or the ticket is Other).
/// The band's minimum must be no more than what the round still needs.
bool? ticketFits(MatchInvestor investor, MatchStartup startup) {
  if (!startup.isRaising) return null;
  final min = ticketMin[investor.ticketSize ?? ''];
  if (min == null) return null;
  return min <= startup.remaining;
}

/// Null = not checked (the startup isn't raising, or no round size given).
/// The round's whole amount must be within the investor's range.
bool? roundSizeFits(MatchInvestor investor, MatchStartup startup) {
  final lo = investor.roundSizeMin;
  final hi = investor.roundSizeMax;
  if (!startup.isRaising || (lo == null && hi == null)) return null;
  final round = startup.fundingRequirement!;
  return (lo == null || round >= lo) && (hi == null || round <= hi);
}

/// True when one of the startup's other (not main) sectors is one the
/// investor invests in.
bool sharesOtherSector(MatchInvestor investor, MatchStartup startup) =>
    startup.otherSectors.any(investor.sectors.contains);

/// The hard filters a pair fails; empty = the pair can match.
List<String> failedFilters(MatchInvestor investor, MatchStartup startup) => [
  if (!investor.sectors.contains(startup.sector)) 'sector',
  if (!investor.stages.contains(startup.stage)) 'stage',
  if (ticketFits(investor, startup) == false) 'ticket',
  if (roundSizeFits(investor, startup) == false) 'round size',
];

/// A close match: not an exact one, but the sector or the stage fits and
/// the ticket and round size still fit. Close matches come after every
/// exact match.
bool isClose(MatchInvestor investor, MatchStartup startup) =>
    _oneOfSectorOrStage(failedFilters(investor, startup));

bool _oneOfSectorOrStage(List<String> failed) =>
    failed.length == 1 && (failed.first == 'sector' || failed.first == 'stage');

// -------------------------------------------------------- ticket filters

/// The startup's main sector is one of the ticket's: the same text by the
/// rule of the "Other" box ("Sports Tech" is "SportsTech"), or the ticket
/// has the plain "Other" and the startup's sector is an Other.
bool ticketSectorFits(MatchTicket ticket, MatchStartup startup) {
  for (final x in ticket.sectors) {
    if (OtherCheck.same(x, startup.sectorLabel)) return true;
    if (x == 'Other' && startup.sector == 'other') return true;
  }
  return false;
}

/// One of the startup's other (not main) sectors is in the ticket.
bool ticketSharesOtherSector(MatchTicket ticket, MatchStartup startup) {
  final values = ticket.sectorValues;
  return startup.otherSectors.any(values.contains);
}

/// The ticket's minimum is no more than what the round still needs.
bool ticketAmountFits(MatchTicket ticket, MatchStartup startup) =>
    startup.isRaising && ticket.amountMin <= startup.remaining;

/// The ticket filters a pair fails; empty = an exact match.
List<String> failedTicketFilters(MatchTicket ticket, MatchStartup startup) => [
  if (!ticketSectorFits(ticket, startup)) 'sector',
  if (!ticket.stages.contains(startup.stage)) 'stage',
  if (!ticketAmountFits(ticket, startup)) 'amount',
];

/// A close match for a ticket: only the sector or only the stage misses,
/// and the amount still fits.
bool isCloseForTicket(MatchTicket ticket, MatchStartup startup) =>
    _oneOfSectorOrStage(failedTicketFilters(ticket, startup));
