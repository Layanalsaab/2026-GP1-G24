/// Where an investment association stands.
enum AssociationStatus { approved, waiting }

/// One investor linked to a startup (Figma "Investment associations").
///
/// Only an association that is [AssociationStatus.approved] and [isPublic]
/// is listed on the startup's profile (preview, investor and guest views);
/// the founder's Manage page lists all of them with their status.
class StartupAssociation {
  const StartupAssociation({
    required this.name,
    required this.subtitle,
    this.status = AssociationStatus.approved,
    this.isPublic = true,
  });

  /// The investor's name.
  final String name;

  /// The investor's city.
  final String subtitle;
  final AssociationStatus status;

  /// Whether the investor agreed to be listed on the startup's profile.
  final bool isPublic;

  bool get isApproved => status == AssociationStatus.approved;

  /// Listed on the startup profile seen by others.
  bool get isShownPublicly => isApproved && isPublic;

  /// Keeps only the associations other people may see.
  static List<StartupAssociation> publicOnly(
    Iterable<StartupAssociation> all,
  ) => [
    for (final item in all)
      if (item.isShownPublicly) item,
  ];
}
