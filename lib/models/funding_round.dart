import '../app_constants/firestore_collections.dart';
import 'startup_enums.dart';

/// One investor of a funding round, as stored in the round document:
/// `{name, investorId, isLead}`.
class RoundInvestor {
  const RoundInvestor({required this.name, this.investorId, this.isLead = false});

  final String name;

  /// The `investors/{id}` profile, or null when the investor has none (the
  /// name is then shown as plain grey text).
  final String? investorId;

  /// The lead investor of the round ("· Lead").
  final bool isLead;

  bool get hasProfile => (investorId ?? '').isNotEmpty;

  Map<String, Object?> toMap() => {
    'name': name,
    'investorId': investorId,
    'isLead': isLead,
  };

  /// Null for an entry without a name.
  static RoundInvestor? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final id = raw['investorId'];
    return RoundInvestor(
      name: name.trim(),
      investorId: id is String && id.isNotEmpty ? id : null,
      isLead: raw['isLead'] == true,
    );
  }
}

/// One funding round of a startup: a document of
/// `startups/{startupId}/fundingRounds/{roundId}` (see FundingRoundFields).
///
/// A startup has at most one OPEN round, and only while it asks for Funding:
/// the startup's `fundingRequirement` is the open round's [amount]. The
/// startup repository keeps the two in step on every save.
class FundingRound {
  const FundingRound({
    required this.number,
    required this.type,
    required this.amount,
    required this.start,
    this.id = '',
    this.typeOther,
    this.raised = 0,
    this.end,
    this.investors = const [],
    this.wantsLeadInvestor,
  });

  /// The document id ('' for a round that is not saved yet).
  final String id;

  /// 1, 2, 3... in date order (the rounds shown are numbered again when
  /// loaded, so a hidden round leaves no gap).
  final int number;

  /// "Pre-seed", "Seed", "Series A"...
  final StartupStage type;

  /// The written type when [type] is Other (dataset rounds such as
  /// "Private Equity").
  final String? typeOther;

  /// The amount the startup is raising, in SAR.
  final int amount;

  /// How much of it has been raised so far, in SAR (it can go past [amount]).
  final int raised;

  final DateTime start;

  /// Null while the round is open.
  final DateTime? end;

  /// The investors who invested in this round, the lead first.
  final List<RoundInvestor> investors;

  /// "Are you looking for a lead investor?" answer given when it was added.
  final bool? wantsLeadInvestor;

  bool get isOpen => end == null;

  /// "Seed", or the written type of an Other round.
  String get typeLabel {
    final other = (typeOther ?? '').trim();
    return type == StartupStage.other && other.isNotEmpty ? other : type.label;
  }

  /// Percentage of [amount] raised. The bar stops at 100 %, the number can go
  /// past it (e.g. 110 %).
  int get percent => amount <= 0 ? 0 : (raised * 100 / amount).round();

  FundingRound copyWith({
    String? id,
    int? number,
    StartupStage? type,
    int? amount,
    int? raised,
    DateTime? start,
    DateTime? end,
    List<RoundInvestor>? investors,
    bool? wantsLeadInvestor,
  }) => FundingRound(
    id: id ?? this.id,
    number: number ?? this.number,
    type: type ?? this.type,
    typeOther: type == null || type == StartupStage.other ? typeOther : null,
    amount: amount ?? this.amount,
    raised: raised ?? this.raised,
    start: start ?? this.start,
    end: end ?? this.end,
    investors: investors ?? this.investors,
    wantsLeadInvestor: wantsLeadInvestor ?? this.wantsLeadInvestor,
  );

  FundingRound withRaised(int value) => copyWith(raised: value);

  /// The round closed on [when]. Raised stays what was actually raised (a
  /// round can close below its target).
  FundingRound closed(DateTime when) => copyWith(end: when);

  // ------------------------------------------------------------ Firestore

  /// The document to save under `startups/[startupId]/fundingRounds`.
  /// Dates are plain DateTimes (Firestore stores them as Timestamps).
  Map<String, Object?> toMap(String startupId) => {
    FundingRoundFields.startupId: startupId,
    FundingRoundFields.number: number,
    FundingRoundFields.status: isOpen
        ? FundingRoundFields.active
        : FundingRoundFields.completed,
    FundingRoundFields.stage: type.value,
    FundingRoundFields.stageOther: type == StartupStage.other
        ? typeOther
        : null,
    FundingRoundFields.amount: amount,
    FundingRoundFields.raised: raised,
    FundingRoundFields.startDate: start,
    FundingRoundFields.endDate: end,
    FundingRoundFields.investors: [for (final i in investors) i.toMap()],
    FundingRoundFields.investorIds: [
      for (final i in investors)
        if (i.hasProfile) i.investorId,
    ],
    FundingRoundFields.investorCount: investors.length,
    FundingRoundFields.wantsLeadInvestor: wantsLeadInvestor,
    FundingRoundFields.isDataset: false,
  };

  /// Null when the document can't be shown: no amount ("Undisclosed" dataset
  /// rounds), no start date or an unknown type.
  static FundingRound? fromMap(String id, Map<String, dynamic>? d) {
    if (d == null) return null;
    final amount = d[FundingRoundFields.amount];
    final start = d[FundingRoundFields.startDate];
    final type = StartupStage.fromValue(d[FundingRoundFields.stage]);
    if (amount is! num || amount <= 0 || start is! DateTime || type == null) {
      return null;
    }
    final end = d[FundingRoundFields.endDate];
    final raised = d[FundingRoundFields.raised];
    final rawInvestors = d[FundingRoundFields.investors];
    final all = [
      if (rawInvestors is List)
        for (final raw in rawInvestors) ?RoundInvestor.fromMap(raw),
    ];
    // The lead first, then the others in stored order.
    final investors = [
      for (final i in all)
        if (i.isLead) i,
      for (final i in all)
        if (!i.isLead) i,
    ];
    final number = d[FundingRoundFields.number];
    final other = d[FundingRoundFields.stageOther];
    final lead = d[FundingRoundFields.wantsLeadInvestor];
    return FundingRound(
      id: id,
      number: number is num ? number.toInt() : 0,
      type: type,
      typeOther: other is String ? other : null,
      amount: amount.toInt(),
      raised: raised is num ? raised.toInt() : 0,
      start: start,
      // "active" is open whatever the end date says.
      end: d[FundingRoundFields.status] == FundingRoundFields.active
          ? null
          : (end is DateTime ? end : start),
      investors: investors,
      wantsLeadInvestor: lead is bool ? lead : null,
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "Aug 2026 – now" while open, "Feb 2022" when it started and ended in the
  /// same month, "Jan – Jun 2026" in the same year, otherwise
  /// "Dec 2025 – Jun 2026".
  String get dateLabel {
    final s = start;
    final e = end;
    if (e == null) return '${_months[s.month - 1]} ${s.year} – now';
    if (e.year == s.year && e.month == s.month) {
      return '${_months[s.month - 1]} ${s.year}';
    }
    if (e.year == s.year) {
      return '${_months[s.month - 1]} – ${_months[e.month - 1]} ${e.year}';
    }
    return '${_months[s.month - 1]} ${s.year} – ${_months[e.month - 1]} ${e.year}';
  }
}
