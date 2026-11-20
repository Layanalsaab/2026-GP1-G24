import '../recommender/content_ranker.dart';

export '../recommender/content_ranker.dart' show MatchResult, MatchRow;

class MatchSummary {
  const MatchSummary({
    required this.percent,
    required this.target,
    required this.rows,
    this.note,
  });

  /// The investor's ticket matched to a startup.
  factory MatchSummary.forTicket(String ticketName, MatchResult m) =>
      MatchSummary(
        percent: m.percent,
        target: 'your ticket “$ticketName”',
        rows: m.rows,
      );

  /// An investor matched to the founder's startup (its open round).
  factory MatchSummary.forStartup(String startupName, MatchResult m) =>
      MatchSummary(
        percent: m.percent,
        target: 'your startup $startupName',
        rows: m.rows,
        note: m.viaTicket
            ? 'They have an open investment ticket for a round like yours.'
            : null,
      );

  final int percent;

  final String target;

  /// One row per criterion (sector, stage, commerce model, amount).
  final List<MatchRow> rows;

  /// An extra line under the headline, or null.
  final String? note;

  /// "86% match with your startup Daftar Pay".
  String get headline => '$percent% match with $target';
}
