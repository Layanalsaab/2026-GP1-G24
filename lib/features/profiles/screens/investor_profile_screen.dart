import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/explore_strings.dart';
import '../../../app_constants/startup_strings.dart';
import '../../../data_access/mock_data/mock_startups.dart';
import '../../../models/investor_profile.dart';
import '../../../models/startup_listing.dart';
import '../../../shared_ui/common_widgets/profile_banner.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../../startups/screens/startup_profile_screen.dart';

/// What a founder sees when opening an investor (Figma "Profile — Investor"):
/// the green banner with the avatar over it, name, the "Investor" role,
/// bio, city, sector chips and the association count, then the investment
/// preferences and the Investment associations.
///
/// It is someone else's profile, so there is no "Edit profile" button. Email,
/// phone and "Joined ..." are left out: they are not known for sample
/// investors, and rows without data are never shown.
///
/// Design phase: sending a request is a visual placeholder (not tappable, no
/// feedback). The associations come from the sample startups.
class InvestorProfileScreen extends StatelessWidget {
  const InvestorProfileScreen({super.key, required this.investor});

  final InvestorProfile investor;

  static const _bannerHeight = 120.0;
  static const _avatarSize = 96.0;

  /// The sample startups this investor is associated with.
  List<StartupListing> get _associations => [
    for (final listing in MockStartups.forYou)
      if (listing.associations.any((a) => a.name == investor.name)) listing,
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;
    final bannerHeight = _bannerHeight + topInset;
    final associations = _associations;
    final bio = investor.profileBio;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: ListView(
          padding: EdgeInsets.only(bottom: 24 + bottom),
          children: [
            SizedBox(
              height: bannerHeight + _avatarSize / 2 + 8,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ProfileBanner(height: bannerHeight),
                  ),
                  Positioned(
                    top: topInset + 8,
                    left: 12,
                    child: Tooltip(
                      message: 'Back',
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.arrow_back,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: bannerHeight - _avatarSize / 2,
                    left: 12,
                    child: Container(
                      width: _avatarSize,
                      height: _avatarSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.moss600,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cream, width: 4),
                      ),
                      child: Text(
                        investor.initials,
                        style: AppText.sans(
                          size: _avatarSize / 3,
                          color: Colors.white,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investor.name,
                    style: AppText.sans(
                      size: 22,
                      color: AppColors.ink,
                      weight: FontWeight.w700,
                      height: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Investor',
                      style: AppText.sans(
                        size: 13,
                        color: AppColors.gold700,
                        weight: FontWeight.w500,
                        height: 18,
                      ),
                    ),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      bio,
                      style: AppText.sans(
                        size: 15,
                        color: AppColors.ink,
                        height: 22,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (investor.city.isNotEmpty)
                        _MetaItem(
                          icon: Icons.location_on_outlined,
                          text: investor.city,
                        ),
                      if (investor.title.isNotEmpty)
                        _MetaItem(
                          icon: Icons.work_outline_rounded,
                          text: investor.title,
                        ),
                    ],
                  ),
                  if (investor.sectors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final sector in investor.sectors)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.moss100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              sector,
                              style: AppText.sans(
                                size: 13,
                                color: AppColors.green,
                                weight: FontWeight.w500,
                                height: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${associations.length}',
                          style: AppText.sans(
                            size: 15,
                            color: AppColors.ink,
                            weight: FontWeight.w700,
                            height: 22,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' ${AccountStrings.associationsCount(associations.length)}',
                          style: AppText.sans(
                            size: 15,
                            color: AppColors.grey,
                            height: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SendRequestButton(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(height: 8, color: AppColors.mutedFill),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: _Section(
                title: ExploreStrings.investmentPreferences,
                child: Column(
                  children: [
                    _Row(
                      ExploreStrings.stage,
                      investor.stageRange,
                      gold: true,
                    ),
                    const SizedBox(height: 10),
                    _Row(
                      ExploreStrings.sectorsLabel,
                      investor.sectors.join(', '),
                    ),
                    const SizedBox(height: 10),
                    _Row(
                      ExploreStrings.ticketSize,
                      investor.ticketRange,
                      ink: true,
                    ),
                    const SizedBox(height: 10),
                    _Row(
                      ExploreStrings.locations,
                      investor.locations.join(', '),
                      ink: true,
                    ),
                  ],
                ),
              ),
            ),
            if (associations.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(height: 8, color: AppColors.mutedFill),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: _Section(
                  title: StartupStrings.associationsTitle,
                  child: Column(
                    children: [
                      for (final listing in associations)
                        _AssociationRow(listing: listing),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.grey),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppText.sans(size: 14, color: AppColors.grey, height: 20),
          ),
        ),
      ],
    );
  }
}

/// Inert "Send request": requests aren't built yet.
class _SendRequestButton extends StatelessWidget {
  const _SendRequestButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.moss600,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          svgIcon('st_send.svg', size: 18),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              ExploreStrings.sendRequest,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.button,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.sans(
            size: 16,
            color: AppColors.ink,
            weight: FontWeight.w700,
            height: 24,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

/// A grey label with its value: Stage in dark gold, Sectors in green, the
/// rest in ink.
class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.gold = false, this.ink = false});

  final String label;
  final String value;
  final bool gold;
  final bool ink;

  @override
  Widget build(BuildContext context) {
    final color = ink
        ? AppColors.ink
        : gold
        ? AppColors.tagGoldText
        : AppColors.moss600;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: AppText.sans(size: 13, color: AppColors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppText.sans(
              size: 14,
              color: color,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// One associated startup: initials square, name, "Sector · City" and a
/// chevron. Tapping opens the startup's profile.
class _AssociationRow extends StatelessWidget {
  const _AssociationRow({required this.listing});

  final StartupListing listing;

  @override
  Widget build(BuildContext context) {
    final subtitle = AppText.sans(size: 13, color: AppColors.grey, height: 18);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StartupProfileScreen(
                startup: listing.startup,
                founderName: MockStartups.founderNameOf(listing.startup),
                associations: listing.associations,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.moss100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    listing.initials,
                    style: AppText.sans(
                      size: 13,
                      color: AppColors.moss600,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(
                          size: 15,
                          color: AppColors.ink,
                          weight: FontWeight.w700,
                          height: 22,
                        ),
                      ),
                      Text(
                        '${listing.sectorLabel} · ${listing.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: subtitle,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
