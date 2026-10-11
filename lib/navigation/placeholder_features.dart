import 'package:flutter/material.dart';

/// Features planned for later sprints. They are visual placeholders only:
/// nothing in the app opens them, shows a message for them or reacts to a tap.
/// Labels follow the Figma side menu ("V2 · 41 · Menu").
enum PlaceholderFeature {
  askGemini('Ask Gemini', Icons.auto_awesome_outlined),
  fundraisingCalculator('Fundraising Calculator', Icons.calculate_outlined),
  activityDashboard('Activity Dashboard', Icons.insights_outlined),
  investmentAssociations('Associations', Icons.link_rounded),
  bookmarks('Bookmarks', Icons.bookmark_border_rounded),
  notifications('Notifications', Icons.notifications_none_rounded),
  requests('My Requests', Icons.send_outlined),
  expressionsOfInterest('Expressions of Interest', Icons.inbox_outlined),
  investorWallet('Investment Wallet', Icons.account_balance_wallet_outlined),
  shareStartup('Share startup', Icons.ios_share_rounded);

  const PlaceholderFeature(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// An icon (bookmark, bell...) of a placeholder [feature]. It is inert: no
/// tap, no ripple, no navigation, no feedback. It keeps a screen-reader label
/// and the same [size] box as a real button, so the layout matches Figma.
class PlaceholderIcon extends StatelessWidget {
  const PlaceholderIcon({
    super.key,
    required this.feature,
    required this.child,
    this.size = 44,
  });

  final PlaceholderFeature feature;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: feature.label,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}
