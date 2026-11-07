import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/funding_round.dart';
import '../../../models/startup.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../../startups/widgets/manage_card.dart';
import '../view_models/valuation_calculator_view_model.dart';

/// Valuation calculator (docs/05 D4): inputs card, green result card,
/// "Ownership after this round" card and the note. From Manage the boxes
/// are filled from the open round and the startup's valuation, from a
/// request they are filled from the request. Nothing is saved.
class ValuationCalculatorScreen extends StatefulWidget {
  const ValuationCalculatorScreen({
    super.key,
    required this.startup,
    this.funding,
    this.equityPercent,
    this.round,
    this.valuation,
    this.ownershipUnknown = false,
  });

  final Startup startup;
  final int? funding;
  final double? equityPercent;

  // the open round (shown under the funding box)
  final FundingRound? round;

  // current company valuation from onboarding
  final int? valuation;

  // true if there are co-founders or older rounds
  final bool ownershipUnknown;

  // opened from the dashboard, filled from the startup and its open round
  static void openForStartup(
    BuildContext context, {
    required Startup startup,
    FundingRound? round,
    bool ownershipUnknown = false,
  }) {
    AppNav.push(
      context,
      ValuationCalculatorScreen(
        startup: startup,
        funding: round?.amount ?? startup.fundingRequirement,
        valuation: startup.valuation,
        round: round,
        ownershipUnknown: ownershipUnknown,
      ),
      greenHeader: true,
    );
  }

  /// Pushes the calculator (forward transition).
  static void open(
    BuildContext context, {
    required Startup startup,
    int? funding,
    double? equityPercent,
    FundingRound? round,
  }) {
    AppNav.push(
      context,
      ValuationCalculatorScreen(
        startup: startup,
        funding: funding,
        equityPercent: equityPercent,
        round: round,
        // so a request's terms can be compared with the startup's valuation
        valuation: startup.valuation,
      ),
      greenHeader: true,
    );
  }

  @override
  State<ValuationCalculatorScreen> createState() =>
      _ValuationCalculatorScreenState();
}

class _ValuationCalculatorScreenState extends State<ValuationCalculatorScreen> {
  late final ValuationCalculatorViewModel _vm = ValuationCalculatorViewModel(
    funding: widget.funding,
    equityPercent: widget.equityPercent,
    valuation: widget.valuation,
    ownershipUnknown: widget.ownershipUnknown,
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  // back with something typed: the same "Discard changes?" dialog as the
  // other forms in the app
  Future<void> _leave() async {
    if (!_vm.hasChanges) {
      AppNav.back(context);
      return;
    }
    final discard = await showDiscardDialog(
      context,
      title: FounderToolsStrings.discardEditTitle,
      message: FounderToolsStrings.discardEditMessage,
      discardLabel: FounderToolsStrings.discard,
      keepLabel: FounderToolsStrings.keepEditing,
    );
    if (!mounted || !discard) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => PopScope(
        canPop: !_vm.hasChanges,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: _page(context),
      ),
    );
  }

