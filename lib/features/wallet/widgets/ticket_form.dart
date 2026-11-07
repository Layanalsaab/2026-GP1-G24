import 'package:flutter/material.dart';

import '../../../app_constants/wallet_strings.dart';
import '../../../models/investor_criteria.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../../../shared_ui/widgets/overlays/multi_picker_sheet.dart';
import '../../login_and_signup/view_models/investor_onboarding_view_model.dart';
import '../../startups/widgets/founder_ui.dart';
import '../view_models/wallet_view_model.dart';

/// The Add ticket / Edit ticket form: a light green box like the round form,
/// with the same field spacing, errors and buttons.
///
/// [editing] false: "New ticket" with "Cancel" / "Add ticket", above the
/// tickets table. [editing] true: "Edit ticket" with the current values and
/// "Cancel" / "Save changes", on the ticket page.
///
/// Add and Save go through the confirm dialog (only when the form is valid);
/// Cancel after a change asks "Discard changes?".
class TicketForm extends StatelessWidget {
  const TicketForm({super.key, required this.vm, this.editing = false});

  final WalletViewModel vm;
  final bool editing;

  /// The sector and stage lists of sign-up.
  static final sectorOptions = InvestorOnboardingViewModel.sectorOptions;
  static const stageOptions = InvestorCriteria.stageOptions;

  Future<void> _pickSectors(BuildContext context) => showMultiPickerSheet(
    context,
    title: WalletStrings.sectorsLabel,
    options: sectorOptions,
    selected: vm.sectors,
    onToggle: vm.toggleSector,
    searchHint: 'Search sectors',
    // The same "Other" box as everywhere: typing something that is already
    // in the list ticks that sector instead.
    otherNoun: 'sector',
    otherHint: 'Type a sector, e.g. SportsTech',
    otherText: vm.sectorOther,
    onOtherChanged: vm.setSectorOther,
    onUndoOther: vm.undoSectorOther,
  );

  Future<void> _pickStages(BuildContext context) => showMultiPickerSheet(
    context,
    title: WalletStrings.stagesLabel,
    options: stageOptions,
    selected: vm.stages,
    onToggle: vm.toggleStage,
  );

  Future<void> _cancel(BuildContext context) async {
    if (vm.formDirty) {
      final discard = await showDiscardDialog(
        context,
        title: WalletStrings.discardTitle,
        message: WalletStrings.discardMessage,
        discardLabel: WalletStrings.discard,
        keepLabel: WalletStrings.keepEditing,
      );
      if (!discard) return;
    }
    vm.cancelForm();
  }

  Future<void> _submit(BuildContext context) async {
    // Invalid: the field errors show first, no confirm.
    if (!vm.formValid) {
      await vm.submit();
      return;
    }
    final go = await showSaveConfirmDialog(
      context,
      title: editing ? WalletStrings.saveTitle : WalletStrings.addTitle,
      message: editing ? WalletStrings.saveMessage : WalletStrings.addMessage,
      confirmLabel: editing
          ? WalletStrings.saveChanges
          : WalletStrings.addTicket,
    );
    if (!go || !context.mounted) return;
    final ok = await vm.submit();
    if (!context.mounted) return;
    if (!ok && vm.error != null) {
      AppToast.error(context, vm.error!);
    } else if (ok) {
      AppToast.confirm(
        context,
        editing ? WalletStrings.ticketSaved : WalletStrings.ticketAdded,
      );
    }
  }

  /// The chosen sectors; "Other" shows what was typed.
  String _sectorsText() => [
    for (final o in sectorOptions)
      if (vm.sectors.contains(o))
        o == 'Other' && vm.sectorOther.trim().isNotEmpty
            ? vm.sectorOther.trim()
            : o,
  ].join(', ');

  String _list(Set<String> chosen, List<String> order) => [
    for (final o in order)
      if (chosen.contains(o)) o,
  ].join(', ');

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
              editing ? WalletStrings.editTicket : WalletStrings.newTicket,
              style: AppText.sans(
                size: 17,
                weight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppField(
            label: WalletStrings.nameLabel,
            required: true,
            sentenceCase: true,
            error: vm.nameError,
            child: AppTextField(
              controller: vm.name,
              maxLength: 40,
              hasError: vm.nameError != null,
              semanticLabel: WalletStrings.nameLabel,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(height: FieldHelperRow.gapAfter),
          AppField(
            label: WalletStrings.sectorsLabel,
            required: true,
            sentenceCase: true,
            error: vm.sectorsError,
            child: SelectField(
              placeholder: WalletStrings.sectorsPlaceholder,
              value: _sectorsText(),
              hasError: vm.sectorsError != null,
              semanticLabel: WalletStrings.sectorsLabel,
              onTap: () => _pickSectors(context),
            ),
          ),
          const SizedBox(height: FieldHelperRow.gapAfter),
          AppField(
            label: WalletStrings.stagesLabel,
            required: true,
            sentenceCase: true,
            error: vm.stagesError,
            child: SelectField(
              placeholder: WalletStrings.stagesPlaceholder,
              value: _list(vm.stages, stageOptions),
              hasError: vm.stagesError != null,
              semanticLabel: WalletStrings.stagesLabel,
              onTap: () => _pickStages(context),
            ),
          ),
          const SizedBox(height: FieldHelperRow.gapAfter),
          AppField(
            label: WalletStrings.minLabel,
            required: true,
            sentenceCase: true,
            error: vm.minError,
            child: MoneyField(
              controller: vm.min,
              hasError: vm.minError != null,
              semanticLabel: WalletStrings.minLabel,
            ),
          ),
          const SizedBox(height: FieldHelperRow.gapAfter),
          AppField(
            label: WalletStrings.maxLabel,
            required: true,
            sentenceCase: true,
            error: vm.maxError,
            child: MoneyField(
              controller: vm.max,
              hasError: vm.maxError != null,
              semanticLabel: WalletStrings.maxLabel,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: WalletStrings.cancel,
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.small,
                  onPressed: () => _cancel(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: editing
                      ? WalletStrings.saveChanges
                      : WalletStrings.addTicket,
                  variant: vm.formValid
                      ? AppButtonVariant.primary
                      : AppButtonVariant.off,
                  size: AppButtonSize.small,
                  onPressed: () => _submit(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
