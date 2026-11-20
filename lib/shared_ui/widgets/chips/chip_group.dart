import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../forms/app_field.dart';
import '../forms/app_text_field.dart';
import 'app_chip.dart';

/// Wrapping group of AppChips (gap 8).
class ChipGroup extends StatelessWidget {
  const ChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onTap,
    this.otherLabel = 'Other',
    this.otherController,
    this.otherValue,
    this.onOtherChanged,
    this.otherHint,
    this.otherError,
    this.otherMax = 40,
  });

  final List<String> options;
  final Iterable<String> selected;
  final ValueChanged<String> onTap;

  final String otherLabel;
  final TextEditingController? otherController;
  final String? otherValue;
  final ValueChanged<String>? onOtherChanged;

  /// Placeholder of the write-in, e.g.
  final String? otherHint;

  /// Red line replacing "Required", e.g.
  final String? otherError;
  final int otherMax;

  bool get _showOther =>
      selected.contains(otherLabel) &&
      (otherController != null || onOtherChanged != null);

  @override
  Widget build(BuildContext context) {
    final sel = selected.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              AppChip(
                label: o,
                selected: sel.contains(o),
                onTap: () => onTap(o),
              ),
          ],
        ),
        if (_showOther) ...[
          const SizedBox(height: 10),
          OtherWriteIn(
            controller: otherController,
            value: otherValue,
            onChanged: onOtherChanged,
            hint: otherHint,
            error: otherError,
            max: otherMax,
          ),
        ],
      ],
    );
  }
}

class OtherWriteIn extends StatelessWidget {
  const OtherWriteIn({
    super.key,
    this.controller,
    this.value,
    this.onChanged,
    this.hint,
    this.error,
    this.max = 40,
  });

  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final String? error;
  final int max;

  @override
  Widget build(BuildContext context) {
    Widget inner(String text) {
      final hasError = error != null && error!.isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: controller,
            value: value,
            onChanged: onChanged,
            hint: hint,
            semanticLabel: hint ?? 'Other',
            prefix: 'Other',
            prefixStyle: AppText.sans(
              size: 14,
              weight: FontWeight.w600,
              color: AppColors.mossText,
            ),
            maxLength: max,
            hasError: hasError,
            fontSize: 15,
            dense: true,
          ),
          FieldHelperRow(error: error, hint: hasError ? null : 'Required'),
        ],
      );
    }

    if (controller != null) {
      return ListenableBuilder(
        listenable: controller!,
        builder: (context, _) => inner(controller!.text),
      );
    }
    return inner(value ?? '');
  }
}

class ChipGroupField extends StatelessWidget {
  const ChipGroupField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onTap,
    this.multi = false,
    this.required = false,
    this.error,
    this.info,
    this.infoOpen,
    this.onInfoToggle,
    this.otherLabel = 'Other',
    this.otherController,
    this.otherValue,
    this.onOtherChanged,
    this.otherHint,
    this.otherError,
    this.otherMax = 40,
    this.sentenceCase = false,
  });

  /// Label as written (see FieldLabel.sentenceCase).
  final bool sentenceCase;

  final String label;
  final List<String> options;
  final Iterable<String> selected;
  final ValueChanged<String> onTap;

  /// Multi choice shows the "Select all that apply · N selected" sub-text.
  final bool multi;
  final bool required;
  final String? error;
  final String? info;
  final bool? infoOpen;
  final VoidCallback? onInfoToggle;
  final String otherLabel;
  final TextEditingController? otherController;
  final String? otherValue;
  final ValueChanged<String>? onOtherChanged;
  final String? otherHint;
  final String? otherError;
  final int otherMax;

  @override
  Widget build(BuildContext context) {
    final count = selected.length;
    return AppField(
      label: label,
      required: required,
      sentenceCase: sentenceCase,
      info: info,
      infoOpen: infoOpen,
      onInfoToggle: onInfoToggle,
      error: error,
      subLabel: multi ? 'Select all that apply · $count selected' : null,
      child: ChipGroup(
        options: options,
        selected: selected,
        onTap: onTap,
        otherLabel: otherLabel,
        otherController: otherController,
        otherValue: otherValue,
        onOtherChanged: onOtherChanged,
        otherHint: otherHint,
        otherError: otherError,
        otherMax: otherMax,
      ),
    );
  }
}