  Widget _page(BuildContext context) {
    final s = widget.startup;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: FounderToolsStrings.calcTitle,
              overlap: OverlapList.overlap,
              onBack: _leave,
            ),
            ListenableBuilder(
              listenable: _vm,
              builder: (context, _) => OverlapList(
                gap: 12,
                children: [
                  _InputsCard(vm: _vm, startup: s, round: widget.round),
                  _ResultCard(vm: _vm),
                  if (_vm.isValid) _OwnershipCard(vm: _vm),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text(
                      FounderToolsStrings.calcNote,
                      style: AppText.sans(
                        size: 13,
                        height: 19,
                        color: AppColors.grey,
                      ),
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

class _InputsCard extends StatelessWidget {
  const _InputsCard({required this.vm, required this.startup, this.round});

  final ValuationCalculatorViewModel vm;
  final Startup startup;
  final FundingRound? round;

  // same field as the other forms: label, inline (i) tip, error / hint line
  Widget _field({
    required String label,
    required String infoKey,
    required Widget input,
    required String? error,
    String? hint,
  }) => AppField(
    label: label,
    info: _tip(infoKey),
    error: error,
    hint: hint,
    child: input,
  );

  @override
  Widget build(BuildContext context) {
    final decimal = [ValuationCalculatorViewModel.percentInput];
    return ManageCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TileAvatar(
                initials: startup.initials,
                size: 44,
                radius: 14,
                fontSize: 15,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startup.name,
                      style: AppText.sans(size: 16, weight: FontWeight.w600),
                    ),
                    Text(
                      '${startup.sectorLabel} · ${startup.location.label}',
                      style: AppText.sans(size: 13, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppPill(
                label: startup.stageLabel,
                tone: AppPillTone.gold,
                height: 28,
                fontSize: 13,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            FounderToolsStrings.thisRound,
            style: AppText.sans(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _field(
            label: FounderToolsStrings.fundingToRaise,
            infoKey: 'f',
            error: vm.fundingError,
            hint: round == null
                ? null
                : FounderToolsStrings.calcRoundHint(
                    round!.number,
                    round!.typeLabel,
                    ValuationCalculatorViewModel.sar(round!.raised.toDouble()),
                  ),
            input: MoneyField(
              controller: vm.funds,
              maxDigits: 12,
              hasError: vm.fundingError != null,
              semanticLabel: FounderToolsStrings.fundingToRaise,
            ),
          ),
          const SizedBox(height: FieldHelperRow.gapAfter),
          _field(
            label: FounderToolsStrings.equityToGive,
            infoKey: 'e',
            error: vm.equityError,
            input: AppTextField(
              controller: vm.equity,
              suffix: '%',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: decimal,
              hasError: vm.equityError != null,
              semanticLabel: FounderToolsStrings.equityToGive,
            ),
          ),
          const SizedBox(height: FieldHelperRow.gapAfter),
          _field(
            label: FounderToolsStrings.currentOwnership,
            infoKey: 'o',
            error: vm.ownershipError,
            hint: vm.ownershipHint,
            input: AppTextField(
              controller: vm.ownership,
              suffix: '%',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: decimal,
              hasError: vm.ownershipError != null,
              semanticLabel: FounderToolsStrings.currentOwnership,
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _tabular(TextStyle style) =>
    style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

class _ResultCard extends StatefulWidget {
  const _ResultCard({required this.vm});

  final ValuationCalculatorViewModel vm;

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  // the (i) tip that's open in this card, if any
  String? _open;

  void _toggle(String key) =>
      setState(() => _open = _open == key ? null : key);

  Widget _label(String text, String key) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Flexible(
            child: Text(
              text,
              style: AppText.sans(
                size: 12,
                color: AppColors.onGreenMuted,
                letterSpacing: 0.48,
              ),
            ),
          ),
          InfoButton.light(onTap: () => _toggle(key), open: _open == key),
        ],
      ),
      if (_open == key) InfoTip(_tip(key)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final dim = vm.dealValid ? 1.0 : 0.4;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0xE617301E),
            offset: Offset(0, 18),
            blurRadius: 34,
            spreadRadius: -22,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(FounderToolsStrings.postMoney, 'post'),
          Opacity(
            opacity: dim,
            child: Text(
              vm.postText,
              style: _tabular(
                AppText.sans(
                  size: 30,
                  height: 36,
                  weight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          Text(
            vm.workText,
            style: AppText.sans(size: 13, color: AppColors.onGreenMuted),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 14),
            color: AppColors.gold.withValues(alpha: 0.75),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Two(
                  label: _label(FounderToolsStrings.preMoney, 'pre'),
                  value: vm.preText,
                  opacity: dim,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Two(
                  label: _label(FounderToolsStrings.valueOfShare, 'val'),
                  value: vm.shareText,
                  // this one needs your ownership too
                  opacity: vm.isValid ? 1.0 : 0.4,
                ),
              ),
            ],
          ),
          if (vm.valuationNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vm.valuationLower! ? '↓' : '↑',
                    style: AppText.sans(
                      size: 15,
                      height: 19,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.valuationNote!,
                      style: AppText.sans(
                        size: 13,
                        height: 19,
                        color: AppColors.onGreenMuted,
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

class _Two extends StatelessWidget {
  const _Two({required this.label, required this.value, required this.opacity});

  final Widget label;
  final String value;
  final double opacity;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      label,
      Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            value,
            style: _tabular(
              AppText.sans(
                size: 16,
                weight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _OwnershipCard extends StatefulWidget {
  const _OwnershipCard({required this.vm});

  final ValuationCalculatorViewModel vm;

  @override
  State<_OwnershipCard> createState() => _OwnershipCardState();
}

class _OwnershipCardState extends State<_OwnershipCard> {
  String? _open;

  void _toggle(String key) =>
      setState(() => _open = _open == key ? null : key);

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final rows = <(Color, String, String, double)>[
      (AppColors.moss600, FounderToolsStrings.youFounder, vm.youWork, vm.you),
      if (vm.hasOthers)
        (
          AppColors.ownershipOthers,
          FounderToolsStrings.otherOwners,
          vm.othersWork,
          vm.others,
        ),
      (
        AppColors.gold,
        FounderToolsStrings.newInvestors,
        FounderToolsStrings.equityGivenUp,
        vm.newInvestors,
      ),
    ];
    return ManageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    FounderToolsStrings.ownershipAfter,
                    style: AppText.sans(size: 17, weight: FontWeight.w700),
                  ),
                ),
              ),
              InfoButton(onTap: () => _toggle('own'), open: _open == 'own'),
            ],
          ),
          if (_open == 'own') InfoTip(_tip('own')),
          const SizedBox(height: 6),
          OwnershipBar(
            segments: [
              OwnershipSegment(vm.you, AppColors.moss600),
              OwnershipSegment(vm.others, AppColors.ownershipOthers),
              OwnershipSegment(vm.newInvestors, AppColors.gold),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(
                        top: BorderSide(color: AppColors.rowSeparator),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: rows[i].$1,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].$2,
                          style: AppText.sans(
                            size: 16,
                            weight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          rows[i].$3,
                          style: AppText.sans(
                            size: 13,
                            color: AppColors.metaText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    ValuationCalculatorViewModel.pct(rows[i].$4),
                    style: _tabular(
                      AppText.sans(size: 17, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          // the founder's dilution in points, and before → after
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        FounderToolsStrings.yourDilution,
                        style: AppText.sans(size: 13, color: AppColors.metaText),
                      ),
                    ),
                    InfoButton(
                      onTap: () => _toggle('change'),
                      open: _open == 'change',
                    ),
                  ],
                ),
                if (_open == 'change') InfoTip(_tip('change')),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      vm.dilutionText,
                      style: _tabular(
                        AppText.sans(size: 20, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          vm.ownershipChangeText,
                          style: _tabular(
                            AppText.sans(size: 13, color: AppColors.metaText),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// the (i) text for a box or result
String _tip(String key) => FounderToolsStrings.calcInfo[key]!.$2;
