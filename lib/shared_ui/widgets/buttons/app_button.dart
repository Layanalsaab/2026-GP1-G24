import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';

/// Button looks (docs/02_design_system.md §8.1).
enum AppButtonVariant {
  /// Moss fill, white text, primary shadow.
  primary,

  /// Green fill, white text (Intro 3 "Get started").
  dark,

  /// White fill, moss text, 1.5 moss border.
  outline,

  /// Red fill, white text.
  danger,

  /// Transparent, moss text, 40 high.
  ghost,

  /// After an action: moss100 fill, green text, moss border, check icon.
  done,

  /// Form not complete: grey fill and text. Still tappable (tapping shows
  /// the errors), so [AppButton.onPressed] is still required for it.
  off,
}

enum AppButtonSize {
  /// 48 high, radius 14, 16/600.
  regular,

  /// 40 high, radius 12, 14/600.
  small,

  /// 52 high (pinned profile CTA bar).
  cta,
}

/// The one button of the app. Press scales to 0.97 (140 ms).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.loading = false,
    this.expanded = true,
  });

  final String label;

  /// Null disables the button (no press, no scale). The `off` variant is not
  /// "disabled": pass a handler that shows the form errors.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Optional filled icon path from [AppIcons] shown before the label
  /// (the `done` variant adds a check automatically when this is null).
  final String? icon;

  /// Shows a spinner and ignores taps, so a request can't be sent twice.
  final bool loading;

  /// Full width (default) or hugging its content.
  final bool expanded;

  bool get _small => size == AppButtonSize.small;

  double get _height {
    if (variant == AppButtonVariant.ghost) return AppSize.buttonSmallHeight;
    return switch (size) {
      AppButtonSize.regular => AppSize.buttonHeight,
      AppButtonSize.small => AppSize.buttonSmallHeight,
      AppButtonSize.cta => AppSize.ctaButtonHeight,
    };
  }

  Color get _fill => switch (variant) {
    AppButtonVariant.primary => AppColors.moss600,
    AppButtonVariant.dark => AppColors.green,
    AppButtonVariant.outline => AppColors.surface,
    AppButtonVariant.danger => AppColors.error,
    AppButtonVariant.ghost => Colors.transparent,
    AppButtonVariant.done => AppColors.moss100,
    AppButtonVariant.off => AppColors.offFill,
  };

  Color get _foreground => switch (variant) {
    AppButtonVariant.primary ||
    AppButtonVariant.dark ||
    AppButtonVariant.danger => AppColors.onDark,
    AppButtonVariant.outline || AppButtonVariant.ghost => AppColors.moss600,
    AppButtonVariant.done => AppColors.green,
    AppButtonVariant.off => AppColors.offText,
  };

  List<BoxShadow>? get _shadow => switch (variant) {
    AppButtonVariant.primary ||
    AppButtonVariant.dark => AppShadow.primaryButton,
    AppButtonVariant.danger => AppShadow.dangerButton,
    _ => null,
  };

  BoxBorder? get _border => switch (variant) {
    AppButtonVariant.outline ||
    AppButtonVariant.done => Border.all(color: AppColors.moss600, width: 1.5),
    _ => null,
  };

  /// The look while a mouse pointer is over the button.
  Color _hoverFill() => switch (variant) {
    AppButtonVariant.primary || AppButtonVariant.dark => _brighter(_fill, 1.06),
    AppButtonVariant.outline => AppColors.moss50,
    _ => _fill,
  };

  List<BoxShadow>? _hoverShadow() => switch (variant) {
    AppButtonVariant.primary || AppButtonVariant.dark => const [
      BoxShadow(
        color: Color(0xA61F3F27),
        offset: Offset(0, 10),
        blurRadius: 20,
        spreadRadius: -8,
      ),
    ],
    _ => _shadow,
  };

  static Color _brighter(Color c, double factor) => Color.from(
    alpha: c.a,
    red: (c.r * factor).clamp(0.0, 1.0),
    green: (c.g * factor).clamp(0.0, 1.0),
    blue: (c.b * factor).clamp(0.0, 1.0),
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      _small ? AppRadius.buttonSmall : AppRadius.button,
    );
    final style =
        (_small || variant == AppButtonVariant.ghost
                ? AppText.buttonSmall
                : AppText.button)
            .copyWith(
              color: _foreground,
              fontSize: variant == AppButtonVariant.ghost && !_small
                  ? 15
                  : null,
            );
    final iconPath =
        icon ?? (variant == AppButtonVariant.done ? AppIcons.check : null);
    final showShine =
        variant == AppButtonVariant.primary || variant == AppButtonVariant.dark;

    final content = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _foreground,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconPath != null) ...[
                AppIcon.filled(
                  iconPath,
                  size: _small ? 18 : 20,
                  color: _foreground,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final interactive = onPressed != null && !loading;
    Widget bodyFor(bool hover) => AnimatedContainer(
      // Fill, border and shadow change over 200 ms (hover, off <-> enabled).
      duration: Motion.dur(context, AppDur.base),
      curve: AppCurves.ease,
      height: _height,
      width: expanded ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hover ? _hoverFill() : _fill,
        borderRadius: radius,
        border: _border,
        boxShadow: hover ? _hoverShadow() : _shadow,
      ),
      child: content,
    );

    // The `inset 0 1px 0 #ffffff26` top highlight of primary/dark buttons.
    Widget shined(bool hover) => showShine
        ? Stack(
            children: [
              bodyFor(hover),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(radius.topLeft.x),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : bodyFor(hover);

    return Semantics(
      button: true,
      enabled: interactive,
      label: label,
      excludeSemantics: true,
      child: _HoverBuilder(
        enabled: interactive,
        builder: (hover) => Pressable(
          onTap: interactive ? onPressed : null,
          scale: PressScale.button,
          child: shined(hover),
        ),
      ),
    );
  }
}

/// Reports whether a mouse pointer is over [builder]'s widget (never for
/// touch), so a button can restyle itself on hover.
class _HoverBuilder extends StatefulWidget {
  const _HoverBuilder({required this.enabled, required this.builder});

  final bool enabled;
  final Widget Function(bool hover) builder;

  @override
  State<_HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<_HoverBuilder> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: widget.builder(widget.enabled && _hover),
  );
}
