import 'package:flutter/material.dart';

import '../../app_constants/explore_strings.dart';
import '../../models/investor_profile.dart';
import '../theme/app_theme.dart';
import 'listing_card_parts.dart';
import 'svg_asset.dart';

/// An investor in an Explore or Hub list (Figma "V2 · 09b / 12").
///
/// [onViewProfile] is given only to the cards that lead somewhere; tapping the
/// card or "View Profile" then calls it. Other cards do nothing when tapped.
class InvestorCard extends StatelessWidget {
  const InvestorCard({
    super.key,
    required this.investor,
    this.style = ListingStyle.explore,
    this.onViewProfile,
  });

  final InvestorProfile investor;
  final ListingStyle style;
  final VoidCallback? onViewProfile;

  @override
  Widget build(BuildContext context) {
    return ListingCardShell(
      onTap: onViewProfile,
      radius: style == ListingStyle.explore ? 16 : 14,
      padding: style == ListingStyle.explore
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: switch (style) {
        ListingStyle.explore => _exploreBody(),
        ListingStyle.hub => _hubBody(),
        ListingStyle.match => _matchBody(),
      },
    );
  }

  Widget _exploreBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InitialsBadge(initials: investor.initials, size: 48, circle: true),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investor.name,
                    style: AppText.sans(
                      size: 16,
                      color: AppColors.ink,
                      weight: FontWeight.w600,
                      height: 20,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    investor.headline,
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Design only: bookmarking isn't connected yet.
            SizedBox(
              width: 36,
              height: 36,
              child: Center(child: svgIcon('bookmark.svg', size: 20)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            LocationLabel(investor.city),
            const SizedBox(width: AppSpacing.sm),
            MetaPill(
              ExploreStrings.invests(investor.stageRange),
              background: AppColors.gold100,
              foreground: AppColors.gold700,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListingFooter(onViewProfile: onViewProfile),
      ],
    );
  }

  Widget _hubBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InitialsBadge(initials: investor.initials, size: 44, circle: true),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(investor.name, style: AppText.itemTitle),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    investor.headline,
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  LocationLabel(investor.city),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListingFooter(onViewProfile: onViewProfile),
      ],
    );
  }

  Widget _matchBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InitialsBadge(
              initials: investor.initials,
              size: 48,
              circle: true,
              background: AppColors.gold100,
              foreground: AppColors.gold700,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investor.name,
                    style: AppText.sans(
                      size: 16,
                      color: AppColors.ink,
                      weight: FontWeight.w600,
                      height: 20,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    investor.headline,
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (investor.matchPercent != null) ...[
              const SizedBox(width: AppSpacing.sm),
              MatchChip(investor.matchPercent!),
            ],
          ],
        ),
        if (investor.matchReason != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(investor.matchReason!, style: AppText.caption),
        ],
        const SizedBox(height: 10),
        ListingFooter(onViewProfile: onViewProfile),
      ],
    );
  }
}
