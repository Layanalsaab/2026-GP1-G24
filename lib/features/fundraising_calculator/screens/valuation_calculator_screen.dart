import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/startup.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../startups/widgets/manage_card.dart';
import '../view_models/valuation_calculator_view_model.dart';

/// Valuation calculator (docs/05 D4): inputs card, green result card,
/// "Ownership after this raise" card and the note. Opened from Manage with
/// empty funding and equity (the ownership keeps its last value), or from a
/// request with [funding] and [equityPercent] pre-filled.
class ValuationCalculatorScreen extends StatefulWidget {
  const ValuationCalculatorScreen({
    super.key,
    required this.startup,
    this.funding,
    this.equityPercent,
  });

  final Startup startup;
  final int? funding;
  final double? equityPercent;

  /// Pushes the calculator (forward transition).
  static void open(
    BuildContext context, {
    required Startup startup,
    int? funding,
    double? equityPercent,
  }) {
    AppNav.push(
      context,
      ValuationCalculatorScreen(
        startup: startup,
        funding: funding,
        equityPercent: equityPercent,
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
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _info(String key) {
    final (title, text) = FounderToolsStrings.calcInfo[key]!;
    showInfoSheet(context, title: title, text: text);
  }

  @override
  Widget build(BuildContext context) {
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
              onBack: () => AppNav.back(context),
            ),
            ListenableBuilder(
              listenable: _vm,
              builder: (context, _) => OverlapList(
                gap: 12,
                children: [
                  _InputsCard(vm: _vm, startup: s, onInfo: _info),
                  _ResultCard(vm: _vm, onInfo: _info),
                  if (_vm.isValid) _OwnershipCard(vm: _vm, onInfo: _info),
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
  const _InputsCard({
    required this.vm,
    required this.startup,
    required this.onInfo,
  });

  final ValuationCalculatorViewModel vm;
  final Startup startup;
  final void Function(String key) onInfo;

  Widget _field({
    required String label,
    required String infoKey,
    required Widget input,
    required String? error,
  }) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FieldLabel(
            label,
            hasError: hasError,
            onInfoTap: () => onInfo(infoKey),
          ),
        ),
        const SizedBox(height: 6),
        input,
        FieldHelperRow(error: error),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
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
            FounderToolsStrings.thisRaise,
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
            input: MoneyField(
              controller: vm.funds,
              maxDigits: 12,
              hasError: vm.fundingError != null,
              semanticLabel: FounderToolsStrings.fundingToRaise,
            ),
          ),
          const SizedBox(height: 16),
          _field(
            label: FounderToolsStrings.equityToGive,
            infoKey: 'e',
            error: vm.equityError,
            input: AppTextField(
              controller: vm.equity,
              suffix: '%',
              maxLength: 5,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: decimal,
              hasError: vm.equityError != null,
              semanticLabel: FounderToolsStrings.equityToGive,
            ),
          ),
          const SizedBox(height: 16),
          _field(
            label: FounderToolsStrings.currentOwnership,
            infoKey: 'o',
            error: vm.ownershipError,
            input: AppTextField(
              controller: vm.ownership,
              suffix: '%',
              maxLength: 5,
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.vm, required this.onInfo});

  final ValuationCalculatorViewModel vm;
  final void Function(String key) onInfo;

  Widget _label(String text, String key) => Row(
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
      InfoButton.light(onTap: () => onInfo(key)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final dim = vm.isValid ? 1.0 : 0.4;
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
                  opacity: dim,
                ),
              ),
            ],
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

class _OwnershipCard extends StatelessWidget {
  const _OwnershipCard({required this.vm, required this.onInfo});

  final ValuationCalculatorViewModel vm;
  final void Function(String key) onInfo;

  @override
  Widget build(BuildContext context) {
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
              InfoButton(onTap: () => onInfo('own')),
            ],
          ),
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
        ],
      ),
    );
  }
}
