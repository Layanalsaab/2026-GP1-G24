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
    this.about,
    this.bio,
    this.matchPercent,
    this.matchReason,
    this.linkedin,
    this.valueOffered,
    this.hopeToGain,
    this.joinedLabel,
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

  /// Short description shown on the list cards.
  final String? about;

  /// Longer text for the profile page; falls back to [about].
  final String? bio;

  String get profileBio => bio ?? about ?? '';

  /// Only set for the Matches tab.
  final int? matchPercent;
  final String? matchReason;

  /// Optional LinkedIn link ("linkedin.com/in/ahmad-hassan").
  final String? linkedin;

  /// "What I can bring to startups".
  final String? valueOffered;

  /// "What I hope to gain".
  final String? hopeToGain;

  /// "Joined yesterday" / "Joined 3 days ago" on the "New on Start.sa" rail.
  final String? joinedLabel;

  /// First letter of the first and last name; "Sara Al-Mohsen" gives "SM".
  String get initials {
    final words = name
        .split(RegExp(r'[\s-]+'))
        .where((w) => w.isNotEmpty)
        .toList();
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
    about: about,
    bio: bio,
    matchPercent: percent,
    matchReason: reason,
    linkedin: linkedin,
    valueOffered: valueOffered,
    hopeToGain: hopeToGain,
    joinedLabel: joinedLabel,
  );
}
