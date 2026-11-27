import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import '../cards/avatars.dart';

/// Where an AppDropdown menu hangs and grows from.
enum AppDropdownOrigin {
  /// Right edges aligned, grows from the top-right (Latest range).
  topRight,

  /// Same width as the anchor, grows from the top-center (Matches for).
  topCenter,
}

/// Anchored popover menu (prototype .rddm / .mfm).
class AppDropdown extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.anchorBuilder,
    required this.menuBuilder,
    this.origin = AppDropdownOrigin.topRight,
    this.minMenuWidth = 160,
    this.semanticLabel,
  });

  final Widget Function(BuildContext context, bool open) anchorBuilder;
  final Widget Function(BuildContext context, VoidCallback close) menuBuilder;
  final AppDropdownOrigin origin;
  final double minMenuWidth;
  final String? semanticLabel;

  @override
  State<AppDropdown> createState() => _AppDropdownState();
}

class _AppDropdownState extends State<AppDropdown> {
  bool _open = false;

  Future<void> _toggle() async {
    if (_open) return;
    final box = context.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero);
    final anchor = topLeft & box.size;
    setState(() => _open = true);
    await Navigator.of(context, rootNavigator: true).push<void>(
      _DropdownRoute(
        anchor: anchor,
        origin: widget.origin,
        minWidth: widget.minMenuWidth,
        reduced: Motion.reduced(context),
        builder: widget.menuBuilder,
        onClosing: () {
          // The caret turns back as soon as the menu starts to close.
          if (mounted && _open) setState(() => _open = false);
        },
      ),
    );
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: _open,
      label: widget.semanticLabel,
      onTap: _toggle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: widget.anchorBuilder(context, _open),
      ),
    );
  }
}

class _DropdownRoute extends PopupRoute<void> {
  _DropdownRoute({
    required this.anchor,
    required this.origin,
    required this.minWidth,
    required this.reduced,
    required this.builder,
    this.onClosing,
  });

  final VoidCallback? onClosing;
  final Rect anchor;
  final AppDropdownOrigin origin;
  final double minWidth;
  final bool reduced;
  final Widget Function(BuildContext, VoidCallback) builder;

  @override
  bool didPop(void result) {
    onClosing?.call();
    return super.didPop(result);
  }

  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => 'Close menu';
  @override
  Duration get transitionDuration =>
      reduced ? Duration.zero : const Duration(milliseconds: 180);
  @override
  Duration get reverseTransitionDuration =>
      reduced ? Duration.zero : const Duration(milliseconds: 150);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    void close() => Navigator.of(context).maybePop();
    final menu = _MenuCard(child: builder(context, close));
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: CustomSingleChildLayout(
        delegate: _MenuLayout(anchor, origin, minWidth),
        child: _MenuTransition(
          animation: animation,
          origin: origin,
          child: menu,
        ),
      ),
    );
  }
}

class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout(this.anchor, this.origin, this.minWidth);

  final Rect anchor;
  final AppDropdownOrigin origin;
  final double minWidth;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxH = math.max(120.0, constraints.maxHeight - anchor.bottom - 16);
    if (origin == AppDropdownOrigin.topCenter) {
      return BoxConstraints(
        minWidth: anchor.width,
        maxWidth: anchor.width,
        maxHeight: maxH,
      );
    }
    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: constraints.maxWidth - 24,
      maxHeight: maxH,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final dy = anchor.bottom + 6;
    if (origin == AppDropdownOrigin.topCenter) return Offset(anchor.left, dy);
    final dx = (anchor.right - childSize.width)
        .clamp(12.0, math.max(12.0, size.width - childSize.width - 12))
        .toDouble();
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_MenuLayout old) =>
      old.anchor != anchor || old.origin != origin;
}

class _MenuTransition extends StatelessWidget {
  const _MenuTransition({
    required this.animation,
    required this.origin,
    required this.child,
  });

  final Animation<double> animation;
  final AppDropdownOrigin origin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final opacity = animation.drive(
      CurveTween(curve: Interval(0, 150 / 180, curve: Curves.ease)),
    );
    final eased = animation.drive(CurveTween(curve: Motion.easeOut));
    final from = origin == AppDropdownOrigin.topCenter ? 0.97 : 0.96;
    return FadeTransition(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: eased,
        child: child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -4 * (1 - eased.value)),
          child: Transform.scale(
            scale: from + (1 - from) * eased.value,
            alignment: origin == AppDropdownOrigin.topCenter
                ? Alignment.topCenter
                : Alignment.topRight,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadow.dropdown,
        ),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

/// Tracks a mouse pointer over its child (never touch) and rebuilds with the hover flag.
class _Hoverable extends StatefulWidget {
  const _Hoverable({required this.builder});

