import '../helpers/formatters.dart';
import 'startup_association.dart';
import 'startup.dart';
import 'startup_enums.dart';

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

  /// Investment associations (all of them; profiles show only the public
  /// ones, see [StartupAssociation.publicOnly]).
  final List<StartupAssociation> associations;

  String get name => startup.name;

  /// The short line for cards (see [Startup.summary]).
  String get tagline => startup.summary;
  String get initials => initialsOverride ?? startup.initials;

  /// "HealthTech" from "HealthTech · Pre-seed".
  String get sectorLabel => sectorStage.split(' · ').first;

  /// "Pre-seed" from "HealthTech · Pre-seed" (empty if there is none).
  String get stageLabel {
    final parts = sectorStage.split(' · ');
    return parts.length > 1 ? parts[1] : '';
  }

  /// What the startup is looking for, as shown on cards: "Funding · SAR 500K",
  /// "Partnership" or a comma-separated list.
  String get needsLabel {
    final items = [
      for (final item in LookingFor.values)
        if (startup.lookingFor.contains(item))
          item == LookingFor.funding && startup.fundingRequirement != null
              ? '${item.label} · ${Formatters.compactSar(startup.fundingRequirement!)}'
              : startup.lookingForLabelOf(item),
    ];
    return items.join(', ');
  }

  /// What the startup is looking for, without amounts: "Funding, Talent".
  String get needsNames => [
    for (final item in LookingFor.values)
      if (startup.lookingFor.contains(item)) startup.lookingForLabelOf(item),
  ].join(', ');

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
