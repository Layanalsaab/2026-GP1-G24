import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../models/investor_profile.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/cards/charts.dart';
import '../../../shared_ui/widgets/cards/profile_blocks.dart';
import '../view_models/startup_profile_view_model.dart';

/// The content of the selected tab of the startup profile (prototype
/// `.mpanes`: padding 16 16 28, cards 12 apart).
class StartupProfilePane extends StatelessWidget {
  const StartupProfilePane({
    super.key,
    required this.viewModel,
    required this.onOpenInvestor,
  });

  final StartupProfileViewModel viewModel;

  /// Opens an associated investor's profile.
  final ValueChanged<InvestorProfile> onOpenInvestor;

  @override
  Widget build(BuildContext context) {
    final cards = switch (viewModel.tab) {
      0 => _overview(),
      1 => _business(),
      2 => _team(),
      _ => _financials(),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            cards[i],
          ],
        ],
      ),
    );
  }

  List<Widget> _overview() {
    final s = viewModel.startup;
    return [
      if (s.description.trim().isNotEmpty)
        ProfileCard(
          icon: AppIcons.info,
          title: ProfileStrings.about,
          child: ProfileText(s.description.trim()),
        ),
      if (viewModel.lookingFor.isNotEmpty)
        ProfileCard(
          icon: AppIcons.target,
          title: ProfileStrings.lookingFor,
          tone: ProfileIconTone.gold,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final t in viewModel.lookingFor) _LookingPill(t)],
          ),
        ),
      if (s.problem.trim().isNotEmpty)
        ProfileCard(
          icon: AppIcons.warn,
          title: ProfileStrings.theProblem,
          tone: ProfileIconTone.red,
          child: ProfileText(s.problem.trim()),
        ),
      if (s.solution.trim().isNotEmpty)
        ProfileCard(
          icon: AppIcons.bulb,
          title: ProfileStrings.ourSolution,
          child: ProfileText(s.solution.trim()),
        ),
    ];
  }

  List<Widget> _business() {
    final s = viewModel.startup;
    if (!viewModel.hasBusiness) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            ProfileStrings.noBusinessDetails,
            textAlign: TextAlign.center,
            style: AppText.sans(size: 14, color: AppColors.metaText),
          ),
        ),
      ];
    }
    return [
      if (s.customers.trim().isNotEmpty)
        ProfileCard(
          icon: AppIcons.people,
          title: ProfileStrings.targetCustomers,
          child: ProfileText(s.customers.trim()),
        ),
      if (s.advantage.trim().isNotEmpty)
        ProfileCard(
          icon: AppIcons.star,
          title: ProfileStrings.different,
          tone: ProfileIconTone.gold,
          child: ProfileText(s.advantage.trim()),
        ),
      if (viewModel.hasMarket)
        ProfileCard(
          icon: AppIcons.search,
          title: ProfileStrings.marketSize,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarketCircles(
                tam: viewModel.tam,
                sam: viewModel.sam,
                som: viewModel.som,
              ),
              const SizedBox(height: 8),
              Text(
                ProfileStrings.yearlyRevenue,
                style: AppText.sans(size: 12, color: AppColors.grey),
              ),
            ],
          ),
        ),
      if (s.growth.trim().isNotEmpty)
        ProfileCard(
          icon: AppIcons.trend,
          title: ProfileStrings.expectedGrowth,
          child: ProfileText(s.growth.trim()),
        ),
    ];
  }

  List<Widget> _team() {
    final s = viewModel.startup;
    final founder = viewModel.founderName;
    if (!viewModel.hasTeamContent && viewModel.associated.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            ProfileStrings.noTeamDetails,
            textAlign: TextAlign.center,
            style: AppText.sans(size: 14, color: AppColors.metaText),
          ),
        ),
      ];
    }
    return [
      if (viewModel.hasTeamContent)
        ProfileCard(
          icon: AppIcons.people,
          title: ProfileStrings.team,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (founder != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      TileAvatar(
                        initials: appInitials(founder),
                        size: 26,
                        fontSize: 10,
                        round: true,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            text: '${ProfileStrings.foundedBy} ',
                            style: AppText.sans(
                              size: 14,
                              color: AppColors.grey,
                            ),
                            children: [
                              TextSpan(
                                text: founder,
                                style: AppText.sans(
                                  size: 14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              for (final m in s.team) ...[
                const SizedBox(height: 10),
                _MemberCard(
                  initials: m.initials,
                  name: m.name,
                  meta: m.meta,
                  bio: m.bio,
                ),
              ],
            ],
          ),
        ),
      if (viewModel.associated.isNotEmpty)
        ProfileCard(
          icon: AppIcons.workOut,
          title: ProfileStrings.associatedInvestors,
          tone: ProfileIconTone.gold,
          child: Column(
            children: [
              for (final i in viewModel.associated)
                ListRow.card(
                  leading: TileAvatar(
                    initials: i.initials,
                    tone: TileTone.gold,
                    size: 38,
                    fontSize: 13,
                    round: true,
                  ),
                  title: i.name,
                  subtitle: '${i.title} · ${i.city}',
                  onTap: () => onOpenInvestor(i),
                ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _financials() => [
    if (viewModel.financials.isNotEmpty)
      ProfileCard(
        icon: AppIcons.wallet,
        title: ProfileStrings.fundingAndFinancials,
        tone: ProfileIconTone.gold,
        child: KeyValueGrid(items: viewModel.financials),
      ),
    if (viewModel.hasRevenue)
      ProfileCard(
        icon: AppIcons.trend,
        title: ProfileStrings.expectedRevenue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevenueBars(
              values: viewModel.revenueValues,
              labels: viewModel.revenueLabels,
              valueLabels: viewModel.revenueValueLabels,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                ProfileStrings.sarPerYear,
                style: AppText.sans(size: 12, color: AppColors.grey),
              ),
            ),
          ],
        ),
      ),
  ];
}

/// A "Looking for" tag: cream pill, 1 px border, 32 high, 13.5/600.
class _LookingPill extends StatelessWidget {
  const _LookingPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      label,
      style: AppText.sans(size: 13.5, weight: FontWeight.w600),
    ),
  );
}

/// A team member row (prototype `.mem`): white, border `#EDEAE3`, radius 14,
/// moss tile 40, name 15/700, meta 12 grey, bio 13.
class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.initials,
    required this.name,
    required this.meta,
    required this.bio,
  });

  final String initials;
  final String name;
  final String meta;
  final String bio;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.dividerSoft),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TileAvatar(initials: initials, size: 40, radius: 12, fontSize: 13),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppText.sans(size: 15, weight: FontWeight.w700),
              ),
              Text(meta, style: AppText.sans(size: 12, color: AppColors.grey)),
              if (bio.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    bio.trim(),
                    style: AppText.sans(
                      size: 13,
                      height: 18,
                      color: AppColors.paragraph,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
