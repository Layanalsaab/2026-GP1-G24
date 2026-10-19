import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../buttons/app_button.dart';
import 'app_bottom_sheet.dart';

/// Result of a [PickerSheet].
class PickerResult {
  const PickerResult(this.value, {this.otherText});

  /// The chosen option label (the "Other" label itself when written in).
  final String value;

  /// The write-in text when [value] is the "Other" option.
  final String? otherText;
}

/// Opens a [PickerSheet] and completes with the pick, or null when dismissed.
///
/// * [selected] / [otherText] pre-select the current value.
/// * [searchHint] non-null shows the search field ("Search cities") and makes
///   the sheet tall; [noResultsText] is shown when nothing matches.
/// * [otherNoun] non-null enables the "Other" option with a write-in field
///   (placeholder "Describe your other NOUN", blank error
///   "Please type your NOUN — it can’t be blank.").
/// * [onUndoOther] runs when the sheet closes with "Other" picked but blank,
///   so the caller can undo that pick.
Future<PickerResult?> showPickerSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
  String? otherText,
  String? searchHint,
  String noResultsText = 'No results found',
  String? otherNoun,
  String otherLabel = 'Other',
  int otherMax = 40,
  VoidCallback? onUndoOther,
  bool tall = false,
}) {
  return showAppBottomSheet<PickerResult>(
    context,
    builder: (_) => PickerSheet(
      title: title,
      options: options,
      selected: selected,
      otherText: otherText,
      searchHint: searchHint,
      noResultsText: noResultsText,
      otherNoun: otherNoun,
      otherLabel: otherLabel,
      otherMax: otherMax,
      onUndoOther: onUndoOther,
      tall: tall,
    ),
  );
}

/// Searchable single-select picker (prototype `sheet.isList`): option rows
/// (min 50, radius 12, 16 px; selected = moss100 fill, green 600 text and a
/// Pop check), optional search field, optional "Other" write-in with an n/40
/// counter and "Required"/error line, and a Done button while the write-in is
/// open. Normally opened with [showPickerSheet].
class PickerSheet extends StatefulWidget {
  const PickerSheet({
    super.key,
    required this.title,
    required this.options,
    this.selected,
    this.otherText,
    this.searchHint,
    this.noResultsText = 'No results found',
    this.otherNoun,
    this.otherLabel = 'Other',
    this.otherMax = 40,
    this.onUndoOther,
    this.tall = false,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final String? otherText;
  final String? searchHint;
  final String noResultsText;
  final String? otherNoun;
  final String otherLabel;
  final int otherMax;
  final VoidCallback? onUndoOther;
  final bool tall;

  @override
  State<PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<PickerSheet> {
  late String? _selected = widget.selected;
  late final TextEditingController _other = TextEditingController(
    text: widget.otherText ?? '',
  );
  final TextEditingController _query = TextEditingController();
  bool _showError = false;
  bool _committed = false;

  bool get _hasOther => widget.otherNoun != null;
  bool get _otherOpen => _hasOther && _selected == widget.otherLabel;

  @override
  void dispose() {
    _other.dispose();
    _query.dispose();
    super.dispose();
  }

  void _pick(String option) {
    if (_hasOther && option == widget.otherLabel) {
      setState(() => _selected = option);
      return;
    }
    _committed = true;
    Navigator.of(context).pop(PickerResult(option));
  }

  void _done() {
    if (_other.text.trim().isEmpty) {
      setState(() => _showError = true);
      return;
    }
    _committed = true;
    Navigator.of(context)
        .pop(PickerResult(widget.otherLabel, otherText: _other.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final shown = [
      for (final o in widget.options)
        // The sheet adds its own "Other" row last, so a list that already
        // ends in "Other" must not show it twice.
        if (!(_hasOther && o == widget.otherLabel) &&
            (q.isEmpty || o.toLowerCase().contains(q)))
          o,
    ];
    final all = [...shown, if (_hasOther) widget.otherLabel];
    // Only a searchable (long) list is pinned tall. A short list, such as the
    // commerce model, fits its content and grows by the write-in field when
    // "Other" is picked, so there is never an empty gap under it.
    final tall = widget.tall || widget.searchHint != null;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_committed && _otherOpen && _other.text.trim().isEmpty) {
          widget.onUndoOther?.call();
        }
      },
      child: AppSheetScaffold(
        title: widget.title,
        tall: tall,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.searchHint != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: _SearchField(
                  controller: _query,
                  hint: widget.searchHint!,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                children: [
                  for (final o in all)
                    _OptionRow(
                      label: o,
                      selected: o == _selected,
                      onTap: () => _pick(o),
                    ),
                  if (shown.isEmpty && !_hasOther)
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
                      padding: const EdgeInsets.only(top: 8),
                      child: _OtherField(
                        controller: _other,
                        placeholder: 'Describe your other ${widget.otherNoun}',
                        max: widget.otherMax,
                        error: _showError && _other.text.trim().isEmpty
                            ? 'Please type your ${widget.otherNoun} — it can’t be blank.'
                            : null,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                ],
              ),
            ),
            if (_otherOpen)
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

class _OptionRow extends StatefulWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  bool _hover = false;

  String get label => widget.label;
  bool get selected => widget.selected;
  VoidCallback get onTap => widget.onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.dur(context, const Duration(milliseconds: 160)),
            curve: Curves.ease,
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.moss100
                  : (_hover ? AppColors.moss50 : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppText.sans(
                      size: 16,
                      color: selected ? AppColors.green : AppColors.ink,
                      weight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  const Pop(
                    child: AppIcon.filled(
                      AppIcons.check,
                      size: 20,
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      decoration: BoxDecoration(
        color: AppColors.mutedFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: AppIcon.filled(
              AppIcons.search,
              size: 20,
              color: AppColors.grey,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppText.sans(size: 15),
              cursorColor: AppColors.moss600,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppText.sans(size: 15, color: AppColors.placeholder),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny private text field for the "Other" write-in: white, 1 px
/// `#8C918D` border radius 12 (moss600 + ring on focus, red when [error]),
/// helper row "Required" / error on the left and `n/max` on the right.
class _OtherField extends StatefulWidget {
  const _OtherField({
    required this.controller,
    required this.placeholder,
    required this.max,
    required this.onChanged,
    this.error,
  });

  final TextEditingController controller;
  final String placeholder;
  final int max;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  State<_OtherField> createState() => _OtherFieldState();
}

class _OtherFieldState extends State<_OtherField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final err = widget.error != null;
    final focused = _focus.hasFocus;
    final border = err
        ? AppColors.error
        : focused
        ? AppColors.moss600
        : AppColors.borderStrong;
    final ring = err
        ? const Color(0x1FB3261E)
        : focused
        ? const Color(0x262F5D3A)
        : Colors.transparent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: Motion.dur(context, const Duration(milliseconds: 160)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
            boxShadow: [BoxShadow(color: ring, spreadRadius: 3)],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            onChanged: widget.onChanged,
            inputFormatters: [LengthLimitingTextInputFormatter(widget.max)],
            style: AppText.input,
            cursorColor: AppColors.moss600,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: AppText.placeholder,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (err)
              Expanded(
                child: Row(
                  children: [
                    const AppIcon.filled(
                      AppIcons.error,
                      size: 14,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: Text(widget.error!, style: AppText.error)),
                  ],
                ),
              )
            else
              Text('Required', style: AppText.helper),
            const SizedBox(width: 8),
            Text(
              '${widget.controller.text.length}/${widget.max}',
              style: AppText.helper,
            ),
          ],
        ),
      ],
    );
  }
}