  final Widget Function(BuildContext context, bool hover) builder;

  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_hover && mounted) setState(() => _hover = true);
      },
      onExit: (_) {
        if (_hover && mounted) setState(() => _hover = false);
      },
      child: widget.builder(context, _hover),
    );
  }
}

/// Row hover fill of the dropdown menus (#F6F4EF).
Color get _rowHover => AppColors.profileBg;

/// The dropdown caret (M7 10l5 5 5-5z, filled) that rotates 180 degrees in 200 ms when open.
class DropdownCaret extends StatelessWidget {
  const DropdownCaret({
    super.key,
    required this.open,
    this.color,
    this.size = 20,
  });

  final bool open;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: open ? 0.5 : 0,
      duration: Motion.dur(context, const Duration(milliseconds: 200)),
      curve: Curves.ease,
      child: AppIcon.filled(
        'M7 10l5 5 5-5z',
        size: size,
        color: color ?? AppColors.ink,
      ),
    );
  }
}

class DropdownOption extends StatelessWidget {
  const DropdownOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: _Hoverable(
        builder: (context, hover) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.dur(context, AppDur.base),
            curve: Curves.ease,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.mossChip
                  : (hover ? _rowHover : Colors.transparent),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              label,
              style: AppText.sans(
                size: 14,
                color: selected ? AppColors.mossText : AppColors.ink,
                weight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RangeDropdown extends StatelessWidget {
  const RangeDropdown({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppDropdown(
      origin: AppDropdownOrigin.topRight,
      semanticLabel: 'Range, ${options[selectedIndex]}',
      anchorBuilder: (context, open) => Container(
        height: 32,
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: BoxDecoration(
          color: AppColors.rangeFill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              options[selectedIndex],
              style: AppText.sans(size: 13, weight: FontWeight.w600),
            ),
            DropdownCaret(open: open),
          ],
        ),
      ),
      menuBuilder: (context, close) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < options.length; i++)
            DropdownOption(
              label: options[i],
              selected: i == selectedIndex,
              onTap: () {
                close();
                if (i != selectedIndex) onSelected(i);
              },
            ),
        ],
      ),
    );
  }
}

/// One row of MatchesForDropdown.
class MatchesForOption {
  const MatchesForOption({required this.name, required this.subtitle});

  /// Startup name.
  final String name;

  /// e.g.
  final String subtitle;
}

class MatchesForDropdown extends StatelessWidget {
  const MatchesForDropdown({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.kicker = 'Matches for',
  });

  final List<MatchesForOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String kicker;

  @override
  Widget build(BuildContext context) {
    final current = options[selectedIndex].name;
    return AppDropdown(
      origin: AppDropdownOrigin.topCenter,
      semanticLabel: '$kicker $current',
      anchorBuilder: (context, open) => _Hoverable(
        builder: (context, hover) => AnimatedContainer(
          duration: Motion.dur(context, const Duration(milliseconds: 150)),
          curve: Curves.ease,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hover ? AppColors.hoverBorderGreen : AppColors.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D1F3F27),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      kicker,
                      style: AppText.sans(
                        size: 11.5,
                        color: AppColors.metaText,
                      ),
                    ),
                    Text(
                      current,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(size: 15, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              DropdownCaret(open: open, color: AppColors.mossText),
            ],
          ),
        ),
      ),
      menuBuilder: (context, close) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < options.length; i++)
            Semantics(
              button: true,
              selected: i == selectedIndex,
              label: '${options[i].name}, ${options[i].subtitle}',
              excludeSemantics: true,
              onTap: () {
                close();
                if (i != selectedIndex) onSelected(i);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  close();
                  if (i != selectedIndex) onSelected(i);
                },
                child: _Hoverable(
                  builder: (context, hover) => AnimatedContainer(
                    duration: Motion.dur(
                      context,
                      const Duration(milliseconds: 150),
                    ),
                    curve: Curves.ease,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: i == selectedIndex
                          ? AppColors.mossChip
                          : (hover ? _rowHover : Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        HueAvatar(
                          name: options[i].name,
                          size: AppSize.avatarDropdown,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                options[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.sans(
                                  size: 14.5,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                options[i].subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.sans(
                                  size: 12,
                                  color: AppColors.metaText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i == selectedIndex)
                          AppIcon.filled(
                            AppIcons.check,
                            size: 18,
                            color: AppColors.mossText,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
