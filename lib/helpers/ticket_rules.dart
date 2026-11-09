import '../models/investment_ticket.dart';
import '../models/startup.dart';
import '../recommender/content_ranker.dart' show MatchResult;
import 'formatters.dart';

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

/// A startup in a ticket's matches (the rules and the score are in
/// lib/recommender; see MatchingRepository.matchesForTicket).
class TicketMatch {
  const TicketMatch({required this.startup, required this.result});

  final Startup startup;
  final MatchResult result;

  /// What the open round still needs (funding minus raised), in SAR.
  int get remaining => result.remaining;
  int get percent => result.percent;

  /// Only the sector or only the stage misses.
  bool get close => result.close;
}

/// What a startup's open round still needs, or 0 when it is not raising.
int remainingOf(Startup s) {
  if (!s.seeksFunding) return 0;
  final funding = s.fundingRequirement;
  if (funding == null || funding <= 0) return 0;
  final left = funding - (s.raisedInRound ?? 0);
  return left > 0 ? left : 0;
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
