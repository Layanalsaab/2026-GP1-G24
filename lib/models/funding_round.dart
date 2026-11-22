import '../app_constants/firestore_collections.dart';
import 'startup_enums.dart';

/// One investor of a funding round, as stored in the round document: {name, investorId}.
class RoundInvestor {
  const RoundInvestor({required this.name, this.investorId});

  final String name;

  final String? investorId;

  bool get hasProfile => (investorId ?? '').isNotEmpty;

  Map<String, Object?> toMap() => {'name': name, 'investorId': investorId};

  /// Null for an entry without a name.
  static RoundInvestor? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final id = raw['investorId'];
    return RoundInvestor(
      name: name.trim(),
      investorId: id is String && id.isNotEmpty ? id : null,
    );
  }
}

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
  });

  /// The document id ('' for a round that is not saved yet).
  final String id;

  /// 1, 2, 3...
  final int number;

  /// "Pre-seed", "Seed", "Series A"...
  final StartupStage type;

  final String? typeOther;

  /// The amount the startup is raising, in SAR.
  final int amount;

  /// How much of it has been raised so far, in SAR (it can go past amount).
  final int raised;

  final DateTime start;

  /// Null while the round is open.
  final DateTime? end;

  /// The investors who invested in this round, the lead first.
  final List<RoundInvestor> investors;

  bool get isOpen => end == null;

  /// "Seed", or the written type of an Other round.
  String get typeLabel {
    final other = (typeOther ?? '').trim();
    return type == StartupStage.other && other.isNotEmpty ? other : type.label;
  }

  /// Percentage of amount raised.
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
  );

  FundingRound withRaised(int value) => copyWith(raised: value);

  /// The round closed on when.
  FundingRound closed(DateTime when) => copyWith(end: when);

  /// The document to save under startups/startupId/fundingRounds.
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
    FundingRoundFields.isArchived: false,
  };

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
    final investors = [
      if (rawInvestors is List)
        for (final raw in rawInvestors) ?RoundInvestor.fromMap(raw),
    ];
    final number = d[FundingRoundFields.number];
    final other = d[FundingRoundFields.stageOther];
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
