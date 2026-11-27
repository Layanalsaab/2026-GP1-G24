import 'dart:async';

import 'package:flutter/material.dart';

import '../../../helpers/other_check.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../buttons/app_button.dart';
import '../forms/app_text_field.dart';
import '../forms/no_emoji_formatter.dart';
import 'app_bottom_sheet.dart';

/// Result of a PickerSheet.
class PickerResult {
  const PickerResult(this.value, {this.otherText});

  /// The chosen option label (the "Other" label itself when written in).
  final String value;

  /// The write-in text when value is the "Other" option.
  final String? otherText;
}

/// Opens a PickerSheet and completes with the pick, or null when dismissed.
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
  Map<String, String> alsoCountsAs = const {},
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
      alsoCountsAs: alsoCountsAs,
      tall: tall,
    ),
  );
}

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
    this.alsoCountsAs = const {},
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

  /// Other texts that mean a listed option (e.g.
  final Map<String, String> alsoCountsAs;

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

  Timer? _pause;
  static const _pauseAfterTyping = Duration(milliseconds: 500);

  /// The listed option the write-in repeats; it shows as selected.
  String? get _match {
    if (!_otherOpen) return null;
    final m = OtherCheck.match(
      _other.text,
      widget.options,
      alsoCountsAs: widget.alsoCountsAs,
    );
    return m == widget.otherLabel ? null : m;
  }

  void _autoPick() {
    _pause?.cancel();
    final match = _match;
    if (match == null || _committed || !mounted) return;
    _committed = true;
    Navigator.of(context).pop(PickerResult(match));
  }

  @override
  void dispose() {
    _pause?.cancel();
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
    final match = _match;
    if (match != null) {
      _committed = true;
      Navigator.of(context).pop(PickerResult(match));
      return;
    }
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
        if (!(_hasOther && o == widget.otherLabel) &&
            (q.isEmpty || o.toLowerCase().contains(q)))
          o,
    ];
    final all = [...shown, if (_hasOther) widget.otherLabel];
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
                child: PickerSearchField(
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
                    PickerOptionRow(
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
                      child: PickerOtherField(
                        controller: _other,
                        placeholder: 'Describe your other ${widget.otherNoun}',
                        max: widget.otherMax,
                        error: _showError && _other.text.trim().isEmpty
                            ? 'Please type your ${widget.otherNoun} — it can’t be blank.'
                            : null,
                        onChanged: (_) {
                          setState(() {});
                          _pause?.cancel();
                          _pause = Timer(_pauseAfterTyping, _autoPick);
                        },
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

/// One option row of a picker sheet: tint and a green check when selected.
class PickerOptionRow extends StatefulWidget {
  const PickerOptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<PickerOptionRow> createState() => PickerOptionRowState();
}

class PickerOptionRowState extends State<PickerOptionRow> {
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
                      color: selected ? AppColors.greenText : AppColors.ink,
                      weight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  Pop(
                    child: AppIcon.filled(
                      AppIcons.check,
                      size: 20,
                      color: AppColors.mossText,
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

/// The grey search box at the top of a picker sheet.
class PickerSearchField extends StatelessWidget {
  const PickerSearchField({
    super.key,
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
          Padding(
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
              inputFormatters: const [NoEmojiFormatter()],
              textInputAction: TextInputAction.search,
              style: AppText.sans(size: 15),
              cursorColor: AppColors.mossText,
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

class PickerOtherField extends StatefulWidget {
  const PickerOtherField({
    super.key,
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
  State<PickerOtherField> createState() => PickerOtherFieldState();
}

class PickerOtherFieldState extends State<PickerOtherField> {
  final FocusNode _focus = FocusNode();
  bool _over = false;

  void _setOver(bool v) {
    if (mounted && v != _over) setState(() => _over = v);
  }

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
    final error = widget.error ?? (_over ? maxLengthMessage(widget.max) : null);
    final err = error != null;
    final focused = _focus.hasFocus;
    final count = widget.controller.text.characters.length;
    final border = err
        ? AppColors.error
        : focused
        ? AppColors.mossText
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
            inputFormatters: [
              const NoEmojiFormatter(),
              MaxLengthFormatter(widget.max, _setOver),
            ],
            style: AppText.input,
            cursorColor: AppColors.mossText,
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
                    AppIcon.filled(
                      AppIcons.error,
                      size: 14,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: Text(error, style: AppText.error)),
                  ],
                ),
              )
            else
              Text('Required', style: AppText.helper),
            const SizedBox(width: 8),
            Text(
              '$count/${widget.max}',
              style: widget.max - count <= 10
                  ? AppText.helper.copyWith(color: AppColors.error)
                  : AppText.helper,
            ),
          ],
        ),
      ],
    );
  }
}
