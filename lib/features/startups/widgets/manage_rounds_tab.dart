import 'package:flutter/material.dart';

import '../../../data_access/repositories/discovery_repository.dart';
import '../../../helpers/formatters.dart';
import '../../../models/funding_round.dart';
import '../../../models/connection_request.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../../connection_requests/view_models/requests_view_model.dart';
import '../../profiles/screens/investor_profile_screen.dart';
import '../view_models/rounds_view_model.dart';
import 'founder_ui.dart';
import 'manage_card.dart';
import 'round_detail.dart';
import 'round_form.dart';

/// Manage startup -> Rounds: the startup's rounds from Firestore. Adding,
/// editing or closing a round is saved with the startup (see
/// RoundsViewModel).
///
/// Top row: "Funding rounds" with "All amounts in SAR", and on the right
/// "Close round" (a round is open) or "Add round" (none is). Below, the
/// "New round" form when it is open, then the rounds table, newest first.
/// Tapping a round opens its page ([RoundDetail]) inside this tab.
class ManageRoundsTab extends StatefulWidget {
  const ManageRoundsTab({
    super.key,
    required this.vm,
    this.canManage = true,
    this.requests,
    this.onCheck,
    this.onToast,
  });

  final RoundsViewModel vm;

  /// False hides Add round / Close round / Edit round (a team member only
  /// reads).
  final bool canManage;

  /// The startup's investment requests, shown on the page of the OPEN round
  /// ("Investment requests"). Null hides that section.
  final RequestsViewModel? requests;

  /// "Check in the calculator" of a request, and the toasts of Accept /
  /// Decline.
  final void Function(ConnectionRequest request)? onCheck;
  final void Function(String message)? onToast;

  @override
  State<ManageRoundsTab> createState() => _ManageRoundsTabState();
}

class _ManageRoundsTabState extends State<ManageRoundsTab> {
  /// The round whose page is open, or null for the list. It lives here (not in
  /// the view model), so switching Manage tabs always comes back to the list.
  int? _detail;

  RoundsViewModel get vm => widget.vm;
  bool get canManage => widget.canManage;

  @override
  void initState() {
    super.initState();
    // Back on the list: an Edit round form left open is dropped.
    vm.resetView();
  }

  Future<void> _confirmClose(BuildContext context) async {
    final open = vm.openRound;
    if (open == null) return;
    final close = await showDiscardDialog(
      context,
      title: 'Close Round ${open.number}?',
      message: 'Investors won’t be able to send requests for this round anymore. You can add a new round after closing it.',
      discardLabel: 'Close round',
      keepLabel: 'Cancel',
    );
    if (!close) return;
    final ok = await vm.closeOpenRound();
    if (!ok && vm.error != null && context.mounted) {
      AppToast.error(context, vm.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final detail = _detail;
        if (detail != null && vm.rounds.any((r) => r.number == detail)) {
          return RoundDetail(
            vm: vm,
            number: detail,
            canManage: canManage,
            requests: widget.requests,
            onCheck: widget.onCheck,
            onToast: widget.onToast,
            onBack: () {
              // An Edit round form left open is dropped with the page.
              if (vm.editOpen) vm.cancelEdit();
              setState(() => _detail = null);
            },
          );
        }
        final open = vm.openRound;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Funding rounds',
                          style: AppText.sans(
                            size: 19,
                            height: 26,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'All amounts in SAR',
                        style: AppText.sans(
                          size: 13,
                          color: const Color(0xFF8C918D),
                        ),
                      ),
                    ],
                  ),
                ),
                if (canManage && !vm.formOpen && vm.ready)
                  open != null
                      ? _PillButton(
                          label: 'Close round',
                          onTap: () => _confirmClose(context),
                        )
                      : _PillButton(
                          label: 'Add round',
                          icon: AppIcons.plus,
                          filled: true,
                          onTap: vm.openForm,
                        ),
              ],
            ),
            const SizedBox(height: 14),
            if (canManage && vm.formOpen) ...[
              RoundForm(vm: vm),
              const SizedBox(height: 14),
            ],
            RoundsTable(
              rounds: vm.rounds,
              onOpen: (r) => setState(() => _detail = r.number),
              emptyText: vm.isLoading
                  ? 'Loading rounds…'
                  : vm.loadFailed
                  ? 'Couldn’t load the rounds. Check your connection.'
                  : 'No rounds yet.',
            ),
            if (vm.rounds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Tap a round to see its details.',
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 13, color: const Color(0xFF8C918D)),
                ),
              ),
            ],
            if (vm.loadFailed) ...[
              const SizedBox(height: 10),
              Center(
                child: _PillButton(label: 'Try again', onTap: vm.load),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// "Close round" (white, 1 px border) or "Add round" (green, plus icon):
/// height 40, radius 999.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final color = filled ? AppColors.onDark : AppColors.ink;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: filled ? AppColors.moss600 : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AppIcon.filled(icon!, size: 18, color: color),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppText.sans(
                  size: 15,
                  weight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ table

/// Column widths: 1.2fr · 0.8fr · 0.85fr · 1fr, gap 10.
const _flex = [120, 80, 85, 100];
const _gap = 10.0;

/// The rounds table (read only): used by Manage -> Rounds and by the startup
/// page's Funding tab.
class RoundsTable extends StatelessWidget {
  const RoundsTable({
    super.key,
    required this.rounds,
    this.emptyText = 'No rounds yet.',
    this.centerEmpty = false,
    this.onOpen,
  });

  final List<FundingRound> rounds;

  /// When set (Manage -> Rounds) every row is tappable: it shows its status
  /// word and a chevron. Null (the startup page) keeps the plain read-only
  /// table.
  final ValueChanged<FundingRound>? onOpen;

  /// The text of an empty table (the startup page centres its own).
  final String emptyText;
  final bool centerEmpty;

  @override
  Widget build(BuildContext context) {
    final open = onOpen;
    final table = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderRow(interactive: open != null),
        if (rounds.isEmpty)
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              emptyText,
              textAlign: centerEmpty ? TextAlign.center : TextAlign.start,
              style: AppText.sans(size: 14, color: AppColors.grey),
            ),
          ),
        for (final r in rounds) ...[
          const Divider(height: 1, color: AppColors.dividerSoft),
          _RoundRow(round: r, onTap: open == null ? null : () => open(r)),
        ],
      ],
    );
    return ManageCard(
      padding: EdgeInsets.zero,
      // A pressed row's background stays inside the card's rounded corners.
      child: open == null
          ? table
          : ClipRRect(borderRadius: BorderRadius.circular(19), child: table),
    );
  }
}

