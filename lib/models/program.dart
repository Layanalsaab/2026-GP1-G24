/// The kind of support program (Figma "V2 · 16 · Programs").
enum ProgramType {
  accelerator('Accelerator'),
  incubator('Incubator'),
  studio('Venture studio'),
  angelNetwork('Angel network');

  const ProgramType(this.label);

  final String label;
}

/// An accelerator, incubator, studio or angel network that supports startups.
class Program {
  const Program({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    required this.duration,
    required this.sinceYear,
    required this.about,
    required this.focusSectors,
    this.summary,
    this.focus,
    this.logoText,
    this.websiteUrl,
  });

  final String id;
  final String name;
  final ProgramType type;
  final String city;

  /// Shown as written, e.g. "6 months".
  final String duration;
  final int sinceYear;
  final String about;
  final List<String> focusSectors;

  /// One short sentence for the list card; falls back to [about].
  final String? summary;

  /// The "Focus" line on the list card, e.g. "Early-stage tech"; falls back to
  /// the focus sectors.
  final String? focus;

  /// The letters in the logo square when they differ from the first letter.
  final String? logoText;
  final String? websiteUrl;

  String get cardSummary => summary ?? about;
  String get cardFocus => focus ?? focusSectors.join(', ');

  /// The letters shown in the logo square.
  String get initial {
    final text = logoText;
    if (text != null && text.isNotEmpty) return text;
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}
