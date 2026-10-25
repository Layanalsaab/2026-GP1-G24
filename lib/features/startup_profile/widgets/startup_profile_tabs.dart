import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/formatters.dart';
import '../../../helpers/startup_finance.dart';
import '../../../models/investor_profile.dart';
import '../../../models/team_member.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/cards/box_grid.dart';
import '../../../shared_ui/widgets/cards/charts.dart';
import '../../../shared_ui/widgets/forms/photo_pickers.dart'
    show DashedBorderPainter;
import '../../profiles/screens/account_screen.dart';
import '../../startups/widgets/manage_card.dart';
import '../../startups/widgets/manage_rounds_tab.dart';
import '../../startups/widgets/role_tag.dart';
import '../../startups/widgets/startup_ask.dart';
import '../screens/team_member_profile_screen.dart';
import '../view_models/startup_profile_view_model.dart';

/// The content of the selected tab of the startup page. Tabs: Overview,
/// Business, Team, Funding. White cards (radius 20, padding 18, 16 px side
/// margins), 12 px apart; question blocks inside a card are separated by a
/// soft 1 px divider.
class StartupProfilePane extends StatelessWidget {
  const StartupProfilePane({
    super.key,
    required this.viewModel,
    required this.onOpenInvestor,
  });

  final StartupProfileViewModel viewModel;

  /// Opens an associated investor's profile.
  final ValueChanged<InvestorProfile> onOpenInvestor;

  static const _divider = Color(0xFFEDEAE3);

