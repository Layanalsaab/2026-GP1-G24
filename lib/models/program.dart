/// The kind of support program (Figma "V2 · 16 · Programs").
enum ProgramType {
  accelerator('Accelerator'),
  incubator('Incubator'),
  studio('Studio');

  const ProgramType(this.label);

  final String label;
}

/// An accelerator, incubator or studio that supports startups.
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
  final String? websiteUrl;

  /// The letter shown in the logo square.
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
}
