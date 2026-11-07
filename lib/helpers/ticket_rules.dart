import '../models/investment_ticket.dart';
import '../models/startup.dart';
import '../models/startup_enums.dart';
import 'formatters.dart';
import 'other_check.dart';

/// Errors of the ticket form (null = fine). Same wording as the prototype.
class TicketErrors {
  TicketErrors._();

  static const maxName = 40;

  static String? name(String value) =>
      value.trim().isEmpty ? 'Enter a name for this ticket.' : null;

  /// [other] is what was typed for "Other" (an unticked or blank Other is
  /// refused like the other pickers do).
  static String? sectors(Set<String> value, {String other = ''}) {
    if (value.isEmpty) return 'Select at least one sector.';
    if (value.contains('Other') && other.trim().isEmpty) {
      return 'Please type your sector — it can’t be blank.';
    }
    return null;
  }

  static String? stages(Set<String> value) =>
      value.isEmpty ? 'Select at least one stage.' : null;

  /// The smallest amount in a ticket, the same minimum as the other money
  /// boxes in the app. (Nothing limits it from above: a ticket is not tied to
  /// what the investor usually invests.)
  static const minAmount = 1000;

  static String? minimum(int? min) {
    if (min == null || min <= 0) return 'Enter the minimum amount.';
    if (min < minAmount) {
      return 'The minimum must be at least ${Formatters.sar(minAmount)}.';
    }
    return null;
  }

  /// The maximum is required, at least the same smallest amount, and more
  /// than the minimum (when the minimum is filled in).
  static String? maximum(int? max, int? min) {
    if (max == null || max <= 0) return 'Enter the maximum amount.';
    if (max < minAmount) {
      return 'The maximum must be at least ${Formatters.sar(minAmount)}.';
    }
    if (min != null && min > 0 && max <= min) {
      return 'The maximum must be more than the minimum.';
    }
    return null;
  }
}

/// Whether a request amount fits a ticket and the round that is still open.
class TicketSend {
  TicketSend._();

  /// The most a request may be: the ticket's maximum or what the round still
  /// needs, whichever is smaller.
  static int most(InvestmentTicket ticket, int remaining) =>
      ticket.amountMax < remaining ? ticket.amountMax : remaining;

  static String? error(int? amount, InvestmentTicket ticket, int remaining) {
    if (amount == null || amount <= 0) return 'Enter an amount.';
    if (amount < ticket.amountMin) {
      return 'The minimum for this ticket is ${Formatters.sar(ticket.amountMin)}.';
    }
    final max = most(ticket, remaining);
    if (amount > max) {
      return 'The most you can send is ${Formatters.sar(max)}.';
    }
    return null;
  }

  static String range(InvestmentTicket ticket, int remaining) =>
      'Between ${Formatters.sar(ticket.amountMin)} and '
      '${Formatters.sar(most(ticket, remaining))}';
}

/// A startup whose open round fits a ticket.
class TicketMatch {
  const TicketMatch({
    required this.startup,
    required this.remaining,
    required this.percent,
    required this.reason,
  });

  final Startup startup;

  /// What the open round still needs (funding minus raised), in SAR.
  final int remaining;
  final int percent;
  final String reason;
}

class TicketMatcher {
  TicketMatcher._();

  /// What the startup's open round still needs, or 0 when it is not raising.
  static int remainingOf(Startup s) {
    final funding = s.fundingRequirement;
    if (funding == null || funding <= 0) return 0;
    final left = funding - (s.raisedInRound ?? 0);
    return left > 0 ? left : 0;
  }

  /// The startup's main sector is one of the ticket's: the same text by the
  /// rule of the "Other" box ("Sports Tech" is "SportsTech"), or the ticket
  /// has the plain "Other" and the startup's sector is an Other.
  static bool _sectorFits(InvestmentTicket ticket, Startup s) {
    for (final x in ticket.sectors) {
      if (OtherCheck.same(x, s.sectorLabel)) return true;
      if (x == 'Other' && s.sector == Sector.other) return true;
    }
    return false;
  }

  /// A ticket fits a startup when the startup's main sector and stage are in
  /// the ticket and the ticket's minimum is no more than what the open round
  /// still needs. Only open tickets match.
  static TicketMatch? match(InvestmentTicket ticket, Startup s) {
    if (!ticket.isOpen) return null;
    final remaining = remainingOf(s);
    if (remaining == 0) return null;
    if (!_sectorFits(ticket, s)) return null;
    if (!ticket.stages.contains(s.stage.label)) return null;
    if (ticket.amountMin > remaining) return null;
    final covers = ticket.amountMax >= remaining;
    // A placeholder percentage until the real ranking is used.
    final percent = (70 + (covers ? 15 : 8) + 5).clamp(0, 98);
    return TicketMatch(
      startup: s,
      remaining: remaining,
      percent: percent,
      reason: 'Same sector and stage${covers ? ' · fits your range' : ''}',
    );
  }

  /// The matches of [ticket], best first (the percentage, then the name).
  static List<TicketMatch> matches(
    InvestmentTicket ticket,
    Iterable<Startup> startups,
  ) {
    final out = <TicketMatch>[];
    for (final s in startups) {
      if (s.isClosed) continue;
      final m = match(ticket, s);
      if (m != null) out.add(m);
    }
    out.sort((a, b) {
      final byPercent = b.percent.compareTo(a.percent);
      return byPercent != 0
          ? byPercent
          : a.startup.name.compareTo(b.startup.name);
    });
    return out;
  }
}

/// "Logistics, E-commerce +1": at most [max] items, then "+N".
String shortList(List<String> items, {int max = 2}) {
  if (items.length <= max) return items.join(', ');
  return '${items.take(max).join(', ')} +${items.length - max}';
}

/// "2h ago", "3d ago" (the time since [when]).
String timeAgo(DateTime? when, {DateTime? now}) {
  if (when == null) return 'just now';
  final diff = (now ?? DateTime.now()).difference(when);
  final minutes = diff.inMinutes;
  if (minutes < 1) return 'just now';
  if (minutes < 60) return '${minutes}m ago';
  final hours = diff.inHours;
  if (hours < 24) return '${hours}h ago';
  final days = diff.inDays;
  if (days < 7) return '${days}d ago';
  if (days < 60) return '${days ~/ 7}w ago';
  return '${days ~/ 30}mo ago';
}
