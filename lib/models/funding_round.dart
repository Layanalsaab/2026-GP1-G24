import 'investor_profile.dart';
import 'startup_enums.dart';

/// One funding round of a startup (Manage -> Rounds).
///
/// INTERFACE ONLY: there is no rounds data in the backend yet. The Rounds tab
/// is built on a list of these, held in local state and filled from
/// `PrototypeSeed.sampleRounds`. A teammate replaces that with the real rounds
/// (and the real open / close / add actions) without touching the screen.
class FundingRound {
  const FundingRound({
    required this.number,
    required this.type,
    required this.amount,
    required this.start,
    this.raised = 0,
    this.end,
    this.investors = const [],
    this.wantsLeadInvestor,
  });

  /// 1, 2, 3... in the order the rounds were added.
  final int number;

  /// "Pre-seed", "Seed", "Series A"...
  final StartupStage type;

  /// The amount the startup is raising, in SAR.
  final int amount;

  /// How much of it has been raised so far, in SAR (it can go past [amount]).
  final int raised;

  final DateTime start;

  /// Null while the round is open.
  final DateTime? end;

  /// The investors who invested in this round.
  final List<InvestorProfile> investors;

  /// "Are you looking for a lead investor?" answer given when it was added.
  final bool? wantsLeadInvestor;

  bool get isOpen => end == null;

  /// Percentage of [amount] raised. The bar stops at 100 %, the number can go
  /// past it (e.g. 110 %).
  int get percent => amount <= 0 ? 0 : (raised * 100 / amount).round();

  FundingRound closed(DateTime when) => FundingRound(
    number: number,
    type: type,
    amount: amount,
    raised: raised,
    start: start,
    end: when,
    investors: investors,
    wantsLeadInvestor: wantsLeadInvestor,
  );

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

  /// "Aug 2026 – now" while open, "Jan – Jun 2026" when it started and ended
  /// in the same year, otherwise "Dec 2025 – Jun 2026".
  String get dateLabel {
    final s = start;
    final e = end;
    if (e == null) return '${_months[s.month - 1]} ${s.year} – now';
    if (e.year == s.year) {
      return '${_months[s.month - 1]} – ${_months[e.month - 1]} ${e.year}';
    }
    return '${_months[s.month - 1]} ${s.year} – ${_months[e.month - 1]} ${e.year}';
  }
}