/// Right padding of a tappable row: room for the chevron so the columns do
/// not touch it.
const double _chevronRoom = 32;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({this.interactive = false});

  final bool interactive;

  @override
  Widget build(BuildContext context) {
    TextStyle style() => AppText.sans(
      size: 11.5,
      weight: FontWeight.w700,
      letterSpacing: 0.5,
      color: const Color(0xFF8C918D),
    );
    Widget cell(int i, String text, {bool center = false}) => Expanded(
      flex: _flex[i],
      child: Text(
        text.toUpperCase(),
        textAlign: center ? TextAlign.center : TextAlign.start,
        maxLines: 1,
        style: style(),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 14, interactive ? _chevronRoom : 14, 12),
      child: Row(
        children: [
          cell(0, 'Round'),
          const SizedBox(width: _gap),
          cell(1, 'Amount', center: true),
          const SizedBox(width: _gap),
          cell(2, 'Raised', center: true),
          const SizedBox(width: _gap),
          cell(3, 'Investors'),
        ],
      ),
    );
  }
}

/// One round: every first line has the same 22 px line height, so the first
/// lines of the four cells sit on one line.
class _RoundRow extends StatefulWidget {
  const _RoundRow({required this.round, this.onTap});

  final FundingRound round;

  /// Set in Manage: the row opens the round page (it also shows the status
  /// word and a chevron).
  final VoidCallback? onTap;

  static const double line = 22;

  @override
  State<_RoundRow> createState() => _RoundRowState();
}

