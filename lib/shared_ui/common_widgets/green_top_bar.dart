import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Flat deep moss header (Figma "V2 · 24 / 25 / 35" top bars). It extends under the
/// status bar, has an optional leading button, a serif title and actions,
/// and can carry extra content below (e.g. a subtitle).
class GreenTopBar extends StatelessWidget {
  const GreenTopBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.below,
    this.color = AppColors.green,
    this.titleStyle,
  });

  final String title;

  /// Overrides the default title style (the Explore and Hub bars use a larger
  /// serif title than the other pages).
  final TextStyle? titleStyle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? below;

  /// Transparent when the bar sits on top of another green header.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top,
        bottom: below == null ? 0 : AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: AppSizes.topBarHeight,
            child: Row(
              children: [
                SizedBox(
                  width: leading == null ? AppSpacing.page : AppSpacing.xs,
                ),
                ?leading,
                if (leading != null) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: titleStyle ?? AppText.topBarTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...actions,
                const SizedBox(width: AppSpacing.xs),
              ],
            ),
          ),
          if (below != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: below,
            ),
        ],
      ),
    );
  }
}

/// A round, white line icon button for [GreenTopBar].
class TopBarIconButton extends StatelessWidget {
  const TopBarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: AppSizes.icon),
      color: AppColors.onDark,
      disabledColor: AppColors.onDarkMuted,
      constraints: const BoxConstraints.tightFor(
        width: AppSizes.touchTarget,
        height: AppSizes.touchTarget,
      ),
    );
  }
}

/// Back arrow for [GreenTopBar]. Uses maybePop, so PopScope guards apply.
class TopBarBackButton extends StatelessWidget {
  const TopBarBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TopBarIconButton(
    icon: Icons.arrow_back_rounded,
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
  );
}
