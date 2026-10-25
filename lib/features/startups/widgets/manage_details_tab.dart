import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/formatters.dart';
import '../../../models/startup.dart';
import '../../../models/startup_enums.dart';
import '../../../models/team_member.dart';
import '../../../models/list_entries.dart';
import '../../../shared_ui/widgets/cards/box_grid.dart';
import 'founder_ui.dart';
import 'manage_card.dart';
import 'role_tag.dart';
import 'startup_ask.dart';

/// Manage startup -> Details: ONE white card holding the six sections of the
/// add-startup form as an accordion, in this order: Overview, Startup
/// Description, Target Market, Finance and Growth, Startup Ask, Startup Team.
///
/// A section row shows an icon tile, the title, a one-line summary and a
/// chevron. Tapping it opens it in place (one at a time). While a section is
/// open and [canEdit], an "Edit" pill appears next to the chevron; it calls
/// [onEdit] with the section's step number (the same numbering as the form).
/// Empty answers read "Not added yet".
class ManageDetailsTab extends StatelessWidget {
  const ManageDetailsTab({
    super.key,
    required this.startup,
    required this.openIndex,
    required this.onToggle,
    required this.canEdit,
    required this.onEdit,
    this.myRole = StartupRole.founder,
  });

  final Startup startup;

  /// The user's role (tags their own row in Startup Team).
  final StartupRole myRole;

  /// The open section (0-based, same as the form's steps), or null.
  final int? openIndex;
  final ValueChanged<int> onToggle;

  /// False hides the Edit pill (view only).
  final bool canEdit;
  final ValueChanged<int> onEdit;

  static const _notAdded = 'Not added yet';

  static String _money(int? v) =>
      v == null || v <= 0 ? '' : Formatters.sarShort(v);

  /// The one-line summary of section [i].
  String _summary(int i) {
    final s = startup;
    switch (i) {
      case 0:
        return '${s.sectorLabel} · ${s.stageLabel} · ${s.location.label}';
      case 1:
        return s.problem.trim().isEmpty ? _notAdded : s.problem.trim();
      case 2:
        return _money(s.tam).isEmpty
            ? _notAdded
            : 'Target market size ${_money(s.tam)}';
      case 3:
        final parts = [
          if (_money(s.capital).isNotEmpty) 'Capital ${_money(s.capital)}',
          if (_money(s.valuation).isNotEmpty)
            'Valuation ${_money(s.valuation)}',
        ];
        return parts.isEmpty ? _notAdded : parts.join(' · ');
      case 4:
        final parts = [
          if (s.seeksFunding && _money(s.fundingRequirement).isNotEmpty)
            'Funding ${_money(s.fundingRequirement)}',
          ...StartupAsk.support(s).take(2),
        ];
        return parts.isEmpty ? _notAdded : parts.join(' · ');
      default:
        final n = s.team.length;
        return n == 0 ? _notAdded : (n == 1 ? '1 member' : '$n members');
    }
  }

  /// The six section titles (also the headers of the single-section editor).
  static const titles = [
    'Overview',
    'Startup Description',
    'Target Market',
    'Finance and Growth',
    'Startup Ask',
    'Startup Team',
  ];
  static const _icons = [
    AppIcons.info,
    AppIcons.bulb,
    AppIcons.search,
    AppIcons.wallet,
    AppIcons.target,
    AppIcons.people,
  ];

  @override
  Widget build(BuildContext context) {
    return ManageCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < titles.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.dividerSoft),
            _SectionRow(
              icon: _icons[i],
              gold: i.isOdd,
              title: titles[i],
              summary: _summary(i),
              open: openIndex == i,
              canEdit: canEdit,
              onToggle: () => onToggle(i),
              onEdit: () => onEdit(i),
              body: _body(i),
            ),
          ],
        ],
      ),
    );
  }

  Widget _body(int i) {
    switch (i) {
      case 0:
        return _Overview(startup);
      case 1:
        return _Description(startup);
      case 2:
        return _Market(startup);
      case 3:
        return _Finance(startup);
      case 4:
        return _Ask(startup);
      default:
        return _Team(startup, myRole);
    }
  }
}

