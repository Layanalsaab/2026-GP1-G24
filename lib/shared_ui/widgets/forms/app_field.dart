import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// Inline round "i" button after a field label (28 x 28, moss600 icon 18,
/// press 0.92). [InfoButton.light] is the 24 px light variant used on the
/// green calculator result card.
class InfoButton extends StatelessWidget {
  const InfoButton({
    super.key,
    required this.onTap,
    this.open = false,
    this.semanticLabel = 'Show examples',
  }) : light = false;

  const InfoButton.light({
    super.key,
    required this.onTap,
    this.open = false,
    this.semanticLabel = 'More info',
  }) : light = true;

  final VoidCallback? onTap;

  /// Reports expanded state to screen readers.
  final bool open;
  final String semanticLabel;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final box = light ? 24.0 : 28.0;
    return Semantics(
      button: true,
      expanded: open,
      label: semanticLabel,
      excludeSemantics: true,
      child: Pressable(
        scale: PressScale.icon,
        // Pointer hover: moss50 (white 10 % on the green card), 160 ms.
        hoverColor: light ? const Color(0x1AFFFFFF) : AppColors.moss50,
        hoverDuration: AppDur.fast,
        borderRadius: BorderRadius.circular(box / 2),
        onTap: onTap,
        child: SizedBox(
          width: box,
          height: box,
          child: Center(
            child: AppIcon.filled(
              AppIcons.info,
              size: 18,
              color: light ? AppColors.onGreenMuted : AppColors.moss600,
            ),
          ),
        ),
      ),
    );
  }
}

/// The tip box that opens under a label (moss50 fill, moss100 border, radius
/// 12, padding 10 12, 13/19 green). Enters with opacity 0 -> 1, translateY
/// -4 -> 0 and scale .98 -> 1 from the top-left over 180 ms; leaves instantly
/// (just remove it from the tree). Bottom margin 8 is included.
class InfoTip extends StatelessWidget {
  const InfoTip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduced
          ? Motion.reducedFade
          : const Duration(milliseconds: 180),
      curve: reduced ? Curves.linear : Motion.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: reduced
            ? child
            : Transform.translate(
                offset: Offset(0, -4 * (1 - t)),
                child: Transform.scale(
                  scale: 0.98 + 0.02 * t,
                  alignment: Alignment.topLeft,
                  child: child,
                ),
              ),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.moss50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.moss100),
        ),
        child: Semantics(
          container: true,
          child: Text(
            text,
            style: AppText.sans(size: 13, color: AppColors.green, height: 19),
          ),
        ),
      ),
    );
  }
}

/// Field label (14/20/500 ink). A required field gets a red `*` (and a
/// screen-reader "(required)"); the whole label turns red when [hasError].
/// An inline [InfoButton] is added when [onInfoTap] is set.
class FieldLabel extends StatelessWidget {
  /// Words kept lower-case inside a title (unless they come first).
  static const _small = {
    'a', 'an', 'the', 'and', 'or', 'but', 'nor', 'of', 'in', 'on', 'at', //
    'to', 'for', 'by', 'with', 'as', 'per', 'vs',
  };

  /// "Which city are you in?" -> "Which City Are You in?". Every field name
  /// is shown in title case: each word starts with a capital, except small
  /// joining words; words that already have inner capitals or digits
  /// (LinkedIn, TAM, Year 1) are left alone.
  static String titleCase(String text) {
    String cap(String w) {
      final i = w.indexOf(RegExp(r'[A-Za-zÀ-ɏ]'));
      if (i < 0) return w;
      final rest = w.substring(i + 1);
      if (rest.contains(RegExp(r'[A-Z0-9]'))) return w; // LinkedIn, TAM
      return w.substring(0, i) + w[i].toUpperCase() + rest;
    }

    final words = text.split(' ');
    for (var n = 0; n < words.length; n++) {
      final bare = words[n].replaceAll(RegExp(r'[^A-Za-z]'), '').toLowerCase();
      if (n > 0 && _small.contains(bare)) continue;
      words[n] = words[n].split('-').map(cap).join('-');
    }
    return words.join(' ');
  }

  const FieldLabel(
    this.label, {
    super.key,
    this.required = false,
    this.hasError = false,
    this.onInfoTap,
    this.infoOpen = false,
  });

  final String label;
  final bool required;
  final bool hasError;

  /// Shows the inline "i" button when non-null.
  final VoidCallback? onInfoTap;
  final bool infoOpen;

