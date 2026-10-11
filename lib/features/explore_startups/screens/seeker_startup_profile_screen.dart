import 'package:flutter/material.dart';

import '../../../models/startup_listing.dart';
import '../../startups/widgets/startup_profile_view.dart';

/// Figma "V2 · 45c · Startup Profile — Guest view": a startup as a startup
/// seeker (no account) sees it. Same page as the investor view, with
/// "Express interest" instead of "Send request". Design phase: sharing
/// and expressing interest are inert placeholders; guests have no bookmark.
class SeekerStartupProfileScreen extends StatelessWidget {
  const SeekerStartupProfileScreen({
    super.key,
    required this.listing,
    this.founderName,
  });

  final StartupListing listing;

  /// Shown as "Founded by ..."; the row is hidden when null.
  final String? founderName;

  @override
  Widget build(BuildContext context) {
    return StartupProfileView(
      startup: listing.startup,
      mode: StartupProfileMode.guest,
      founderName: founderName,
      associations: listing.associations,
    );
  }
}
