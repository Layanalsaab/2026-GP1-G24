import 'package:flutter/material.dart';

import '../../app_constants/explore_strings.dart';
import '../../models/startup_listing.dart';
import '../theme/app_theme.dart';
import 'listing_card_parts.dart';

/// A startup in an Explore or Hub list (Figma "V2 · 10 / 12b / 11 / 12c").
///
/// [onViewProfile] is given only to the cards that lead somewhere; tapping the
/// card or "View Profile" then calls it. Other cards do nothing when tapped.
/// [actionLabel] is the second button's text ("Send Request" by default,
/// "Express Interest" for seekers); that button does nothing yet.
class StartupCard extends StatelessWidget {
  const StartupCard({
    super.key,
    required this.listing,
    this.style = ListingStyle.explore,
    this.onViewProfile,
    this.actionLabel = ExploreStrings.sendRequest,
  });

  final StartupListing listing;
  final ListingStyle style;
  final VoidCallback? onViewProfile;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return ListingCardShell(
      onTap: onViewProfile,
      radius: style == ListingStyle.seeker ? 16 : 14,
      child: switch (style) {
        ListingStyle.match => _matchBody(),
        ListingStyle.seeker => _seekerBody(),
        _ => _body(),
      },
    );
  }

  ListingFooter _footer() =>
      ListingFooter(onViewProfile: onViewProfile, actionLabel: actionLabel);

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
        _footer(),
      ],
    );
  }

  /// The seeker's Explore card: separate sector and stage chips.
  Widget _seekerBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InitialsBadge(
              initials: listing.initials,
              size: 42,
              radius: 11,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.name,
                    style: AppText.sans(
                      size: 15,
                      color: AppColors.ink,
                      weight: FontWeight.w600,
                      height: 20,
                    ),
                  ),
                  Text(
                    listing.tagline,
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            MetaPill(listing.sectorLabel),
            if (listing.stageLabel.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              MetaPill(
                listing.stageLabel,
                background: AppColors.mutedFill,
                foreground: AppColors.grey,
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            LocationLabel(listing.city),
          ],
        ),
        const SizedBox(height: 10),
        _footer(),
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
        _footer(),
      ],
    );
  }
}
