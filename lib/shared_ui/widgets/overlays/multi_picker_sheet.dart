import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../buttons/app_button.dart';
import 'app_bottom_sheet.dart';
import 'picker_sheet.dart';

/// Opens a [MultiPickerSheet]. Every tick is reported at once through
/// [onToggle] / [onOtherChanged], so the caller's state is always current,
/// whether the sheet is closed with Done, by tapping outside or by dragging
/// it away. [onUndoOther] runs when the sheet closes with "Other" ticked but
/// its write-in blank (the caller unticks it).
Future<void> showMultiPickerSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  required Set<String> selected,
  required ValueChanged<String> onToggle,
  String? searchHint,
  String noResultsText = 'No results found',
  String otherLabel = 'Other',
  String? otherNoun,
  String? otherHint,
  String otherText = '',
  ValueChanged<String>? onOtherChanged,
  VoidCallback? onUndoOther,
  int otherMax = 40,
}) {
  // The same bottom sheet as the Sector / Stage / Commerce model pickers.
  return showAppBottomSheet<void>(
    context,
    builder: (_) => MultiPickerSheet(
      title: title,
      options: options,
      selected: selected,
      onToggle: onToggle,
      searchHint: searchHint,
      noResultsText: noResultsText,
      otherLabel: otherLabel,
      otherNoun: otherNoun,
      otherHint: otherHint,
      otherText: otherText,
      onOtherChanged: onOtherChanged,
      onUndoOther: onUndoOther,
      otherMax: otherMax,
    ),
  );
}

/// Searchable multi-select sheet: a checkbox per row (22 px square, radius 6,
/// 2 px `#8C918D` border; ticked = green fill and a white check that fades
/// and scales in), an optional "Other" write-in and a Done button.
class MultiPickerSheet extends StatefulWidget {
  const MultiPickerSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.searchHint,
    this.noResultsText = 'No results found',
    this.otherLabel = 'Other',
    this.otherNoun,
    this.otherHint,
    this.otherText = '',
    this.onOtherChanged,
    this.onUndoOther,
    this.otherMax = 40,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String? searchHint;
  final String noResultsText;
  final String otherLabel;
  final String? otherNoun;
  final String? otherHint;
  final String otherText;
  final ValueChanged<String>? onOtherChanged;
  final VoidCallback? onUndoOther;
  final int otherMax;

  @override
  State<MultiPickerSheet> createState() => _MultiPickerSheetState();
}

class _MultiPickerSheetState extends State<MultiPickerSheet> {
  late final Set<String> _selected = {...widget.selected};
  late final TextEditingController _other = TextEditingController(
    text: widget.otherText,
  );
  final TextEditingController _query = TextEditingController();
  bool _showError = false;

  bool get _hasOther => widget.otherNoun != null;

  /// Like the Sector / Stage / Commerce model pickers: only a list with a
  /// search box is pinned tall; a short one fits its content and grows by the
  /// "Other" write-in when that is ticked.
  bool get _tall => widget.searchHint != null;

  bool get _otherOpen => _hasOther && _selected.contains(widget.otherLabel);
  bool get _otherBlank => _other.text.trim().isEmpty;

  @override
  void dispose() {
    _other.dispose();
    _query.dispose();
    super.dispose();
  }

  void _toggle(String option) {
    setState(() {
      if (!_selected.remove(option)) _selected.add(option);
      _showError = false;
    });
    widget.onToggle(option);
  }

  void _done() {
    if (_otherOpen && _otherBlank) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final shown = [
      for (final o in widget.options)
        if (q.isEmpty ||
            o.toLowerCase().contains(q) ||
            o == widget.otherLabel && 'other'.contains(q))
          o,
    ];
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _otherOpen && _otherBlank) widget.onUndoOther?.call();
      },
      child: AppSheetScaffold(
        title: widget.title,
        tall: _tall,
        child: Column(
          mainAxisSize: _tall ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.searchHint != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: PickerSearchField(
                  controller: _query,
                  hint: widget.searchHint!,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            Flexible(
              fit: _tall ? FlexFit.tight : FlexFit.loose,
              child: ListView(
                shrinkWrap: !_tall,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                children: [
                  for (final o in shown)
                    _CheckRow(
                      label: o,
                      checked: _selected.contains(o),
                      onTap: () => _toggle(o),
                    ),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        widget.noResultsText,
                        textAlign: TextAlign.center,
                        style: AppText.sans(size: 14, color: AppColors.grey),
                      ),
                    ),
                  if (_otherOpen)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                      child: PickerOtherField(
                        controller: _other,
                        placeholder:
                            widget.otherHint ??
                            'Describe your other ${widget.otherNoun}',
                        max: widget.otherMax,
                        error: _showError && _otherBlank
                            ? 'Please type your ${widget.otherNoun} — it can’t be blank.'
                            : null,
                        onChanged: (v) {
                          setState(() {});
                          widget.onOtherChanged?.call(v);
                        },
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: AppButton(label: 'Done', onPressed: _done),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatefulWidget {
  const _CheckRow({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  State<_CheckRow> createState() => _CheckRowState();
}

class _CheckRowState extends State<_CheckRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final checked = widget.checked;
    final dur = Motion.dur(context, const Duration(milliseconds: 160));
    return Semantics(
      checked: checked,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: dur,
            curve: Curves.ease,
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: checked
                  ? AppColors.moss100
                  : (_hover ? AppColors.moss50 : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: dur,
                  curve: Curves.ease,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: checked ? AppColors.moss600 : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: checked
                          ? AppColors.moss600
                          : AppColors.borderStrong,
                      width: 2,
                    ),
                  ),
                  child: AnimatedScale(
                    duration: dur,
                    curve: Curves.easeOut,
                    scale: checked ? 1 : 0.5,
                    child: AnimatedOpacity(
                      duration: dur,
                      opacity: checked ? 1 : 0,
                      child: const Center(
                        child: AppIcon.filled(
                          AppIcons.check,
                          size: 16,
                          color: AppColors.onDark,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppText.sans(
                      size: 16,
                      color: checked ? AppColors.green : AppColors.ink,
                      weight: checked ? FontWeight.w600 : FontWeight.w400,
                    ),
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
