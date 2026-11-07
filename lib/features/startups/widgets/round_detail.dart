import '../../../shared_ui/widgets/cards/pin_city.dart';

import 'package:flutter/material.dart';

import '../../../data_access/repositories/discovery_repository.dart';
import '../../../helpers/formatters.dart';
import '../../../models/funding_round.dart';
import '../../../models/home_item.dart';
import '../../../models/connection_request.dart';
import '../../../models/investor_profile.dart';
import '../../connection_requests/screens/requests_tab.dart';
import '../../connection_requests/view_models/requests_view_model.dart';
import '../../profiles/screens/investor_profile_screen.dart';
import '../view_models/rounds_view_model.dart';
import 'founder_ui.dart';
import 'manage_card.dart';
import 'round_form.dart';

/// Manage startup -> Rounds -> one round: back link "All rounds", the round
/// card (status, type and dates, Amount and Raised, progress, "Edit round" for
/// an open round), the "Investors" in the round and, for an OPEN round, its
/// "Investment requests" (Accept / Decline) and top "Matches".
///
/// Not here yet (they need the investment wallet, a later sprint): what each
/// investor paid, wallet links and a founder sending an investor a request.
/// Each section is a separate widget, so those can be added next to them.
class RoundDetail extends StatelessWidget {
  const RoundDetail({
    super.key,
    required this.vm,
    required this.number,
    required this.onBack,
    this.canManage = true,
    this.requests,
    this.onCheck,
    this.onToast,
  });

  final RoundsViewModel vm;

  /// The shown round's number (it is looked up again on every build, so the
  /// page follows an edit).
  final int number;
  final VoidCallback onBack;

  /// False for a view-only team member: no "Edit round".
  final bool canManage;

  /// The startup's investment requests (open round only), with the
  /// calculator check and toasts of Accept / Decline. Null hides the section.
  final RequestsViewModel? requests;
  final void Function(ConnectionRequest request)? onCheck;
  final void Function(String message)? onToast;

  FundingRound? get _round {
    for (final r in vm.rounds) {
      if (r.number == number) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    if (round == null) return const SizedBox.shrink();
    final editingThis = vm.editing?.number == round.number;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailBackLink(onTap: onBack),
        const SizedBox(height: 14),
        if (editingThis) ...[
          RoundForm(vm: vm, editing: true),
          const SizedBox(height: 14),
        ],
        _RoundCard(
          round: round,
          // Open round, someone who can edit, and no form open.
          onEdit: round.isOpen && canManage && !vm.formOpen && !vm.editOpen
              ? vm.openEdit
              : null,
        ),
        const SizedBox(height: 22),
        SectionTitle(
          title: 'Investors',
          subtitle: 'Who invested in this round',
        ),
        const SizedBox(height: 10),
        _Investors(round: round),
        // The investment requests belong to the open round (they used to be
        // a tab of Manage startup).
        if (round.isOpen && requests != null) ...[
          const SizedBox(height: 22),
          const SectionTitle(
            title: 'Investment Requests',
            subtitle: 'Investors asking to join this round',
          ),
          const SizedBox(height: 10),
          RequestsTab(
            vm: requests!,
            onCheck: onCheck ?? (_) {},
            onToast: onToast ?? (_) {},
            canAct: canManage,
          ),
        ],
        if (round.isOpen) ...[
          const SizedBox(height: 22),
          const SectionTitle(
            title: 'Matches',
            subtitle: 'Investors that fit this round',
          ),
          const SizedBox(height: 10),
          _Matches(vm: vm, round: round),
        ],
      ],
    );
  }
}

