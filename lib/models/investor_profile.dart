import 'investor_criteria.dart';

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
    this.createdAt,
    this.email,
    this.phone,
    this.emailPublic = false,
    this.phonePublic = false,
    this.yearsInvesting,
    this.startupsInvested,
    this.roundSize,
    this.ledRound,
    this.commerceModels = const [],
    this.photoUrl,
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

  /// When the document was created (orders the "New on Start.sa" rail).
  final DateTime? createdAt;

  /// e.g. "4–6 years".
  final String? yearsInvesting;

  /// "0", "1–3", ... "10+".
  final String? startupsInvested;

  /// Investment size per funding round, e.g. "SAR 500K – 1M".
  final String? roundSize;
  final bool? ledRound;

  /// Contact details, only set for what the investor made Public (their
  /// email / phone are never listed otherwise).
  final String? email;
  final String? phone;
  final bool emailPublic;
  final bool phonePublic;

  /// Short names ("B2B").
  final List<String> commerceModels;

  /// Profile photo (null: the default picture).
  final String? photoUrl;

  /// "SAR 500K – 1M" from two amounts (K thousands, M millions); one amount
  /// gives "SAR 500K"; none gives "".
  static String amountLabel(int? min, int? max) {
    String short(int n) {
      String trim(double v) =>
          v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
      if (n >= 1000000) return '${trim(n / 1000000)}M';
      if (n >= 1000) return '${trim(n / 1000)}K';
      return '$n';
    }

    if (min == null && max == null) return '';
    if (min == null || max == null) return 'SAR ${short(min ?? max!)}';
    return 'SAR ${short(min)} – ${short(max)}';
  }

  static List<String> _strings(Object? v) =>
      v is List ? v.whereType<String>().toList() : const [];

  static String? _text(Object? v) {
    final t = v is String ? v.trim() : '';
    return t.isEmpty ? null : t;
  }

  /// Reads an `investors/{id}` document (the same field names as an
  /// investor's `users/{uid}` document). Null without a name.
  static InvestorProfile? fromMap(String id, Map<String, dynamic>? d) {
    if (d == null) return null;
    final name = _text(d['fullName']);
    if (name == null) return null;
    final city = _text(d['city']) ?? '';
    final bio = _text(d['bio']);
    final c = InvestorCriteria.fromFields(d);
    final deals = c?.dealsCount;
    final shortModels = c?.commerceModelsShort ?? '';
    return InvestorProfile(
      id: id,
      name: name,
      title: _text(d['title']) ?? 'Investor',
      city: city,
      sectors: _strings(d['preferredSectors']),
      stages: _strings(d['preferredStages']),
      ticketRange: (c?.roundSizeLabel ?? '').isNotEmpty
          ? c!.roundSizeLabel
          : (_text(d['ticketSize']) ?? ''),
      locations: city.isEmpty ? const [] : [city],
      about: bio,
      bio: bio,
      linkedin: _text(d['linkedinUrl']),
      valueOffered: _text(d['offer']),
      hopeToGain: _text(d['lookingFor']),
      createdAt: d['createdAt'] is DateTime ? d['createdAt'] as DateTime : null,
      emailPublic: d['emailPublic'] == true,
      phonePublic: d['phonePublic'] == true,
      email: d['emailPublic'] == true ? _text(d['email']) : null,
      phone: d['phonePublic'] == true ? _text(d['phone']) : null,
      yearsInvesting: c?.yearsInvesting,
      startupsInvested: deals,
      roundSize: deals == '0'
          ? null
          : [c?.roundMin, c?.roundMax].every((v) => v == null)
          ? null
          : amountLabel(c?.roundMin, c?.roundMax),
      ledRound: c?.hasLedRound,
      commerceModels: shortModels.isEmpty ? const [] : shortModels.split(', '),
      photoUrl: _text(d['photoUrl']),
    );
  }

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
  String get headline =>
      sectors.isEmpty ? title : '$title · ${sectors.join(', ')}';

  /// "Pre-seed – Seed", or just the one stage.
  String get stageRange => stages.isEmpty
      ? ''
      : (stages.length > 1 ? '${stages.first} – ${stages.last}' : stages.first);

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
    createdAt: createdAt,
    email: email,
    phone: phone,
    emailPublic: emailPublic,
    phonePublic: phonePublic,
    yearsInvesting: yearsInvesting,
    startupsInvested: startupsInvested,
    roundSize: roundSize,
    ledRound: ledRound,
    commerceModels: commerceModels,
    photoUrl: photoUrl,
  );
}
