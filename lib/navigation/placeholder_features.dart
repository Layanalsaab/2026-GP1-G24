import 'package:flutter/material.dart';

import '../shared_ui/common_widgets/coming_soon_screen.dart';

/// Features planned for later sprints. Every entry point to one of these
/// opens a "Coming in a later sprint" page instead of crashing.
enum PlaceholderFeature {
  askGemini('Ask Gemini', Icons.auto_awesome_outlined),
  fundraisingCalculator('Fundraising Calculator', Icons.calculate_outlined),
  activityDashboard('Activity Dashboard', Icons.insights_outlined),
  investmentAssociations(
    'Investment Associations',
    Icons.account_balance_outlined,
  ),
  bookmarks('Bookmarks', Icons.bookmark_border_rounded),
  matches('Matches', Icons.handshake_outlined),
  explore('Explore', Icons.explore_outlined),
  search('Search', Icons.search_rounded),
  programs('Programs', Icons.school_outlined),
  notifications('Notifications', Icons.notifications_none_rounded);

  const PlaceholderFeature(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Opens this feature's placeholder page on top of the current screen.
  void open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ComingSoonScreen(feature: this)));
}
