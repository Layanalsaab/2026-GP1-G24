import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/discovery_repository.dart';
import '../../../helpers/formatters.dart';
import '../../../models/funding_round.dart';
import '../../../models/startup_enums.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../../profiles/screens/investor_profile_screen.dart';
import '../view_models/rounds_view_model.dart';
import 'founder_ui.dart';
import 'manage_card.dart';

/// Manage startup -> Rounds: the startup's rounds from Firestore. Adding or
/// closing a round is saved with the startup (see RoundsViewModel).
///
/// Top row: "Funding rounds" with "All amounts in SAR", and on the right
/// "Close round" (a round is open) or "Add round" (none is). Below, the
/// "New round" form when it is open, then the rounds table, newest first.
class ManageRoundsTab extends StatelessWidget {
  const ManageRoundsTab({super.key, required this.vm, this.canManage = true});

  final RoundsViewModel vm;

  /// False hides Add round / Close round (a team member only reads).
  final bool canManage;

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
              _AddRoundForm(vm: vm),
              const SizedBox(height: 14),
            ],
            RoundsTable(
              rounds: vm.rounds,
              emptyText: vm.isLoading
                  ? 'Loading rounds…'
                  : vm.loadFailed
                  ? 'Couldn’t load the rounds. Check your connection.'
                  : 'No rounds yet.',
            ),
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
  });

  final List<FundingRound> rounds;

  /// The text of an empty table (the startup page centres its own).
  final String emptyText;
  final bool centerEmpty;

  @override
  Widget build(BuildContext context) {
    return ManageCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HeaderRow(),
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
            _RoundRow(round: r),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
class _RoundRow extends StatelessWidget {
  const _RoundRow({required this.round});

  final FundingRound round;

  static const double line = 22;

  @override
  Widget build(BuildContext context) {
    final r = round;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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

// ------------------------------------------------------------- add round

/// The "New round" form: a light green box above the table.
class _AddRoundForm extends StatelessWidget {
  const _AddRoundForm({required this.vm});

  final RoundsViewModel vm;

  Future<void> _pickType(BuildContext context) async {
    final r = await showPickerSheet(
      context,
      title: 'Round type',
      options: [for (final t in vm.allowedTypes) t.label],
      selected: vm.type?.label,
    );
    if (r != null) {
      vm.setType(StartupStage.picks.firstWhere((t) => t.label == r.value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.moss50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.moss100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'New round · Round ${vm.nextNumber}',
              style: AppText.sans(
                size: 17,
                weight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppField(
            label: 'Round type',
            required: true,
            child: SelectField(
              placeholder: 'Select a round type',
              value: vm.type?.label,
              semanticLabel: 'Round type',
              onTap: () => _pickType(context),
            ),
          ),
          const SizedBox(height: FieldHelperRow.gapAfter),
          AppField(
            label: FounderToolsStrings.fundingLabel,
            required: true,
            sentenceCase: true,
            info: FounderToolsStrings.fundingInfo,
            hint: vm.amountHint,
            error: vm.amountError,
            child: MoneyField(
              controller: vm.amount,
              onChanged: vm.setAmount,
              hasError: vm.amountError != null,
              semanticLabel: FounderToolsStrings.fundingLabel,
            ),
          ),
          const SizedBox(height: FieldHelperRow.gapAfter),
          AppField(
            label: FounderToolsStrings.raisedLabel,
            required: true,
            sentenceCase: true,
            info: FounderToolsStrings.raisedInfo,
            error: vm.raisedError,
            child: MoneyField(
              controller: vm.raised,
              onChanged: vm.setRaised,
              hasError: vm.raisedError != null,
              semanticLabel: FounderToolsStrings.raisedLabel,
            ),
          ),
          const SizedBox(height: FieldHelperRow.gapAfter),
          ChipGroupField(
            label: FounderToolsStrings.leadLabel,
            required: true,
            sentenceCase: true,
            options: const ['Yes', 'No'],
            selected: [if (vm.wantsLead != null) vm.wantsLead! ? 'Yes' : 'No'],
            onTap: (label) => vm.setLead(label == 'Yes'),
            error: vm.leadError,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.small,
                  onPressed: vm.cancelForm,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Add round',
                  variant: vm.formValid
                      ? AppButtonVariant.primary
                      : AppButtonVariant.off,
                  size: AppButtonSize.small,
                  onPressed: () async {
                    final ok = await vm.addRound();
                    if (!ok && vm.error != null && context.mounted) {
                      AppToast.error(context, vm.error!);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