  @override
  Widget build(BuildContext context) {
    final cards = switch (viewModel.tab) {
      0 => _overview(),
      1 => _business(),
      2 => _team(context),
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
    // Funding shows only while the startup is raising.
    final raising = viewModel.currentRound;
    final partnership = StartupAsk.partnership(s);
    final support = StartupAsk.supportSelected(s);
    final rows = <Widget>[
      if (raising != null)
        _LookRow(
          kind: _LookKind.funding,
          title: 'Funding',
          value: 'Raising ${Formatters.sar(raising.goal)}',
        ),
      if (partnership)
        _LookRow(
          kind: _LookKind.partnership,
          title: 'Partnership',
          value: StartupAsk.partners(s).join(', '),
        ),
      if (support)
        _LookRow(
          kind: _LookKind.support,
          title: 'Support',
          value: StartupAsk.support(s).join(', '),
        ),
    ];
    return [
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
              BoxGrid(items: facts, accent: const {'Website'}, page: true),
          ],
        ),
      ),
      if (rows.isNotEmpty)
        _SectionCard(
          icon: AppIcons.target,
          title: ProfileStrings.lookingFor,
          tone: _Tone.gold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                rows[i],
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
    final hasModel = s.businessModelText.trim().isNotEmpty;
    if (!hasDescription && !hasMarket && !hasModel) {
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
          child: _Blocks([
            if (s.problem.trim().isNotEmpty)
              _Answer(ProfileStrings.theProblem, s.problem),
            if (s.solution.trim().isNotEmpty)
              _Answer(ProfileStrings.ourSolution, s.solution),
            if (s.advantage.trim().isNotEmpty)
              _Answer(ProfileStrings.different, s.advantage),
          ]),
        ),
      if (hasMarket)
        _SectionCard(
          icon: AppIcons.search,
          title: 'Target market',
          child: _Blocks([
            if (s.customers.trim().isNotEmpty)
              _Answer(ProfileStrings.targetCustomers, s.customers),
            if (viewModel.hasMarket)
              _Answer(
                ProfileStrings.marketSize,
                viewModel.targetMarketShort,
                big: true,
                caption: ProfileStrings.yearlyRevenue,
              ),
          ]),
        ),
      if (hasModel)
        _SectionCard(
          icon: AppIcons.wallet,
          title: 'Business model',
          tone: _Tone.gold,
          child: Text(
            s.businessModelText.trim(),
            style: AppText.sans(size: 16, height: 23, color: AppColors.ink),
          ),
        ),
    ];
  }

  // ----------------------------------------------------------------- Team

  /// Founder first, then the co-founders, then the members (each group in the
  /// order they were added). Invited people (no account yet) are hidden from
  /// everyone outside the team; the team previewing sees them, dashed.
  List<TeamMember> _people() {
    final s = viewModel.startup;
    final team = [...s.team];
    if (!team.any((m) => m.isFounder)) {
      final founder = viewModel.founderName;
      if (founder != null) {
        team.insert(
          0,
          TeamMember(
            name: founder,
            role: '',
            contribution: '',
            isFounder: true,
            uid: s.founderId,
          ),
        );
      }
    }
    int rank(TeamMember m) => m.isFounder ? 0 : (m.coFounder ? 1 : 2);
    final shown = [
      for (final m in team)
        if (!m.invited || m.isFounder || viewModel.isPreview) m,
    ];
    // A stable sort by rank.
    return [
      for (final r in [0, 1, 2])
        for (final m in shown)
          if (rank(m) == r) m,
    ];
  }

  List<Widget> _team(BuildContext context) {
    final people = _people();
    if (people.isEmpty && viewModel.associated.isEmpty) {
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
    final me = AppSession.instance.user?.uid;
    return [
      if (people.isNotEmpty)
        _SectionCard(
          icon: AppIcons.people,
          title: ProfileStrings.team,
          child: _Rows([
            for (final m in people)
              _PersonRow(
                member: m,
                isYou: me != null && m.uid == me,
                // Invited people (shown only to the team) are not tappable.
                onTap: m.invited && !m.isFounder
                    ? null
                    : () => _openPerson(context, m, me),
              ),
          ]),
        ),
      if (viewModel.associated.isNotEmpty)
        _SectionCard(
          icon: AppIcons.workOut,
          title: ProfileStrings.associatedInvestors,
          tone: _Tone.gold,
          child: _Rows([
            for (final i in viewModel.associated)
              _InvestorRow(investor: i, onTap: () => onOpenInvestor(i)),
          ]),
        ),
    ];
  }

  /// Opens a person's profile: mine opens my own profile.
  void _openPerson(BuildContext context, TeamMember m, String? me) {
    if (me != null && m.uid == me) {
      OwnProfileScreen.open(context);
      return;
    }
    TeamMemberProfileScreen.open(
      context,
      m,
      startupName: viewModel.startup.name,
    );
  }

  // -------------------------------------------------------------- Funding

  List<Widget> _funding() {
    final s = viewModel.startup;
    String amount(int? v) => v == null ? '—' : Formatters.sarShort(v);
    final key = <(String, String)>[
      ('Valuation', amount(s.valuation)),
      ('Available capital', amount(s.capital)),
      ('Revenue this year', amount(s.revenueThisYear)),
      ('Monthly burn', amount(s.monthlyBurn)),
      ('Runway', Runway.short(s.capital, s.monthlyBurn) ?? '—'),
    ];
    return [
      _CurrentRoundCard(round: viewModel.currentRound),
      _SectionCard(
        icon: AppIcons.trend,
        title: 'Key numbers',
        child: BoxGrid(items: key, page: true, fullWidthLast: true),
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
          RoundsTable(
            rounds: viewModel.roundsNewestFirst,
            emptyText: 'No funding rounds yet.',
            centerEmpty: true,
          ),
        ],
      ),
      if (viewModel.hasRevenue)
        _SectionCard(
          icon: AppIcons.trend,
          title: ProfileStrings.expectedRevenue,
          trailing: Text(
            ProfileStrings.sarPerYear,
            style: AppText.sans(
              size: 13,
              weight: FontWeight.w600,
              color: const Color(0xFF8C918D),
            ),
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

// ----------------------------------------------------------- Looking for

enum _LookKind { funding, partnership, support }

/// One chosen option of "Looking for": a dashed row with a gradient icon
/// tile, the title and its (minimal) value.
class _LookRow extends StatelessWidget {
  const _LookRow({
    required this.kind,
    required this.title,
    required this.value,
  });

  final _LookKind kind;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final (icon, colors) = switch (kind) {
      _LookKind.funding => (
        AppIcons.wallet,
        const [Color(0xFFD4AE55), Color(0xFFA9832C)],
      ),
      _LookKind.partnership => (
        AppIcons.workOut,
        const [Color(0xFF5B82BD), Color(0xFF2B4F80)],
      ),
      _LookKind.support => (
        AppIcons.people,
        const [Color(0xFF4F7D5A), Color(0xFF2F5D3A)],
      ),
    };
    return CustomPaint(
      painter: DashedBorderPainter(
        color: const Color(0xFFD9D6CF),
        radius: 14,
        strokeWidth: 1,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
              child: Center(
                child: AppIcon.filled(icon, size: 18, color: AppColors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.sans(size: 16, weight: FontWeight.w700),
                  ),
                  if (value.trim().isNotEmpty)
                    Text(
                      value,
                      style: AppText.sans(
                        size: 14,
                        height: 20,
                        color: const Color(0xFF4B544E),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ answers

/// A question with its answer: the label (13.5 semibold #6B726C) over the
/// answer (16 / 23 ink). [big] shows the answer as a large dark-green number
/// with a [caption].
class _Answer extends StatelessWidget {
  const _Answer(this.label, this.answer, {this.big = false, this.caption});

  final String label;
  final String answer;
  final bool big;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.sans(
            size: 13.5,
            weight: FontWeight.w600,
            color: const Color(0xFF6B726C),
          ),
        ),
        const SizedBox(height: 4),
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
            style: AppText.sans(size: 16, height: 23, color: AppColors.ink),
          ),
        if (caption != null)
          Text(caption!, style: AppText.sans(size: 13, color: AppColors.grey)),
      ],
    );
  }
}

/// Question blocks of one card, a 1 px soft divider between them.
class _Blocks extends StatelessWidget {
  const _Blocks(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(
                height: 1,
                thickness: 1,
                color: StartupProfilePane._divider,
              ),
            ),
          children[i],
        ],
      ],
    );
  }
}

// ----------------------------------------------------------------- rows

/// Rows of a card (people, investors): padding 12 0 between them, a soft
/// divider between rows and NO line above the first one. The first row has
/// no top padding, so the space under the title is the card's 14 px.
class _Rows extends StatelessWidget {
  const _Rows(this.rows);

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              thickness: 1,
              color: StartupProfilePane._divider,
            ),
          Padding(
            padding: EdgeInsets.only(
              top: i == 0 ? 0 : 12,
              bottom: i == rows.length - 1 ? 0 : 12,
            ),
            child: rows[i],
          ),
        ],
      ],
    );
  }
}