/// One accordion row: header (tile, title, summary, Edit pill, chevron) and,
/// when open, the section's content.
class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.icon,
    required this.gold,
    required this.title,
    required this.summary,
    required this.open,
    required this.canEdit,
    required this.onToggle,
    required this.onEdit,
    required this.body,
  });

  final String icon;
  final bool gold;
  final String title;
  final String summary;
  final bool open;
  final bool canEdit;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final dur = Motion.dur(context, const Duration(milliseconds: 220));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          label: '$title, $summary',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: gold ? AppColors.tagGoldFill : AppColors.moss100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: AppIcon.filled(
                        icon,
                        size: 20,
                        color: gold ? AppColors.tagGoldText : AppColors.moss600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppText.sans(
                            size: 17,
                            weight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(
                            size: 14,
                            height: 20,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The Edit pill exists only while the section is open and
                  // fades in (200 ms).
                  if (canEdit && open)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Motion.dur(
                        context,
                        const Duration(milliseconds: 200),
                      ),
                      builder: (context, t, child) =>
                          Opacity(opacity: t, child: child),
                      child: _EditPill(onTap: onEdit),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: dur,
                    curve: Curves.ease,
                    child: const AppIcon.filled(
                      AppIcons.chevDown,
                      size: 24,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: dur,
          curve: Curves.ease,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: body,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Pencil icon + "Edit": height 34, radius 999, 1 px border, white, moss
/// 14 px semibold.
class _EditPill extends StatelessWidget {
  const _EditPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Edit',
      excludeSemantics: true,
      child: Pressable(
        scale: PressScale.chip,
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon.outline(
                AppIcons.pencil,
                size: 14,
                color: AppColors.moss600,
              ),
              const SizedBox(width: 6),
              Text(
                'Edit',
                style: AppText.sans(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppColors.moss600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ section bodies

/// A question / label above its answer. An empty answer reads "Not added yet".
class _QA extends StatelessWidget {
  const _QA(this.label, this.answer);

  final String label;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final empty = answer.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.sans(
              size: 14,
              height: 20,
              weight: FontWeight.w600,
              color: AppColors.moss600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            empty ? ManageDetailsTab._notAdded : answer.trim(),
            style: AppText.sans(
              size: 16,
              height: 24,
              color: empty ? AppColors.hint : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview(this.s);

  final Startup s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QA('Startup name', s.name),
        _QA('Brief description', s.briefDescription),
        BoxGrid(
          items: [
            ('Sector', s.sectorLabel),
            ('Stage', s.stageLabel),
            ('Commerce model', s.businessModelLabel),
            ('Headquarters', s.location.label),
            ('Founded year', s.foundedYear?.toString() ?? ''),
            ('Website', s.websiteUrl ?? ''),
            ('Visibility', s.isPublic ? 'Public' : 'Private'),
          ],
        ),
      ],
    );
  }
}

class _Description extends StatelessWidget {
  const _Description(this.s);

  final Startup s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QA(FounderToolsStrings.problemLabel, s.problem),
        _QA(FounderToolsStrings.solutionLabel, s.solution),
        _QA(FounderToolsStrings.advantageLabel, s.advantage),
      ],
    );
  }
}

class _Market extends StatelessWidget {
  const _Market(this.s);

  final Startup s;

  @override
  Widget build(BuildContext context) {
    final size = ManageDetailsTab._money(s.tam);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QA(FounderToolsStrings.customersLabel, s.customers),
        Text(
          'Target market size',
          style: AppText.sans(
            size: 14,
            height: 20,
            weight: FontWeight.w600,
            color: AppColors.moss600,
          ),
        ),
        const SizedBox(height: 4),
        if (size.isEmpty)
          Text(
            ManageDetailsTab._notAdded,
            style: AppText.sans(size: 16, height: 24, color: AppColors.hint),
          )
        else ...[
          Text(
            size,
            style: AppText.sans(
              size: 28,
              height: 34,
              weight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
          Text(
            'Total yearly revenue in the target market',
            style: AppText.sans(size: 13, color: AppColors.grey),
          ),
        ],
      ],
    );
  }
}

class _Finance extends StatelessWidget {
  const _Finance(this.s);

  final Startup s;

  @override
  Widget build(BuildContext context) {
    final revenue = s.expectedRevenue;
    final hasRevenue = revenue.any((v) => (v ?? 0) > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoxGrid(
          items: [
            ('Current available capital', ManageDetailsTab._money(s.capital)),
            ('Current company valuation', ManageDetailsTab._money(s.valuation)),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Expected revenue next 3 years',
          style: AppText.sans(
            size: 14,
            height: 20,
            weight: FontWeight.w600,
            color: AppColors.moss600,
          ),
        ),
        const SizedBox(height: 4),
        if (!hasRevenue)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              ManageDetailsTab._notAdded,
              style: AppText.sans(size: 16, height: 24, color: AppColors.hint),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: RevenueBars(
              values: [for (final v in revenue) (v ?? 0).toDouble()],
              labels: const ['Year 1', 'Year 2', 'Year 3'],
              valueLabels: [
                for (final v in revenue)
                  (v ?? 0) > 0 ? Formatters.shortMoney(v!) : '—',
              ],
            ),
          ),
        _QA(FounderToolsStrings.growthLabel, s.growth),
        // The business model answer is asked in the onboarding, which is
        // being redone; until it is stored it reads "Not added yet".
        const _QA('Business model', ''),
      ],
    );
  }
}

class _Ask extends StatelessWidget {
  const _Ask(this.s);

  final Startup s;

  @override
  Widget build(BuildContext context) {
    final funding = s.seeksFunding;
    final partnership = s.lookingFor.contains(LookingFor.partnership);
    final support = StartupAsk.support(s);
    final amount = ManageDetailsTab._money(s.fundingRequirement);
    final lead = s.wantsLeadInvestor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AskRow(
          icon: AppIcons.wallet,
          title: 'Funding',
          selected: funding,
          detail: !funding
              ? 'Off'
              : [
                  if (amount.isNotEmpty) amount,
                  if (lead != null)
                    lead
                        ? 'Looking for a lead investor'
                        : 'No lead investor needed',
                ].join(' · '),
        ),
        const SizedBox(height: 10),
        AskRow(
          icon: AppIcons.people,
          title: 'Partnership',
          selected: partnership,
          detail: partnership ? 'Open to partnerships' : 'Not selected',
        ),
        const SizedBox(height: 10),
        AskRow(
          icon: AppIcons.bulb,
          title: 'Support',
          selected: support.isNotEmpty,
          detail: support.isEmpty ? 'Not selected' : support.join(', '),
        ),
      ],
    );
  }
}

class _Team extends StatelessWidget {
  const _Team(this.s, this.myRole);

  final Startup s;
  final StartupRole myRole;

  @override
  Widget build(BuildContext context) {
    if (s.team.isEmpty) {
      return Text(
        ManageDetailsTab._notAdded,
        style: AppText.sans(size: 16, height: 24, color: AppColors.hint),
      );
    }
    final user = AppSession.instance.user;
    final me = user?.fullName.trim().toLowerCase();
    return Column(
      children: [
        for (var i = 0; i < s.team.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _MemberCard(
            member: s.team[i],
            isMe: s.team[i].uid != null
                ? s.team[i].uid == user?.uid
                : me != null && s.team[i].name.trim().toLowerCase() == me,
            myRole: myRole,
          ),
        ],
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isMe,
    required this.myRole,
  });

  final TeamMember member;
  final bool isMe;
  final StartupRole myRole;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TileAvatar(
            initials: member.initials,
            size: 40,
            fontSize: 14,
            round: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMe
                            ? '${AppSession.instance.user?.fullName ?? member.name} (you)'
                            : member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(size: 16, weight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Members are not stored with a role yet: your own row shows
                    // your role, the others show "Team member".
                    RoleTag(isMe ? myRole : StartupRole.member),
                  ],
                ),
                Text(
                  member.meta,
                  style: AppText.sans(
                    size: 14,
                    height: 20,
                    color: AppColors.grey,
                  ),
                ),
                if (member.contribution.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      member.contribution,
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
