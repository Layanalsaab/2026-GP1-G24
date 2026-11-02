import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/startup_enums.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../view_models/rounds_view_model.dart';
import 'founder_ui.dart';

/// The Add round / Edit round form: a light green box with the same three
/// fields (Round type, How much are you raising?, How much have you already
/// raised in this round?), the same limits, hints and errors.
///
/// [editing] false: "New round · Round N", buttons "Cancel" / "Add round",
/// above the rounds table. [editing] true: "Edit round · Round N" with the
/// current values, buttons "Cancel" / "Save changes", on the round page.
///
/// Save and Add go through the confirm dialog (only when the form is valid);
/// Cancel with a changed value asks "Discard changes?".
class RoundForm extends StatelessWidget {
  const RoundForm({super.key, required this.vm, this.editing = false});

  final RoundsViewModel vm;
  final bool editing;

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

  /// Cancel: with a changed value the "Discard changes?" dialog asks first;
  /// with none the form just closes.
  Future<void> _cancel(BuildContext context) async {
    if (vm.formDirty) {
      final discard = await showDiscardDialog(
        context,
        title: FounderToolsStrings.discardEditTitle,
        message: FounderToolsStrings.discardEditMessage,
        discardLabel: FounderToolsStrings.discard,
        keepLabel: FounderToolsStrings.keepEditing,
      );
      if (!discard) return;
    }
    editing ? vm.cancelEdit() : vm.cancelForm();
  }

  Future<void> _submit(BuildContext context) async {
    // Invalid: the field errors show first, no confirm.
    if (!vm.formValid) {
      editing ? await vm.saveEdit() : await vm.addRound();
      return;
    }
    final go = await showSaveConfirmDialog(
      context,
      title: editing
          ? FounderToolsStrings.saveConfirmTitle
          : FounderToolsStrings.addRoundTitle,
      message: editing
          ? FounderToolsStrings.saveRoundMessage
          : FounderToolsStrings.addRoundMessage,
      confirmLabel: editing
          ? FounderToolsStrings.saveConfirmButton
          : FounderToolsStrings.addRoundButton,
    );
    if (!go || !context.mounted) return;
    final ok = editing ? await vm.saveEdit() : await vm.addRound();
    if (!context.mounted) return;
    if (!ok && vm.error != null) {
      AppToast.error(context, vm.error!);
    } else if (ok && editing) {
      AppToast.confirm(context, FounderToolsStrings.roundUpdated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = editing ? vm.editing?.number : vm.nextNumber;
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
              editing
                  ? 'Edit round · Round $number'
                  : 'New round · Round $number',
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.small,
                  onPressed: () => _cancel(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: editing
                      ? FounderToolsStrings.saveConfirmButton
                      : FounderToolsStrings.addRoundButton,
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
