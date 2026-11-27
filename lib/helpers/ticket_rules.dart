import '../models/startup.dart';
import '../recommender/content_ranker.dart' show MatchResult;
import 'formatters.dart';

/// Errors of the ticket form (null = fine).
class TicketErrors {
  TicketErrors._();

  static String? name(String value) =>
      value.trim().isEmpty ? 'Enter a name for this ticket.' : null;

  static String? sectors(Set<String> value, {String other = ''}) {
    if (value.isEmpty) return 'Select at least one sector.';
    if (value.contains('Other') && other.trim().isEmpty) {
      return 'Please type your sector — it can’t be blank.';
    }
    return null;
  }

  static String? stages(Set<String> value) =>
      value.isEmpty ? 'Select at least one stage.' : null;

  static const minAmount = 1000;

  static String? minimum(int? min) {
    if (min == null || min <= 0) return 'Enter the minimum amount.';
    if (min < minAmount) {
      return 'The minimum must be at least ${Formatters.sar(minAmount)}.';
    }
    return null;
  }

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

/// "Logistics, E-commerce +1": at most max items, then "+N".
String shortList(List<String> items, {int max = 2}) {
  if (items.length <= max) return items.join(', ');
  return '${items.take(max).join(', ')} +${items.length - max}';
}
