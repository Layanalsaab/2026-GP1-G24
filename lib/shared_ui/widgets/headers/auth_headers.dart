import 'package:flutter/material.dart';

import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'arch_background.dart';
import 'header_buttons.dart';

/// Segmented progress bar of the step header: one segment per step, equal
/// width, gap 6, 4 high, radius 2. The first [current] segments are gold
/// (done + current), the rest white 20 %; colors animate 300 ms.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.total,
    required this.current,
  });

  /// Number of segments (6 founder sign-up, 4 investor sign-up / add startup).
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

/// The top row of the arch headers: back button (or an empty 44 px spacer when
/// [onBack] is null, so the logo stays on the right) on the left, [trailing] (default the
/// 42 px logo with a 6 px right margin) on the right. Height 44.
class HeaderTopRow extends StatelessWidget {
  const HeaderTopRow({
    super.key,
    this.onBack,
    this.trailing,
    this.backLabel = 'Back',
    this.close = false,
  });

  final VoidCallback? onBack;

  /// Replaces the logo (e.g. the My Startups "Add" pill, glass buttons).
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

/// Auth header (log in, forgot password, My Startups, valuation calculator):
/// green, padding 6 8 72, bottom radius 28, both arch paths at 22 %. Top row:
/// back button + logo (or [trailing]); title 32/38 (rise 420 ms); optional
/// [subtitle] (13 `#CFE0D3`, "2 startups").
///
/// [overlap] is how far the white card below climbs into the header: 44 for
/// an [AuthCard] (default), 48 for an [OverlapList]
/// (`overlap: OverlapList.overlap`).
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

/// Step header (sign-up steps, add / edit startup steps): like [AuthHeader]
/// with padding-bottom 64, a [StepProgressBar], the "STEP N OF M" label and a
/// 28/34 title. Without [onBack] a 44 px spacer keeps the logo on the right.
///
/// Edit startup passes `edit: true` for "EDIT STARTUP · STEP N OF 4", or pass
/// a custom [label].
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
  });

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

  /// The generated label, e.g. `STEP 3 OF 6`.
  static String labelFor(int step, int total, {bool edit = false}) =>
      '${edit ? 'EDIT STARTUP · ' : ''}STEP $step OF $total';

  @override
  Widget build(BuildContext context) {
    final text = (label ?? labelFor(step, total, edit: edit)).toUpperCase();
    return ArchHeaderShell(
      overlap: overlap,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderTopRow(onBack: onBack),
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

/// Roomy header (choose role): padding-bottom 110, 34/40 title with a 44 px
/// top margin; the role cards overlap it by 48 ([overlap]).
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
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderTopRow(onBack: onBack),
          HeaderTitle(
            title,
            style: AppText.roleTitle,
            margin: const EdgeInsets.fromLTRB(16, 44, 16, 0),
          ),
        ],
      ),
    );
  }
}
