import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_constants/app_strings.dart';
import '../../helpers/validators.dart';
import '../theme/app_theme.dart';
import 'form_message.dart';

/// Figma "Text field": label above, 48px field with a strong border.
///
/// Live feedback while the user types:
/// * [rules] shows a checklist under the field. Every rule is red with a cross
///   until it is met, then turns green with a check, one by one.
/// * A green check appears inside the field once every rule is met.
/// * The border and label turn red when a rule is still unmet after the user
///   leaves the field (or after a submit attempt, see [showRules]).
/// * [errorText] (a server or submit error) shows as a message with an icon.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.rules,
    this.showRules = false,
    this.optional = false,
    this.prefix,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  /// Shows a value that can't be edited (e.g. the login email) in a grey,
  /// muted field. Different from [enabled]: false, which is used while loading.
  final bool readOnly;

  /// More than 1 makes a multi-line field (e.g. a bio).
  final int maxLines;

  /// When set, limits the length and shows a "0/150" counter under the field.
  final int? maxLength;

  /// The live checklist for this field. The screen recomputes it from the
  /// controller's text (see the `Validators.*Rules` methods).
  final List<FieldRule>? rules;

  /// Show the checklist as failed even before the user touched the field.
  /// Screens set this after a submit attempt.
  final bool showRules;

  /// Adds a muted "(optional)" after the label.
  final bool optional;

  /// Something before the text, e.g. the "+966" country code.
  final Widget? prefix;

  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focus = FocusNode();
  TextEditingController? _ownController;
  bool _touched = false;
  late bool _obscured = widget.obscureText;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus) _touched = true;
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _focus]),
      builder: (context, _) => _buildField(),
    );
  }

  Widget _buildField() {
    final text = _controller.text;
    final rules = widget.rules;
    final focused = _focus.hasFocus;
    final unmet = rules?.where((r) => !r.met).length ?? 0;

    final rulesVisible = rules != null && (_touched || widget.showRules);
    final rulesFailed = rulesVisible &&
        unmet > 0 &&
        !focused &&
        (text.isNotEmpty || widget.showRules);
    final hasError = widget.errorText != null || rulesFailed;
    final isValid = rules != null && unmet == 0 && text.isNotEmpty && !hasError;

    final borderColor = hasError
        ? AppColors.error
        : focused
            ? AppColors.moss600
            : isValid
                ? AppColors.moss600
                : widget.readOnly
                    ? AppColors.border
                    : AppColors.borderStrong;
    final borderWidth = (hasError || focused) && !widget.readOnly ? 2.0 : 1.0;
    final labelColor = hasError
        ? AppColors.error
        : focused
            ? AppColors.moss600
            : AppColors.ink;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: color, width: width),
        );

    Widget? suffix;
    if (widget.obscureText) {
      suffix = IconButton(
        tooltip: _obscured ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscured = !_obscured),
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: AppColors.grey,
        ),
      );
    } else if (isValid) {
      suffix = const Padding(
        padding: EdgeInsets.only(right: 14),
        child: Icon(Icons.check, size: 20, color: AppColors.moss600),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: widget.label,
            style: AppText.sans(
              size: 14,
              color: labelColor,
              weight: FontWeight.w500,
              height: 20,
            ),
            children: [
              if (widget.optional)
                TextSpan(
                  text: ' ${AppStrings.optionalSuffix}',
                  style: AppText.sans(
                    size: 13,
                    color: AppColors.grey,
                    height: 20,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          focusNode: _focus,
          obscureText: _obscured,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          inputFormatters: widget.inputFormatters,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          cursorColor: AppColors.moss600,
          autocorrect: false,
          enableSuggestions: !widget.obscureText,
          style: AppText.sans(
            size: 16,
            color: widget.readOnly ? AppColors.grey : AppColors.ink,
            height: 24,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: widget.readOnly ? AppColors.mutedFill : AppColors.surface,
            hintText: widget.hint,
            hintStyle: AppText.sans(size: 16, color: AppColors.grey, height: 24),
            // The counter is drawn below, next to the checklist.
            counterText: '',
            contentPadding: EdgeInsets.fromLTRB(
              widget.prefix == null ? 14 : 10,
              11,
              14,
              11,
            ),
            prefixIcon: widget.prefix,
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            border: border(borderColor, borderWidth),
            enabledBorder: border(borderColor, borderWidth),
            focusedBorder: widget.readOnly
                ? border(AppColors.border, 1)
                : border(hasError ? AppColors.error : AppColors.moss600, 2),
            disabledBorder: border(AppColors.border, 1),
          ),
        ),
        if (rulesVisible) ...[
          const SizedBox(height: 8),
          for (final rule in rules) _RuleRow(rule: rule),
        ],
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          FormMessage.error(widget.errorText!),
        ],
        if (widget.maxLength != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${text.length}/${widget.maxLength}',
              style: AppText.sans(size: 12, color: AppColors.grey, height: 16),
            ),
          ),
        ],
      ],
    );
  }
}

/// One checklist line: red cross while unmet, green check once met. The state
/// is never shown by color alone (the icon differs) and is read out loud.
class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule});

  final FieldRule rule;

  @override
  Widget build(BuildContext context) {
    final color = rule.met ? AppColors.moss600 : AppColors.error;
    return Semantics(
      label: '${rule.label}, ${rule.met ? 'done' : 'not done yet'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(rule.met ? Icons.check : Icons.close, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                rule.label,
                style: AppText.sans(size: 12, color: color, height: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
