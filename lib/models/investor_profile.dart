/// An investor as shown to founders: in lists and on their profile page
/// (Figma "V2 · 10 / 12 / 15").
class InvestorProfile {
  const InvestorProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.city,
    required this.sectors,
    required this.stages,
    required this.ticketRange,
    required this.locations,
    this.matchPercent,
    this.matchReason,
  });

  final String id;
  final String name;

  /// e.g. "Angel Investor", "VC Associate".
  final String title;
  final String city;
  final List<String> sectors;
  final List<String> stages;

  /// Shown as written, e.g. "SAR 100K – 500K".
  final String ticketRange;
  final List<String> locations;

  /// Only set for the Matches tab.
  final int? matchPercent;
  final String? matchReason;

  /// First letter of the first and last name; "Sara Al-Mohsen" gives "SM".
  String get initials {
    final words =
        name.split(RegExp(r'[\s-]+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  /// "Angel Investor · HealthTech, Fintech".
  String get headline => '$title · ${sectors.join(', ')}';

  /// "Pre-seed – Seed", or just the one stage.
  String get stageRange =>
      stages.length > 1 ? '${stages.first} – ${stages.last}' : stages.first;

  InvestorProfile withMatch(int percent, String reason) => InvestorProfile(
        id: id,
        name: name,
        title: title,
        city: city,
        sectors: sectors,
        stages: stages,
        ticketRange: ticketRange,
        locations: locations,
        matchPercent: percent,
        matchReason: reason,
      );
}
