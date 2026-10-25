import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../helpers/formatters.dart';
import '../../../models/investor_profile.dart';
import '../../../models/list_entries.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/cards/box_grid.dart';
import '../../../shared_ui/widgets/cards/charts.dart';
import '../../startups/widgets/manage_card.dart';
import '../../startups/widgets/manage_rounds_tab.dart';
import '../../startups/widgets/role_tag.dart';
import '../../startups/widgets/stat_tile.dart';
import '../../startups/widgets/startup_ask.dart';
import '../view_models/startup_profile_view_model.dart';

/// The content of the selected tab of the startup page, in the same bigger
/// card sizes as Manage (card padding 18, titles 19 / 26 bold, body 16).
/// Tabs: Overview, Business, Team, Funding. Cards sit 12 px apart.
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
      _ => _funding(),
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

  // ---------------------------------------------------------------- tiles

  /// Raising (dark when a round is open) and Valuation, side by side.
  Widget _raisingAndValuation() {
    final round = viewModel.openRound;
    final valuation = viewModel.startup.valuation;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatTile(
              dark: round != null,
              label: 'Raising',
              value: round == null
                  ? 'Not raising'
                  : Formatters.sarShort(round.amount),
              sub: round == null
                  ? 'No open round'
                  : 'Round ${round.number} · Open',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatTile(
              label: 'Valuation',
              value: valuation == null || valuation <= 0
                  ? '—'
                  : Formatters.sarShort(valuation),
              sub: 'Current',
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- Overview

  List<Widget> _overview() {
    final s = viewModel.startup;
    final facts = <(String, String)>[
      ('Website', viewModel.website),
      ('Sector', s.sectorLabel),
      ('Stage', s.stageLabel),
      ('Commerce model', s.businessModelLabel),
      ('Headquarters', s.location.label),
      ('Founded', s.foundedYear?.toString() ?? ''),
    ].where((f) => f.$2.trim().isNotEmpty).toList();
    final funding = StartupAsk.funding(s);
    final partnership = StartupAsk.partnership(s);
    final support = StartupAsk.support(s);
    return [
      _raisingAndValuation(),
      _SectionCard(
        icon: AppIcons.info,
        title: ProfileStrings.about,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (s.briefDescription.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: facts.isEmpty ? 0 : 14),
                child: Text(
                  s.briefDescription,
                  style: AppText.sans(
                    size: 16,
                    height: 24,
                    color: AppColors.ink,
                  ),
                ),
              ),
            if (facts.isNotEmpty)
              BoxGrid(items: facts, accent: const {'Website'}),
          ],
        ),
      ),
      if (funding || partnership || support.isNotEmpty)
        _SectionCard(
          icon: AppIcons.target,
          title: ProfileStrings.lookingFor,
          tone: _Tone.gold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (funding)
                AskRow(
                  icon: AppIcons.wallet,
                  title: 'Funding',
                  selected: true,
                  showStatus: false,
                  detail: StartupAsk.fundingDetail(s),
                ),
              if (partnership) ...[
                if (funding) const SizedBox(height: 10),
                const AskRow(
                  icon: AppIcons.people,
                  title: 'Partnership',
                  selected: true,
                  showStatus: false,
                  detail: 'Open to partnerships',
                ),
              ],
              if (support.isNotEmpty) ...[
                if (funding || partnership) const SizedBox(height: 10),
                AskRow(
                  icon: AppIcons.bulb,
                  title: 'Support',
                  selected: true,
                  showStatus: false,
                  detail: support.join(', '),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  // ------------------------------------------------------------- Business

  List<Widget> _business() {
    final s = viewModel.startup;
    final hasDescription =
        s.problem.trim().isNotEmpty ||
        s.solution.trim().isNotEmpty ||
        s.advantage.trim().isNotEmpty;
    final hasMarket = s.customers.trim().isNotEmpty || viewModel.hasMarket;
    if (!hasDescription && !hasMarket && s.growth.trim().isEmpty) {
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
      if (hasDescription)
        _SectionCard(
          icon: AppIcons.bulb,
          title: 'Startup description',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s.problem.trim().isNotEmpty)
                _Answer(ProfileStrings.theProblem, s.problem),
              if (s.solution.trim().isNotEmpty)
                _Answer(ProfileStrings.ourSolution, s.solution),
              if (s.advantage.trim().isNotEmpty)
                _Answer(ProfileStrings.different, s.advantage),
            ],
          ),
        ),
      if (hasMarket)
        _SectionCard(
          icon: AppIcons.search,
          title: 'Target market',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s.customers.trim().isNotEmpty)
                _Answer(ProfileStrings.targetCustomers, s.customers),
              if (viewModel.hasMarket)
                _Answer(
                  ProfileStrings.marketSize,
                  viewModel.targetMarketShort,
                  big: true,
                  caption: ProfileStrings.yearlyRevenue,
                ),
            ],
          ),
        ),
      if (s.growth.trim().isNotEmpty)
        _SectionCard(
          icon: AppIcons.trend,
          title: 'Growth plan',
          tone: _Tone.gold,
          child: _Answer(ProfileStrings.expectedGrowth, s.growth),
        ),
    ];
  }

  // ----------------------------------------------------------------- Team

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
        _SectionCard(
          icon: AppIcons.people,
          title: ProfileStrings.team,
          child: Column(
            children: [
              if (founder != null)
                _PersonRow(
                  initials: appInitials(founder),
                  name: founder,
                  role: StartupRole.founder,
                  line: '',
                ),
              for (final m in s.team)
                _PersonRow(
                  initials: m.initials,
                  name: m.name,
                  role: StartupRole.member,
                  line: m.meta,
                  extra: m.bio,
                ),
            ],
          ),
        ),
      if (viewModel.associated.isNotEmpty)
        _SectionCard(
          icon: AppIcons.workOut,
          title: ProfileStrings.associatedInvestors,
          tone: _Tone.gold,
          child: Column(
            children: [
              for (final i in viewModel.associated)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onOpenInvestor(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        TileAvatar(
                          initials: i.initials,
                          tone: TileTone.gold,
                          size: 46,
                          fontSize: 15,
                          round: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i.name,
                                style: AppText.sans(
                                  size: 16.5,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${i.title} · ${i.city}',
                                style: AppText.sans(
                                  size: 14,
                                  height: 20,
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const AppIcon.filled(
                          AppIcons.chevRight,
                          size: 22,
                          color: AppColors.hint,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  // -------------------------------------------------------------- Funding

  List<Widget> _funding() {
    final s = viewModel.startup;
    final capital = s.capital;
    return [
      _raisingAndValuation(),
      if (capital != null && capital > 0)
        StatTile(
          label: 'Capital',
          value: Formatters.sarShort(capital),
          sub: 'Available now',
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Funding rounds',
            style: AppText.sans(size: 19, height: 26, weight: FontWeight.w700),
          ),
          Text(
            'All amounts in SAR',
            style: AppText.sans(size: 13, color: const Color(0xFF8C918D)),
          ),
          const SizedBox(height: 12),
          // The same table as Manage, read only (sample rounds).
          RoundsTable(rounds: viewModel.roundsNewestFirst),
        ],
      ),
      if (viewModel.hasRevenue)
        _SectionCard(
          icon: AppIcons.trend,
          title: ProfileStrings.expectedRevenue,
          trailing: Text(
            ProfileStrings.sarPerYear,
            style: AppText.sans(size: 13, color: AppColors.grey),
          ),
          child: RevenueBars(
            values: viewModel.revenueValues,
            labels: viewModel.revenueLabels,
            valueLabels: viewModel.revenueValueLabels,
          ),
        ),
    ];
  }
}

enum _Tone { moss, gold }

/// A white card with a small icon tile and a 19 / 26 bold title (the Manage
/// card: padding 18, radius 20).
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.tone = _Tone.moss,
    this.trailing,
  });

  final String icon;
  final String title;
  final Widget child;
  final _Tone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final gold = tone == _Tone.gold;
    return ManageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: gold ? AppColors.tagGoldFill : AppColors.moss100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: AppIcon.filled(
                    icon,
                    size: 18,
                    color: gold ? AppColors.tagGoldText : AppColors.moss600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppText.sans(
                      size: 19,
                      height: 26,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// A label with a 4 x 14 gold bar on the left (14.5 px, weight 700, moss
/// green) over its answer (16 px black). [big] shows the answer as a large
/// green number with a [caption].
class _Answer extends StatelessWidget {
  const _Answer(this.label, this.answer, {this.big = false, this.caption});

  final String label;
  final String answer;
  final bool big;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: AppText.sans(
                    size: 14.5,
                    weight: FontWeight.w700,
                    color: AppColors.moss600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (big)
            Text(
              answer,
              style: AppText.sans(
                size: 28,
                height: 34,
                weight: FontWeight.w700,
                color: AppColors.green,
              ),
            )
          else
            Text(
              answer.trim(),
              style: AppText.sans(size: 16, height: 24, color: AppColors.ink),
            ),
          if (caption != null)
            Text(
              caption!,
              style: AppText.sans(size: 13, color: AppColors.grey),
            ),
        ],
      ),
    );
  }
}

/// One person of the Team card: a 46 px round avatar, the name with the role
/// tag (Founder gold / Co-founder blue / Member green), the role line and
/// what they contribute.
class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.initials,
    required this.name,
    required this.role,
    required this.line,
    this.extra = '',
  });

  final String initials;
  final String name;
  final StartupRole role;
  final String line;
  final String extra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TileAvatar(initials: initials, size: 46, fontSize: 15, round: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(
                          size: 16.5,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoleTag(role),
                  ],
                ),
                if (line.isNotEmpty)
                  Text(
                    line,
                    style: AppText.sans(
                      size: 14,
                      height: 20,
                      color: AppColors.grey,
                    ),
                  ),
                if (extra.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      extra.trim(),
                      style: AppText.sans(
                        size: 14,
                        height: 20,
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
}
