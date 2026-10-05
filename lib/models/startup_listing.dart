import 'startup.dart';

/// A startup as shown on a list card (Figma "V2 · 10 / 12b / 11"): a short
/// summary for the card, plus the full [Startup] its profile page opens.
class StartupListing {
  const StartupListing({
    required this.startup,
    required this.sectorStage,
    required this.city,
    this.matchPercent,
    this.matchReason,
    this.initialsOverride,
    this.teamSize,
    this.lookingForNote,
    this.associations = const [],
  });

  final Startup startup;

  /// The chip text, e.g. "HealthTech · Pre-seed".
  final String sectorStage;
  final String city;

  /// Only set for the Matches tab.
  final int? matchPercent;
  final String? matchReason;

  /// Two letters for the logo square. Defaults to the startup's own initials;
  /// the sample data sets it where Figma shows two letters for a one-word name.
  final String? initialsOverride;

  /// Shown on the seeker's startup profile (Figma "V2 · 14c").
  final int? teamSize;
  final String? lookingForNote;
  final List<({String name, String subtitle})> associations;

  String get name => startup.name;
  String get tagline => startup.tagline ?? '';
  String get initials => initialsOverride ?? startup.initials;

  /// "HealthTech" from "HealthTech · Pre-seed".
  String get sectorLabel => sectorStage.split(' · ').first;

  /// "Pre-seed" from "HealthTech · Pre-seed" (empty if there is none).
  String get stageLabel {
    final parts = sectorStage.split(' · ');
    return parts.length > 1 ? parts[1] : '';
  }

  StartupListing withMatch(int percent, String reason) => StartupListing(
        startup: startup,
        sectorStage: sectorStage,
        city: city,
        matchPercent: percent,
        matchReason: reason,
        initialsOverride: initialsOverride,
        teamSize: teamSize,
        lookingForNote: lookingForNote,
        associations: associations,
      );
}
