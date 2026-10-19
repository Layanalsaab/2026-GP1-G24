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
        scale: 0.92,
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
          TextSpan(text: label),
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

/// The helper row under a field (12/16): the error on the left (red, 14 px
/// error icon, gap 4) or the hint (grey), and the counter ("12/50") on the
/// right. Renders nothing when all three are empty.
class FieldHelperRow extends StatelessWidget {
  const FieldHelperRow({super.key, this.error, this.hint, this.counter});

  final String? error;
  final String? hint;
  final String? counter;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    final hasHint = hint != null && hint!.isNotEmpty;
    final hasCounter = counter != null && counter!.isNotEmpty;
    if (!hasError && !hasHint && !hasCounter) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: LayoutBuilder(
        builder: (context, box) {
          // An error that would wrap only because of the counter keeps its one
          // line: the counter steps aside while the error is showing.
          var showCounter = hasCounter;
          if (hasError && hasCounter) {
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
          return _row(hasError, hasHint, showCounter);
        },
      ),
    );
  }

  Widget _row(bool hasError, bool hasHint, bool hasCounter) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: hasError
                ? Semantics(
                    liveRegion: true,
                    child: Row(
                      children: [
                        AppIcon.filled(
                          AppIcons.error,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Flexible(child: Text(error!, style: AppText.error)),
                      ],
                    ),
                  )
                : hasHint
                ? Text(hint!, style: AppText.helper)
                : const SizedBox.shrink(),
          ),
          if (hasCounter) ...[
            const SizedBox(width: 8),
            Text(counter!, style: AppText.helper),
          ],
        ],
      ),
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
/// Stack fields with a 20 px gap (`FormFieldColumn`). The info tip is
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
  });

  final Widget child;
  final String? label;
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
  bool _localOpen = false;

  bool get _open => widget.infoOpen ?? _localOpen;

  void _toggle() {
    if (widget.onInfoToggle != null) widget.onInfoToggle!();
    if (widget.infoOpen == null) setState(() => _localOpen = !_localOpen);
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
          // The sub-text has a -2 top margin in the prototype.
          SizedBox(height: widget.subLabel != null && !tipOpen ? 4 : 6),
        ],
        if (tipOpen) InfoTip(widget.info!),
        if (widget.subLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(widget.subLabel!, style: AppText.helper),
          ),
        widget.child,
        ?widget.below,
        FieldHelperRow(
          error: widget.error,
          hint: widget.hint,
          counter: widget.counter,
        ),
        if (widget.linkLabel != null)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Semantics(
                button: true,
                label: widget.linkLabel,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onLink,
                  child: Text(widget.linkLabel!, style: AppText.link),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A column of fields with the documented 20 px gap and the form block
/// padding `20 16 24` (override [padding] when needed).
class FormFieldColumn extends StatelessWidget {
  const FormFieldColumn({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 24),
    this.gap = 20,
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