/// Chevron + "All rounds" (or another [label]) in moss green. Also the back
/// link of the Investment Wallet ticket page.
class DetailBackLink extends StatelessWidget {
  const DetailBackLink({
    super.key,
    required this.onTap,
    this.label = 'All rounds',
  });

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon.outline(
                  AppIcons.profileBack,
                  size: 20,
                  stroke: 2.2,
                  color: AppColors.moss600,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppText.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppColors.moss600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A section heading (19 bold) with its grey 13 line under it; also used by
/// the Investment Wallet.
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppText.sans(size: 19, height: 26, weight: FontWeight.w700),
          ),
        ),
        Text(
          subtitle,
          style: AppText.sans(size: 13, color: const Color(0xFF8C918D)),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ card

class _RoundCard extends StatelessWidget {
  const _RoundCard({required this.round, required this.onEdit});

  final FundingRound round;

  /// Null hides the button.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final r = round;
    return ManageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Round ${r.number}',
                    style: AppText.sans(
                      size: 20,
                      height: 26,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              AppPill(
                label: r.isOpen ? 'Open' : 'Closed',
                tone: r.isOpen ? AppPillTone.moss : AppPillTone.grey,
                height: 26,
                fontSize: 12.5,
                weight: FontWeight.w600,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${r.typeLabel} · ${r.dateLabel}',
            style: AppText.sans(size: 14, height: 20, color: AppColors.grey),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InfoBox(label: 'Amount', value: Formatters.sar(r.amount)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InfoBox(label: 'Raised', value: Formatters.sar(r.raised)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DetailProgress(percent: r.percent),
          const SizedBox(height: 6),
          Text(
            '${r.percent}% of the target raised',
            style: AppText.sans(size: 13, color: AppColors.grey),
          ),
          if (onEdit != null) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'Edit round',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.small,
              onPressed: onEdit,
            ),
          ],
        ],
      ),
    );
  }
}

