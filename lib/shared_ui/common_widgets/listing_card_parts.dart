import 'package:flutter/material.dart';

import '../../app_constants/explore_strings.dart';
import '../theme/app_theme.dart';
import 'svg_asset.dart';

/// The look of a card in the Explore and Hub lists.
enum ListingStyle {
  /// Explore > For You / Trending: header, meta row and buttons.
  explore,

  /// Hub: the location sits under the text; no bookmark.
  hub,

  /// Explore > Matches: "82% match" chip and a "Why" line.
  match,

  /// The seeker's Explore (Figma "V2 · 11"): split sector / stage chips and
  /// an "Express Interest" button.
  seeker,
}

/// White rounded card (Figma list cards). Tapping works only when [onTap] is
/// given, so a card with no destination yet does nothing.
class ListingCardShell extends StatelessWidget {
  const ListingCardShell({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1C1F1C),
            offset: Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: shape,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Ink(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: shape,
              border: Border.all(color: AppColors.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Initials in a rounded square or a circle (a logo or avatar placeholder).
class InitialsBadge extends StatelessWidget {
  const InitialsBadge({
    super.key,
    required this.initials,
    required this.size,
    this.circle = false,
    this.background = AppColors.moss100,
    this.foreground = AppColors.moss600,
    this.radius = 12,
    this.fontSize,
  });

  final String initials;
  final double size;
  final bool circle;
  final Color background;
  final Color foreground;
  final double radius;

  /// Defaults to 15 for large badges and 14 for small ones.
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
      child: Text(
        initials,
        style: AppText.sans(
          size: fontSize ?? (size >= 48 ? 15 : 14),
          color: foreground,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Pin icon followed by a city name.
class LocationLabel extends StatelessWidget {
  const LocationLabel(this.city, {super.key});

  final String city;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        svgIcon('pin.svg', size: 14),
        const SizedBox(width: 4),
        Text(city, style: AppText.caption),
      ],
    );
  }
}

/// A small tinted pill (sector · stage, "Invests: ...").
class MetaPill extends StatelessWidget {
  const MetaPill(
    this.text, {
    super.key,
    this.background = AppColors.moss100,
    this.foreground = AppColors.moss600,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.sans(
            size: 11,
            color: foreground,
            weight: FontWeight.w500,
            height: 16,
          ),
        ),
      ),
    );
  }
}

/// "82% match" pill on the Matches tab.
class MatchChip extends StatelessWidget {
  const MatchChip(this.percent, {super.key});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold100,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.gold700),
          const SizedBox(width: 4),
          Text(
            ExploreStrings.matchPercent(percent),
            style: AppText.sans(
              size: 11,
              color: AppColors.gold700,
              weight: FontWeight.w600,
              height: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// "View Profile" and "Send Request" buttons at the bottom of a card.
/// A button with no callback is shown but does nothing.
class ListingFooter extends StatelessWidget {
  const ListingFooter({
    super.key,
    this.onViewProfile,
    this.onSendRequest,
    this.actionLabel = ExploreStrings.sendRequest,
  });

  final VoidCallback? onViewProfile;
  final VoidCallback? onSendRequest;

  /// The second button's text: "Send Request", or "Express Interest" for
  /// seekers.
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FooterButton(
            label: ExploreStrings.viewProfile,
            filled: false,
            onTap: onViewProfile,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _FooterButton(
            label: actionLabel,
            filled: true,
            onTap: onSendRequest,
          ),
        ),
      ],
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(10);
    // A button with no action still catches the tap, so it never falls through
    // to the card behind it (which may open a profile).
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () {},
      child: Material(
        color: filled ? AppColors.moss600 : Colors.transparent,
        borderRadius: shape,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Ink(
            height: 36,
            decoration: BoxDecoration(
              borderRadius: shape,
              border: filled ? null : Border.all(color: AppColors.moss600),
            ),
            child: Center(
              child: Text(
                label,
                style: AppText.sans(
                  size: 13,
                  color: filled ? Colors.white : AppColors.moss600,
                  weight: FontWeight.w600,
                  height: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
