import 'startup.dart';

/// A startup as shown on a list card (Figma "V2 · 10 / 12b"): a short summary
/// for the card, plus the full [Startup] its profile page opens.
class StartupListing {
  const StartupListing({
    required this.startup,
    required this.sectorStage,
    required this.city,
    this.matchPercent,
    this.matchReason,
    this.initialsOverride,
  });

  final Startup startup;

  /// The chip text, e.g. "HealthTech · Pre-seed".
  final String sectorStage;
  final String city;

  /// Only set for the Matches tab.
  final int? matchPercent;
  final String? matchReason;

  String get name => startup.name;
  String get tagline => startup.tagline ?? '';
  /// Two letters for the logo square. Defaults to the startup's own initials;
  /// the sample data sets it where Figma shows two letters for a one-word name.
  final String? initialsOverride;

  String get initials => initialsOverride ?? startup.initials;

  StartupListing withMatch(int percent, String reason) => StartupListing(
        startup: startup,
        sectorStage: sectorStage,
        city: city,
        matchPercent: percent,
        matchReason: reason,
        initialsOverride: initialsOverride,
      );
}