  @override
  Widget build(BuildContext context) {
    final color = hasError ? AppColors.error : AppColors.ink;
    final style = AppText.label.copyWith(color: color);
    final text = Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: titleCase(label)),
          if (required) ...[
            const WidgetSpan(child: SizedBox(width: 2)),
            TextSpan(
              text: '*',
              style: style.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Semantics(
            label: required ? '$label (required)' : label,
            excludeSemantics: true,
            child: text,
          ),
        ),
        if (onInfoTap != null)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            // 28 px button in a 20 px row (the prototype's -4 px margins).
            child: SizedBox(
              width: 28,
              height: 20,
              child: OverflowBox(
                maxHeight: 28,
                child: InfoButton(onTap: onInfoTap, open: infoOpen),
              ),
            ),
          ),
      ],
    );
  }
}

/// The helper row under a field. It is ALWAYS reserved: 4 px under the
/// control, min height 18, empty or not, so the distance from one control to
/// the next label is the same on every form (8 + 18 + 2 = 28 px).
///
/// Holds the error on the left (red, 14 px error icon, gap 4) or the hint
/// (grey), and on the right the counter ("12/50") or a field link such as
/// "Forgot password?" ([linkLabel] + [onLink]).
class FieldHelperRow extends StatelessWidget {
  const FieldHelperRow({
    super.key,
    this.error,
    this.hint,
    this.counter,
    this.linkLabel,
    this.onLink,
    this.warning,
    this.onErrorTap,
  });

  /// Soft amber note shown in place of the hint when there is no error.
  final String? warning;

  /// Makes the error text tappable ("Did you mean name@gmail.com?").
  final VoidCallback? onErrorTap;

  /// Height of the helper line (excluding the 4 px above it).
  static const double lineHeight = 18;

  /// Gap between the helper line and the next field's label.
  static const double gapAfter = 2;

  final String? error;
  final String? hint;
  final String? counter;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    final hasHint = hint != null && hint!.isNotEmpty;
    final hasCounter = counter != null && counter!.isNotEmpty;
    final hasLink = linkLabel != null;
    final hasWarning = !hasError && warning != null && warning!.isNotEmpty;
    return Padding(
      // 8 px of air under the control; a line with a link ("Forgot password?")
      // is taller so the 14/20 text is not cut off.
      padding: const EdgeInsets.only(top: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: hasLink ? 28 : lineHeight),
        child: LayoutBuilder(
          builder: (context, box) {
            // An error that would wrap only because of the counter keeps its
            // one line: the counter steps aside while the error is showing.
            var showCounter = hasCounter && !hasLink;
            if (hasError && showCounter) {
              final scaler = MediaQuery.textScalerOf(context);
              double width(String t, TextStyle st) {
                final tp = TextPainter(
                  text: TextSpan(text: t, style: st),
                  textDirection: TextDirection.ltr,
                  textScaler: scaler,
                )..layout();
                return tp.width;
              }

              final errorW = 18 + width(error!, AppText.error);
              final counterW = 8 + width(counter!, AppText.helper);
              final fitsAlone = errorW <= box.maxWidth;
              if (fitsAlone && errorW + counterW > box.maxWidth) {
                showCounter = false;
              }
            }
            return _row(hasError, hasHint, showCounter, hasLink, hasWarning);
          },
        ),
      ),
    );
  }

  Widget _row(
    bool hasError,
    bool hasHint,
    bool hasCounter,
    bool hasLink,
    bool hasWarning,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: hasError
              ? Semantics(
                  liveRegion: true,
                  button: onErrorTap != null,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onErrorTap,
                    child: Row(
                      children: [
                        AppIcon.filled(
                          AppIcons.error,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            error!,
                            style: onErrorTap == null
                                ? AppText.error
                                : AppText.error.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.error,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : hasWarning
              ? Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      AppIcon.filled(
                        AppIcons.warn,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          warning!,
                          style: AppText.helper.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : hasHint
              ? Text(hint!, style: AppText.helper)
              : const SizedBox.shrink(),
        ),
        if (hasLink) ...[
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: linkLabel,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onLink,
              // The 14/20 link, centered in its 28 px line (also a bigger tap area).
              child: SizedBox(
                height: 28,
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 1,
                  child: Text(linkLabel!, style: AppText.link),
                ),
              ),
            ),
          ),
        ] else if (hasCounter) ...[
          const SizedBox(width: 8),
          Text(counter!, style: AppText.helper),
        ],
      ],
    );
  }
}

