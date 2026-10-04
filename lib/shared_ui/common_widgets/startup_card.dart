import 'package:flutter/material.dart';

import '../../models/startup_listing.dart';
import '../theme/app_theme.dart';
import 'listing_card_parts.dart';

/// A startup in an Explore or Hub list (Figma "V2 · 10 / 12b").
///
/// [onViewProfile] is given only to the cards that lead somewhere; tapping the
/// card or "View Profile" then calls it. Other cards do nothing when tapped.
class StartupCard extends StatelessWidget {
  const StartupCard({
    super.key,
    required this.listing,
    this.style = ListingStyle.explore,
    this.onViewProfile,
  });

  final StartupListing listing;
  final ListingStyle style;
  final VoidCallback? onViewProfile;

  @override
  Widget build(BuildContext context) {
    return ListingCardShell(
      onTap: onViewProfile,
      child: switch (style) {
        ListingStyle.match => _matchBody(),
        _ => _body(),
      },
    );
  }

  Widget _body() {
    final hub = style == ListingStyle.hub;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InitialsBadge(initials: listing.initials, size: 44),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.name, style: AppText.itemTitle),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    listing.tagline,
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hub) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    LocationLabel(listing.city),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (!hub) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              MetaPill(listing.sectorStage),
              const SizedBox(width: 6),
              LocationLabel(listing.city),
            ],
          ),
        ],
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
              initials: listing.initials,
              size: 44,
              circle: true,
              background: AppColors.gold100,
              foreground: AppColors.gold700,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.name, style: AppText.itemTitle),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${listing.sectorStage} · ${listing.city}',
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (listing.matchPercent != null) ...[
              const SizedBox(width: AppSpacing.sm),
              MatchChip(listing.matchPercent!),
            ],
          ],
        ),
        if (listing.matchReason != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(listing.matchReason!, style: AppText.caption),
        ],
        const SizedBox(height: 10),
        ListingFooter(onViewProfile: onViewProfile),
      ],
    );
  }
}