/// A small green box with a grey label and a bold value (Amount / Raised,
/// Minimum / Maximum).
class InfoBox extends StatelessWidget {
  const InfoBox({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.moss50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.sans(size: 12.5, color: const Color(0xFF8C918D)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(size: 16, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// A 8 px full-width bar; it stops at 100 % (the text under it can go past).
class DetailProgress extends StatelessWidget {
  const DetailProgress({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final fill = (percent / 100).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFFE9E6DF))),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fill,
                child: const ColoredBox(color: AppColors.moss600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- investors

/// The style of the "Title · [pin] City" line of an investor.
final _subStyle = AppText.sans(size: 13.5, height: 19, color: AppColors.grey);

class _Investors extends StatefulWidget {
  const _Investors({required this.round});

  final FundingRound round;

  @override
  State<_Investors> createState() => _InvestorsState();
}

class _InvestorsState extends State<_Investors> {
  /// Loaded profiles by investor id (null: has none / could not be read).
  final Map<String, InvestorProfile?> _profiles = {};

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void didUpdateWidget(_Investors old) {
    super.didUpdateWidget(old);
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    for (final i in widget.round.investors) {
      final id = i.investorId;
      if (id == null || _profiles.containsKey(id)) continue;
      _profiles[id] = null;
      try {
        final p = await DiscoveryRepository.instance.loadInvestor(id);
        if (!mounted) return;
        setState(() => _profiles[id] = p);
      } catch (_) {
        // The name is still shown; opening it tries again.
      }
    }
  }

  Future<void> _open(RoundInvestor investor) async {
    final id = investor.investorId!;
    var profile = _profiles[id];
    if (profile == null) {
      try {
        profile = await DiscoveryRepository.instance.loadInvestor(id);
      } catch (_) {
        profile = null;
      }
    }
    if (!mounted) return;
    if (profile == null) {
      AppToast.error(context, 'This investor’s profile isn’t available.');
      return;
    }
    InvestorProfileScreen.open(context, profile);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.round;
    if (r.investors.isEmpty) {
      return ManageCard(
        child: Text(
          r.isOpen ? 'No investors yet' : 'No investors recorded',
          style: AppText.sans(size: 14, height: 20, color: AppColors.grey),
        ),
      );
    }
    return Column(
      children: [
        for (final i in r.investors) ...[
          _PersonTile(
            name: i.name,
            title: i.hasProfile ? _profiles[i.investorId]?.title ?? '' : '',
            city: i.hasProfile ? _profiles[i.investorId]?.city ?? '' : '',
            imageUrl: _profiles[i.investorId]?.photoUrl,
            onTap: i.hasProfile ? () => _open(i) : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// --------------------------------------------------------------- matches

class _Matches extends StatefulWidget {
  const _Matches({required this.vm, required this.round});

  final RoundsViewModel vm;
  final FundingRound round;

  @override
  State<_Matches> createState() => _MatchesState();
}

class _MatchesState extends State<_Matches> {
  late Future<List<HomeItem>> _future = _load();

  Future<List<HomeItem>> _load() => widget.vm.matchesFor(widget.round);

  /// New investors / startups arrived (a listener, outside of build).
  void _again() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  @override
  void initState() {
    super.initState();
    // New or changed investors: computed again at once.
    widget.vm.matchChanges.addListener(_again);
  }

  @override
  void didUpdateWidget(_Matches old) {
    super.didUpdateWidget(old);
    final a = old.round;
    final b = widget.round;
    // The round's type or amount changed (Edit round): new matches. A build
    // follows, so no setState here.
    if (a.type != b.type || a.amount != b.amount) _future = _load();
  }

  @override
  void dispose() {
    widget.vm.matchChanges.removeListener(_again);
    super.dispose();
  }

  void _open(HomeItem item) {
    final profile = widget.vm.matchedInvestor(item.id);
    if (profile == null) {
      AppToast.error(context, 'This investor’s profile isn’t available.');
      return;
    }
    InvestorProfileScreen.open(context, profile);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HomeItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return ManageCard(
            child: Text(
              'Finding matches…',
              style: AppText.sans(size: 14, height: 20, color: AppColors.grey),
            ),
          );
        }
        if (snap.hasError) {
          return ManageCard(
            child: Text(
              'Couldn’t load the matches. Check your connection.',
              style: AppText.sans(size: 14, height: 20, color: AppColors.grey),
            ),
          );
        }
        final items = snap.data ?? const <HomeItem>[];
        if (items.isEmpty) {
          return ManageCard(
            child: Text(
              'No matching investors yet',
              style: AppText.sans(size: 14, height: 20, color: AppColors.grey),
            ),
          );
        }
        return Column(
          children: [
            for (final item in items) ...[
              _PersonTile(
                name: item.name,
                title: widget.vm.matchedInvestor(item.id)?.title ?? 'Investor',
                city: item.city,
                imageUrl: item.imageUrl,
                matchPercent: item.matchPercent,
                matchReason: item.matchReason,
                onTap: () => _open(item),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------ tile

/// One investor: avatar, name, "Title · City" and, for a match, the pill
/// ("86% match") with the reason. Tappable when [onTap] is set.
class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.name,
    required this.title,
    required this.city,
    this.imageUrl,
    this.matchPercent,
    this.matchReason,
    this.onTap,
  });

  final String name;

  /// The investor's title ("Angel investor"), then the [city] with its pin.
  final String title;
  final String city;
  final String? imageUrl;
  final int? matchPercent;
  final String? matchReason;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final match = matchPercent;
    final reason = (matchReason ?? '').trim();
    return Semantics(
      button: onTap != null,
      label: [name, title, city].where((t) => t.trim().isNotEmpty).join(', '),
      excludeSemantics: true,
      child: ManageCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            HueAvatar(
              name: name,
              kind: HueAvatarKind.investor,
              size: 44,
              imageUrl: imageUrl,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                      size: 16,
                      height: 22,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (title.trim().isNotEmpty || city.trim().isNotEmpty)
                    Row(
                      children: [
                        if (title.trim().isNotEmpty)
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _subStyle,
                            ),
                          ),
                        if (title.trim().isNotEmpty && city.trim().isNotEmpty)
                          Text(' · ', style: _subStyle),
                        Flexible(child: PinCity(city, style: _subStyle)),
                      ],
                    ),
                  if (match != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mossChip,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$match% match',
                            style: AppText.sans(
                              size: 12.5,
                              color: AppColors.moss600,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (reason.isNotEmpty)
                          Text(
                            reason,
                            style: AppText.sans(
                              size: 12.5,
                              color: AppColors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const AppIcon.outline(
                AppIcons.rowChevron,
                size: 20,
                stroke: 2.2,
                color: Color(0xFF9AA19B),
              ),
          ],
        ),
      ),
    );
  }
}