/// A form field wrapper: [label] (red `*` when [required]; red text when
/// [error] is set), optional inline info "i" + [info] tip, optional
/// [subLabel] ("Select all that apply · 3 selected"), the [child] control, an
/// optional [below] block (password rules), the helper row ([error] / [hint]
/// left, [counter] right) and an optional right-aligned link
/// ("Forgot password?" via [linkLabel] + [onLink]).
///
/// Stack fields with [FormFieldColumn] (6 px gap after the always-reserved
/// helper line = 28 px from one control to the next label). The info tip is
/// controlled with [infoOpen] + [onInfoToggle] (so a screen can keep only one
/// open); leave [infoOpen] null to let the field manage it itself.
class AppField extends StatefulWidget {
  const AppField({
    super.key,
    required this.child,
    this.label,
    this.required = false,
    this.info,
    this.infoOpen,
    this.onInfoToggle,
    this.subLabel,
    this.error,
    this.hint,
    this.counter,
    this.below,
    this.linkLabel,
    this.onLink,
    this.labelTrailing,
    this.warning,
    this.onErrorTap,
  });

  /// Soft amber note (not an error), shown when there is no [error].
  final String? warning;

  /// Makes the [error] line tappable.
  final VoidCallback? onErrorTap;

  final Widget child;
  final String? label;

  /// Shown at the right end of the label row (e.g. the Private / Public
  /// pill). It may be taller than the label: the row stays 20 px high.
  final Widget? labelTrailing;
  final bool required;

  /// Tip text; presence adds the "i" button.
  final String? info;
  final bool? infoOpen;
  final VoidCallback? onInfoToggle;
  final String? subLabel;

  /// Error copy; non-null puts the label and helper in the error style.
  final String? error;
  final String? hint;

  /// e.g. "4/50".
  final String? counter;
  final Widget? below;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  /// The self-managed field whose tip is open: only one tip is open at a
  /// time, opening another closes this one.
  static _AppFieldState? _current;

  bool _localOpen = false;

  bool get _open => widget.infoOpen ?? _localOpen;

  void _toggle() {
    if (widget.onInfoToggle != null) widget.onInfoToggle!();
    if (widget.infoOpen == null) {
      final opening = !_localOpen;
      if (opening) {
        final prev = _current;
        if (prev != null && prev != this && prev.mounted) {
          prev.setState(() => prev._localOpen = false);
        }
        _current = this;
      } else if (_current == this) {
        _current = null;
      }
      setState(() => _localOpen = opening);
    }
  }

  @override
  void dispose() {
    if (_current == this) _current = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasInfo = widget.info != null;
    final tipOpen = hasInfo && _open;
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) ...[
          if (widget.labelTrailing == null)
            Align(
              alignment: Alignment.centerLeft,
              child: FieldLabel(
                widget.label!,
                required: widget.required,
                hasError: hasError,
                onInfoTap: hasInfo ? _toggle : null,
                infoOpen: tipOpen,
              ),
            )
          else
            // The trailing widget (the Private / Public pill) is taller than
            // the 20 px label line, so it hangs over it: the row stays 20 px
            // high and the spacing between fields never changes.
            SizedBox(
              height: 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FieldLabel(
                      widget.label!,
                      required: widget.required,
                      hasError: hasError,
                      onInfoTap: hasInfo ? _toggle : null,
                      infoOpen: tipOpen,
                    ),
                  ),
                  Positioned(right: 0, top: -3, child: widget.labelTrailing!),
                ],
              ),
            ),
          // Label -> control is always 8 px (the sub-text, when present,
          // sits between them).
          SizedBox(height: widget.subLabel != null && !tipOpen ? 2 : 8),
        ],
        if (tipOpen) InfoTip(widget.info!),
        if (widget.subLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.subLabel!, style: AppText.helper),
          ),
        widget.child,
        ?widget.below,
        FieldHelperRow(
          error: widget.error,
          hint: widget.hint,
          counter: widget.counter,
          linkLabel: widget.linkLabel,
          onLink: widget.onLink,
          warning: widget.warning,
          onErrorTap: widget.onErrorTap,
        ),
      ],
    );
  }
}

/// A column of fields: the form card padding `28 16 16` and a 6 px gap (the
/// helper line of every [AppField] is always reserved, so control -> next
/// label is always 28 px). Never add ad-hoc spacing between fields.
class FormFieldColumn extends StatelessWidget {
  const FormFieldColumn({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 28, 16, 16),
    this.gap = FieldHelperRow.gapAfter,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}