class _RoundRowState extends State<_RoundRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    final content = _content();
    if (onTap == null) return content;
    final r = widget.round;
    return Semantics(
      button: true,
      label: 'Round ${r.number}, ${r.isOpen ? 'open' : 'closed'}',
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: ColoredBox(
          color: _pressed ? AppColors.moss50 : Colors.transparent,
          child: Stack(
            children: [
              content,
              const Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: ExcludeSemantics(
                    child: AppIcon.outline(
                      AppIcons.rowChevron,
                      size: 20,
                      stroke: 2.2,
                      color: Color(0xFF9AA19B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    final r = widget.round;
    const line = _RoundRow.line;
    final interactive = widget.onTap != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 16, interactive ? _chevronRoom : 14, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round: status dot, "Round 2", the type in gold, the dates.
          Expanded(
            flex: _flex[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: line,
                  child: Row(
                    children: [
                      _StatusDot(open: r.isOpen),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Round ${r.number}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(
                            size: 16,
                            height: line,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (interactive)
                  Text(
                    r.isOpen ? 'Open' : 'Closed',
                    style: AppText.sans(
                      size: 12.5,
                      height: 17,
                      weight: FontWeight.w600,
                      color: r.isOpen
                          ? const Color(0xFF2F8A4A)
                          : const Color(0xFF8C918D),
                    ),
                  ),
                Text(
                  r.typeLabel,
                  style: AppText.sans(
                    size: 13,
                    height: 18,
                    weight: FontWeight.w600,
                    color: AppColors.tagGoldText,
                  ),
                ),
                Text(
                  r.dateLabel,
                  style: AppText.sans(
                    size: 12.5,
                    height: 17,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _gap),
          // Amount: centred, never wraps.
          Expanded(
            flex: _flex[1],
            child: SizedBox(
              height: line,
              child: Center(
                child: Text(
                  Formatters.shortMoney(r.amount),
                  maxLines: 1,
                  softWrap: false,
                  style: AppText.sans(
                    size: 16,
                    height: line,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: _gap),
          // Raised: amount, a 6 px bar (stops at 100 %), the percentage.
          Expanded(
            flex: _flex[2],
            child: Column(
              children: [
                SizedBox(
                  height: line,
                  child: Center(
                    child: Text(
                      Formatters.shortMoney(r.raised),
                      maxLines: 1,
                      softWrap: false,
                      style: AppText.sans(
                        size: 15,
                        height: line,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _RaisedBar(percent: r.percent),
                const SizedBox(height: 4),
                Text(
                  '${r.percent}%',
                  style: AppText.sans(size: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: _gap),
          // Investors: one name per line (long names wrap), the first
          // three then "+N more", or "None yet".
          Expanded(
            flex: _flex[3],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.investors.isEmpty)
                  SizedBox(
                    height: line,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'None yet',
                        style: AppText.sans(size: 14, color: AppColors.grey),
                      ),
                    ),
                  )
                else
                  _InvestorList(investors: r.investors),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 8 px dot: open = green with a soft ring, closed = grey.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: open ? 'Open' : 'Closed',
      excludeSemantics: true,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: open ? const Color(0xFF3FAE5C) : const Color(0xFFC3C0B9),
          boxShadow: open
              ? const [BoxShadow(color: Color(0x333FAE5C), spreadRadius: 3)]
              : null,
        ),
      ),
    );
  }
}

/// A 6 px progress bar, at most 64 px wide, grey track and green fill. It
/// never goes past 100 % (the percentage under it can).
class _RaisedBar extends StatelessWidget {
  const _RaisedBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final fill = (percent / 100).clamp(0.0, 1.0);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 64),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          height: 6,
          width: double.infinity,
          child: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFFE9E6DF)),
              ),
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
      ),
    );
  }
}

/// An investor of a round: with a profile, the name in 14 px semibold moss
/// green (no underline) that opens it; without one, plain grey text. The
/// lead investor gets "· Lead" in gold.
class _InvestorLink extends StatelessWidget {
  const _InvestorLink({required this.investor});

  final RoundInvestor investor;

  Future<void> _open(BuildContext context) async {
    final profile = await DiscoveryRepository.instance.loadInvestor(
      investor.investorId!,
    );
    if (!context.mounted) return;
    if (profile == null) {
      AppToast.error(context, 'This investor’s profile isn’t available.');
      return;
    }
    InvestorProfileScreen.open(context, profile);
  }

  @override
  Widget build(BuildContext context) {
    final linked = investor.hasProfile;
    // At least one table line high (the first lines of the cells stay on
    // one line); a long name wraps instead of being cut.
    final line = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _RoundRow.line),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text.rich(
          TextSpan(
            text: investor.name,
            style: AppText.sans(
              size: 14,
              height: 20,
              weight: linked ? FontWeight.w600 : FontWeight.w400,
              color: linked ? AppColors.moss600 : AppColors.grey,
            ).copyWith(decoration: TextDecoration.none),
            children: [
              if (investor.isLead)
                TextSpan(
                  text: ' · Lead',
                  style: AppText.sans(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: AppColors.tagGoldText,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final label = investor.isLead
        ? '${investor.name}, lead investor'
        : investor.name;
    if (!linked) {
      return Semantics(label: label, excludeSemantics: true, child: line);
    }
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context),
        child: line,
      ),
    );
  }
}

/// The investors of a round: the first [shown] names, then "+N more" that
/// opens the full list ("Show less" closes it).
class _InvestorList extends StatefulWidget {
  const _InvestorList({required this.investors});

  final List<RoundInvestor> investors;

  static const shown = 3;

  @override
  State<_InvestorList> createState() => _InvestorListState();
}

class _InvestorListState extends State<_InvestorList> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final all = widget.investors;
    final extra = all.length - _InvestorList.shown;
    final visible = _all || extra <= 0
        ? all
        : all.take(_InvestorList.shown).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final i in visible) _InvestorLink(investor: i),
        if (extra > 0)
          Semantics(
            button: true,
            label: _all ? 'Show fewer investors' : 'Show $extra more investors',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _all = !_all),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _all ? 'Show less' : '+$extra more',
                  style: AppText.sans(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.moss600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
