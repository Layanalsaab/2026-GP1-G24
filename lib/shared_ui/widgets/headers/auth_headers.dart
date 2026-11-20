import 'package:flutter/material.dart';

import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'arch_background.dart';
import 'header_buttons.dart';

class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.total,
    required this.current,
  });

  final int total;

  /// How many segments are filled gold (the current step number).
  final int current;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: Motion.dur(
                  context,
                  const Duration(milliseconds: 300),
                ),
                curve: Motion.easeOut,
                height: 4,
                decoration: BoxDecoration(
                  color: i < current
                      ? AppColors.gold
                      : AppColors.stepSegmentOff,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HeaderTopRow extends StatelessWidget {
  const HeaderTopRow({
    super.key,
    this.onBack,
    this.trailing,
    this.backLabel = 'Back',
    this.close = false,
  });

  final VoidCallback? onBack;

  /// Replaces the logo (e.g.
  final Widget? trailing;
  final String backLabel;
  final bool close;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onBack != null)
            HeaderBackButton(
              onTap: onBack,
              semanticLabel: backLabel,
              close: close,
            )
          else
            const SizedBox(width: 44, height: 44),
          trailing ?? const HeaderLogo(),
        ],
      ),
    );
  }
}

/// Header title that rises in (420 ms): white Inter 700 on a green header.
class HeaderTitle extends StatelessWidget {
  const HeaderTitle(this.text, {super.key, required this.style, this.margin});

  final String text;
  final TextStyle style;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Rise(
        duration: const Duration(milliseconds: 420),
        child: Semantics(header: true, child: Text(text, style: style)),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
    this.subtitle,
    this.overlap = 44,
  });

  final String title;
  final VoidCallback? onBack;

  /// Right side of the top row; null = the logo.
  final Widget? trailing;

  /// Small line under the title (My Startups count).
  final String? subtitle;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    return ArchHeaderShell(
      overlap: overlap,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderTopRow(onBack: onBack, trailing: trailing),
          HeaderTitle(
            title,
            style: AppText.authTitle,
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Text(subtitle!, style: AppText.onGreenMeta),
            ),
        ],
      ),
    );
  }
}

class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    this.onBack,
    this.edit = false,
    this.label,
    this.overlap = 44,
    this.showProgress = true,
  });

  /// False hides the progress bar (editing one section).
  final bool showProgress;

  /// Current step, 1-based (also the number of gold segments).
  final int step;

  /// Total steps (segments).
  final int total;
  final String title;

  /// Null shows an empty spacer instead of the back button.
  final VoidCallback? onBack;

  /// "EDIT STARTUP · STEP N OF M".
  final bool edit;

  /// Overrides the generated label.
  final String? label;
  final double overlap;

  /// The generated label, e.g.
  static String labelFor(int step, int total, {bool edit = false}) =>
      '${edit ? 'EDIT STARTUP · ' : ''}STEP $step OF $total';

  @override
  Widget build(BuildContext context) {
    final text = (label ?? labelFor(step, total, edit: edit)).toUpperCase();
    return ArchHeaderShell(
      overlap: overlap,
      padding: EdgeInsets.fromLTRB(8, 6, 8, showProgress ? 64 : 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderTopRow(onBack: onBack),
          if (showProgress)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: StepProgressBar(total: total, current: step),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              text,
              style: AppText.stepLabel.copyWith(height: 14 / 11),
            ),
          ),
          HeaderTitle(
            title,
            style: AppText.stepTitle,
            margin: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          ),
        ],
      ),
    );
  }
}

class RoleHeader extends StatelessWidget {
  const RoleHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.overlap = 48,
  });

  final String title;
  final VoidCallback? onBack;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    return ArchHeaderShell(
      overlap: overlap,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderTopRow(onBack: onBack),
          HeaderTitle(
            title,
            style: AppText.roleTitle,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          ),
        ],
      ),
    );
  }
}
