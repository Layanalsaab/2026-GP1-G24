import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'app_field.dart';

/// The input box of the design system (`.inp`): min height 50, white, 1 px
/// `#8C918D` border, radius 12, text 16/24 with padding 12 14. Focus: moss600
/// border + 3 px ring; error: red border + ring; [valid]: moss600 border and a
/// popping check at the right (never together with an error). Border/ring
/// animate over 160 ms.
///
/// Two ways to feed it: a [controller] (owned by a view model; the field never
/// disposes it), or [value] + [onChanged] (the field keeps its own
/// controller and follows [value] when it changes from outside).
///
/// [prefix] ("+966", "SAR", "Other") shows before the text followed by a
/// 1 x 24 divider; [suffix] ("%") shows after it behind a divider; [password]
/// adds the 44 px show/hide eye. [multiline] makes a fixed [rows]-row
/// textarea. The text is cut at [maxLength] (the counter lives in the
/// surrounding [AppField] / [LabeledTextField]). [dense] is the 46 px money
/// box of the trio rows.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.hint,
    this.semanticLabel,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.multiline = false,
    this.rows = 4,
    this.prefix,
    this.prefixStyle,
    this.suffix,
    this.password = false,
    this.valid = false,
    this.hasError = false,
    this.enabled = true,
    this.focusNode,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.dense = false,
    this.autofocus = false,
    this.tabularFigures = false,
    this.fontSize = 16,
    this.counterOf,
    this.counterMax,
    this.showCounter = true,
    this.warnLow = true,
    this.onOverflow,
  }) : assert(
         controller == null || value == null,
         'Pass either a controller or a value, not both.',
       );

  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Placeholder text (`#4F5751`).
  final String? hint;

  /// Screen-reader label (the visible label lives outside the box).
  final String? semanticLabel;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  /// Hard limit; extra characters are cut.
  final int? maxLength;
  final bool multiline;
  final int rows;
  final String? prefix;
  final TextStyle? prefixStyle;
  final String? suffix;
  final bool password;

  /// Shows the "ok" check and the moss600 border (field has an ok rule and
  /// its value is valid).
  final bool valid;
  final bool hasError;
  final bool enabled;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  /// 46 px high box with 10 px padding (trio money rows).
  final bool dense;
  final bool autofocus;
  final bool tabularFigures;
  final double fontSize;

  /// Counts something other than the characters (the phone: digits only).
  final int Function(String text)? counterOf;

  /// The limit shown in the counter when it is not [maxLength] (phone: 9).
  final int? counterMax;

  /// False hides the on-border counter (it is never shown on passwords).
  final bool showCounter;

  /// Turns the counter red when 10 or fewer characters are left.
  final bool warnLow;

  /// Told true when a paste or typing went past [maxLength] (the extra is
  /// cut) and false on the next edit that stays within it.
  final ValueChanged<bool>? onOverflow;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  late FocusNode _focus;
  bool _ownController = false;
  bool _ownFocus = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _bindController();
    _bindFocus();
  }

  void _bindController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownController = false;
    } else {
      _controller = TextEditingController(text: widget.value ?? '');
      _ownController = true;
    }
  }

  void _bindFocus() {
    if (widget.focusNode != null) {
      _focus = widget.focusNode!;
      _ownFocus = false;
    } else {
      _focus = FocusNode();
      _ownFocus = true;
    }
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(AppTextField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (_ownController) _controller.dispose();
      _bindController();
    } else if (_ownController &&
        widget.value != null &&
        widget.value != _controller.text) {
      final v = widget.value!;
      _controller.value = TextEditingValue(
        text: v,
        selection: TextSelection.collapsed(offset: v.length),
      );
    }
    if (old.focusNode != widget.focusNode) {
      _focus.removeListener(_onFocus);
      if (_ownFocus) _focus.dispose();
      _bindFocus();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (_ownFocus) _focus.dispose();
    if (_ownController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final focused = _focus.hasFocus;
    final showCheck = w.valid && !w.hasError;
    final Color border;
    final Color ring;
    if (w.hasError) {
      border = AppColors.error;
      ring = AppColors.errorRing;
    } else if (focused) {
      border = AppColors.moss600;
      ring = AppColors.focusRing;
    } else if (showCheck) {
      border = AppColors.moss600;
      ring = const Color(0x00000000);
    } else {
      border = AppColors.borderStrong;
      ring = const Color(0x00000000);
    }

    final vPad = w.dense ? 10.0 : 12.0;
    final hPad = w.dense ? 10.0 : 14.0;
    var textStyle = AppText.sans(
      size: w.fontSize,
      height: w.fontSize == 16 ? 24 : null,
      tabular: w.tabularFigures || w.dense,
    );
    if (!w.enabled) textStyle = textStyle.copyWith(color: AppColors.grey);

    final formatters = <TextInputFormatter>[
      ...?w.inputFormatters,
      if (w.maxLength != null) _MaxLengthFormatter(w.maxLength!, w.onOverflow),
    ];

    final field = Semantics(
      label: w.semanticLabel,
      textField: true,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        enabled: w.enabled,
        autofocus: w.autofocus,
        onChanged: w.onChanged,
        onSubmitted: w.onSubmitted,
        keyboardType: w.multiline ? TextInputType.multiline : w.keyboardType,
        textInputAction:
            w.textInputAction ?? (w.multiline ? TextInputAction.newline : null),
        textCapitalization: w.textCapitalization,
        inputFormatters: formatters,
        autofillHints: w.autofillHints,
        obscureText: w.password && _obscure,
        enableSuggestions: !w.password,
        autocorrect: !w.password,
        minLines: w.multiline ? w.rows : 1,
        maxLines: w.multiline ? w.rows : 1,
        style: textStyle,
        cursorColor: AppColors.moss600,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: false,
          counterText: '',
          hintText: w.hint,
          hintStyle: textStyle.copyWith(color: AppColors.placeholder),
          contentPadding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: vPad,
          ),
        ),
      ),
    );

    final minHeight = w.dense ? 46.0 : 50.0;
    final children = <Widget>[
      if (w.prefix != null && !w.multiline)
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                w.prefix!,
                style: w.prefixStyle ?? AppText.sans(size: 16, height: 24),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 24, color: AppColors.border),
            ],
          ),
        ),
      Expanded(child: field),
      if (w.suffix != null && !w.multiline)
        SizedBox(
          height: minHeight - 2,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: Text(
                  w.suffix!,
                  style: AppText.sans(size: 16, color: AppColors.grey),
                ),
              ),
            ),
          ),
        ),
      if (w.password)
        Semantics(
          button: true,
          label: _obscure ? 'Show password' : 'Hide password',
          excludeSemantics: true,
          child: Pressable(
            scale: PressScale.icon,
            hoverColor: const Color(0x0F1F3F27),
            hoverDuration: AppDur.fast,
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _obscure = !_obscure),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: AppIcon.filled(
                  _obscure ? AppIcons.eye : AppIcons.eyeOff,
                  size: 20,
                  color: AppColors.grey,
                ),
              ),
            ),
          ),
        ),
      if (showCheck)
        SizedBox(
          width: 44,
          child: Center(
            child: Pop(
              key: const ValueKey('ok-check'),
              child: AppIcon.filled(
                AppIcons.check,
                size: 20,
                color: AppColors.moss600,
              ),
            ),
          ),
        ),
    ];

    final limit = w.counterMax ?? w.maxLength;
    final showCounter = w.showCounter && !w.password && limit != null;
    final fill = w.enabled ? AppColors.surface : AppColors.mutedFill;

    final box = AnimatedContainer(
      duration: Motion.dur(context, const Duration(milliseconds: 160)),
      curve: Curves.ease,
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: w.enabled ? AppColors.surface : AppColors.mutedFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: ring, spreadRadius: 3)],
      ),
      child: Row(
        crossAxisAlignment: w.multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: children,
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: w.enabled ? _focus.requestFocus : null,
      child: !showCounter
          ? box
          : Stack(
              clipBehavior: Clip.none,
              children: [
                box,
                // "typed/max" sits on the bottom border, 12 px from the right
                // edge, its background notching the line. Only while the
                // field is focused.
                Positioned(
                  right: 12,
                  bottom: -8,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: Motion.dur(
                        context,
                        const Duration(milliseconds: 160),
                      ),
                      opacity: focused ? 1 : 0,
                      child: ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) {
                          final text = _controller.text;
                          final count = (w.counterOf ?? (t) => t.length)(text);
                          final low = w.warnLow && limit - count <= 10;
                          return Container(
                            height: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            color: fill,
                            alignment: Alignment.center,
                            child: Text(
                              '$count/$limit',
                              style: AppText.sans(
                                size: 12,
                                height: 16,
                                weight: FontWeight.w500,
                                tabular: true,
                                color: low ? AppColors.error : AppColors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Cuts text at [max] characters (like a length limit) and reports through
/// [onOverflow] whether the edit tried to go past it.
class _MaxLengthFormatter extends TextInputFormatter {
  _MaxLengthFormatter(this.max, this.onOverflow);

  final int max;
  final ValueChanged<bool>? onOverflow;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final over = newValue.text.characters.length > max;
    // Told on every edit (not only when it changes): this formatter is made
    // again on every rebuild, so it can't remember the last value, and the
    // red "Maximum N characters" line must clear as soon as the text is
    // back within the limit. The field ignores repeats of the same value.
    if (onOverflow != null) {
      // Not during the framework's editing callback: tell the field after.
      WidgetsBinding.instance
        ..addPostFrameCallback((_) => onOverflow!(over))
        ..ensureVisualUpdate();
    }
    if (!over) return newValue;
    return LengthLimitingTextInputFormatter(max)
        .formatEditUpdate(oldValue, newValue);
  }
}

/// Holds the "went past the limit" flag of one [LabeledTextField].
class _OverflowFlag extends StatefulWidget {
  const _OverflowFlag({required this.builder});

  final Widget Function(BuildContext context, bool over, ValueChanged<bool> set)
  builder;

  @override
  State<_OverflowFlag> createState() => _OverflowFlagState();
}

class _OverflowFlagState extends State<_OverflowFlag> {
  bool _over = false;

  void _set(bool v) {
    if (mounted && v != _over) setState(() => _over = v);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _over, _set);
}

/// [AppField] + [AppTextField] in one widget for the common case: label,
/// optional info tip, the input, error / hint and an automatic `n/max`
/// counter (from the controller or [value]). Takes the input arguments of
/// [AppTextField] (see there) plus the field arguments of [AppField].
///
/// The counter is shown when [maxLength] is set (set [counterFrom] to count
/// something else, e.g. phone digits). Pass [valid] for the "ok" check.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    this.required = false,
    this.info,
    this.infoOpen,
    this.onInfoToggle,
    this.error,
    this.hint,
    this.showCounter = true,
    this.counterFrom,
    this.below,
    this.linkLabel,
    this.onLink,
    this.controller,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.placeholder,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.multiline = false,
    this.rows = 4,
    this.prefix,
    this.suffix,
    this.password = false,
    this.valid = false,
    this.focusNode,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.labelTrailing,
    this.warning,
    this.onWarningTap,
    this.sentenceCase = false,
  });

  final String label;

  /// Shows the label as written (sentence case) instead of Title Case.
  final bool sentenceCase;
  final bool required;

  /// At the right end of the label row (the Private / Public pill).
  final Widget? labelTrailing;

  /// A soft amber note (not an error) shown in the helper line when there is
  /// no error, e.g. "Make sure your email domain is correct."
  final String? warning;

  /// Makes the [error] tappable (e.g. "Did you mean name@gmail.com?").
  final VoidCallback? onWarningTap;
  final String? info;
  final bool? infoOpen;
  final VoidCallback? onInfoToggle;
  final String? error;

  /// Grey helper text shown when there is no error.
  final String? hint;
  final bool showCounter;

  /// Computes the counted length from the text (default: its length).
  final int Function(String text)? counterFrom;
  final Widget? below;
  final String? linkLabel;
  final VoidCallback? onLink;

  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? placeholder;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool multiline;
  final int rows;
  final String? prefix;
  final String? suffix;
  final bool password;
  final bool valid;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _OverflowFlag(builder: _buildField);
  }

  Widget _buildField(BuildContext context, bool over, ValueChanged<bool> set) {
    // Going past the character limit (a long paste) is an error too.
    final shownError = (error != null && error!.isNotEmpty)
        ? error
        : (over && maxLength != null
              ? 'Maximum $maxLength characters allowed.'
              : null);
    Widget inner(String text) => AppField(
      label: label,
      required: required,
      info: info,
      infoOpen: infoOpen,
      onInfoToggle: onInfoToggle,
      error: shownError,
      hint: hint,
      warning: warning,
      onErrorTap: onWarningTap,
      labelTrailing: labelTrailing,
      sentenceCase: sentenceCase,
      below: below,
      linkLabel: linkLabel,
      onLink: onLink,
      child: AppTextField(
        controller: controller,
        value: value,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        hint: placeholder,
        semanticLabel: label,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        multiline: multiline,
        rows: rows,
        prefix: prefix,
        suffix: suffix,
        password: password,
        valid: valid,
        hasError: shownError != null && shownError.isNotEmpty,
        onOverflow: set,
        counterOf: counterFrom,
        showCounter: showCounter,
        focusNode: focusNode,
        autofillHints: autofillHints,
        textCapitalization: textCapitalization,
        enabled: enabled,
      ),
    );

    if (controller != null) {
      return ListenableBuilder(
        listenable: controller!,
        builder: (context, _) => inner(controller!.text),
      );
    }
    return inner(value ?? '');
  }
}