/// One person of the Team card: a 46 px circle avatar, the name with the tag
/// capsules on the same line, the role, what they contribute and a chevron.
/// Tapping opens their profile (no underline). [onTap] null = not tappable
/// (an invited person, seen by the team).
class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.member,
    required this.isYou,
    required this.onTap,
  });

  final TeamMember member;
  final bool isYou;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final role = member.role.trim();
    final contribution = member.contribution.trim();
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TileAvatar(
          initials: member.initials,
          size: 46,
          fontSize: 15,
          round: true,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    member.name,
                    style: AppText.sans(
                      size: 16.5,
                      height: 22,
                      weight: FontWeight.w700,
                    ).copyWith(decoration: TextDecoration.none),
                  ),
                  ...teamTagsOf(member, isYou: isYou),
                ],
              ),
              if (role.isNotEmpty)
                Text(
                  role,
                  style: AppText.sans(
                    size: 14,
                    height: 20,
                    color: const Color(0xFF6B726C),
                  ).copyWith(decoration: TextDecoration.none),
                ),
              if (contribution.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    contribution,
                    style: AppText.sans(
                      size: 13.5,
                      height: 19,
                      color: AppColors.paragraph,
                    ).copyWith(decoration: TextDecoration.none),
                  ),
                ),
            ],
          ),
        ),
        if (onTap != null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: AppIcon.filled(
              AppIcons.chevRight,
              size: 20,
              color: Color(0xFFA3A7A2),
            ),
          ),
      ],
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: member.name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// An associated investor: a 46 px circle avatar with the gold gradient, the
/// name, "Title · City" and a chevron. Tapping opens their profile.
class _InvestorRow extends StatelessWidget {
  const _InvestorRow({required this.investor, required this.onTap});

  final InvestorProfile investor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          TileAvatar(
            initials: investor.initials,
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
                  investor.name,
                  style: AppText.sans(size: 16.5, weight: FontWeight.w700),
                ),
                Text(
                  '${investor.title} · ${investor.city}',
                  style: AppText.sans(
                    size: 14,
                    height: 20,
                    color: const Color(0xFF6B726C),
                  ),
                ),
              ],
            ),
          ),
          const AppIcon.filled(
            AppIcons.chevRight,
            size: 20,
            color: Color(0xFFA3A7A2),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------- current round

/// "Current round": the type pill, the goal, the progress bar, what is raised
/// and the lead-investor line. Not raising: only the title and "Not raising
/// right now."
class _CurrentRoundCard extends StatelessWidget {
  const _CurrentRoundCard({required this.round});

  final CurrentRound? round;

  @override
  Widget build(BuildContext context) {
    final r = round;
    final title = Semantics(
      header: true,
      child: Text(
        'Current round',
        style: AppText.sans(size: 19, height: 26, weight: FontWeight.w700),
      ),
    );
    if (r == null) {
      return ManageCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            title,
            const SizedBox(height: 8),
            Text(
              'Not raising right now.',
              style: AppText.sans(size: 16, color: AppColors.grey),
            ),
          ],
        ),
      );
    }
    final fill = (r.percent / 100).clamp(0.0, 1.0);
    final lead = r.wantsLead;
    return ManageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: title),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.moss100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    r.type,
                    style: AppText.sans(
                      size: 12,
                      weight: FontWeight.w600,
                      color: AppColors.moss600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.sar(r.goal),
            style: AppText.sans(
              size: 28,
              height: 34,
              weight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
          Text(
            'Funding goal',
            style: AppText.sans(size: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFFEBE8E1)),
                  ),
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fill,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4F7D5A), Color(0xFF2F5D3A)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${Formatters.sar(r.raised)} raised',
                  style: AppText.sans(size: 15, weight: FontWeight.w600),
                ),
              ),
              Text(
                '${r.percent}%',
                style: AppText.sans(size: 14, color: AppColors.grey),
              ),
            ],
          ),
          if (lead != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                thickness: 1,
                color: StartupProfilePane._divider,
              ),
            ),
            Text(
              lead ? 'Looking for a lead investor' : 'No lead investor needed',
              style: AppText.sans(size: 14, color: AppColors.paragraph),
            ),
          ],
        ],
      ),
    );
  }
}
