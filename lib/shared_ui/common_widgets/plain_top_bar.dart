import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'svg_asset.dart';

/// Light page header used by the startup management screens (Figma
/// "V2 · 44 / 44b / 44c / 45"): cream background, an optional centred bold
/// title, and icon buttons at both ends. It extends under the status bar.
class PlainTopBar extends StatelessWidget {
  const PlainTopBar({
    super.key,
    this.title,
    this.leading,
    this.trailing = const [],
    this.showDivider = false,
    this.safeTop = true,
    this.color = AppColors.cream,
  });

  final String? title;
  final Widget? leading;
  final List<Widget> trailing;

  /// Thin line under the bar (Figma: only on the empty My Startups page).
  final bool showDivider;

  /// Leaves room for the status bar. False when something above already
  /// does (the preview banner).
  final bool safeTop;

  /// Background of the bar (the startup profile pages use moss-100).
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: EdgeInsets.only(
        top: safeTop ? MediaQuery.paddingOf(context).top : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: AppSizes.topBarHeight - 1,
            child: Stack(
              children: [
                if (title != null)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 72),
                      child: Center(
                        child: Text(
                          title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppText.sans(
                            size: 18,
                            color: AppColors.ink,
                            weight: FontWeight.w700,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [?leading, const Spacer(), ...trailing],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: showDivider ? AppColors.border : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

/// A 40 px round touch target around one Figma line icon.
class PlainTopBarIcon extends StatelessWidget {
  const PlainTopBarIcon({
    super.key,
    required this.asset,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 24,
  });

  final String asset;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;

  /// The back arrow, popping the current route.
  factory PlainTopBarIcon.back(BuildContext context, {double iconSize = 24}) =>
      PlainTopBarIcon(
        asset: 'st_back.svg',
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        iconSize: iconSize,
        onPressed: () => Navigator.of(context).maybePop(),
      );

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: svgIcon(asset, size: iconSize)),
        ),
      ),
    );
  }
}
