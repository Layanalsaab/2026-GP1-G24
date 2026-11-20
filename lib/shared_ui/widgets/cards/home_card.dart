import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import 'pin_city.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import 'avatars.dart';
import 'pills.dart';

class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.name,
    required this.tag,
    required this.city,
    required this.body,
    this.kind = HueAvatarKind.startup,
    this.onTap,
    this.onShare,
    this.onBookmark,
    this.bookmarked = false,
    this.matchPercent,
    this.matchReason,
    this.highlight,
    this.highlightReason,
    this.index = 0,
    this.animate = true,
    this.bodyMaxLines = 3,
    this.badges = const [],
    this.actionLabel,
    this.imageUrl,
    this.imageData,
  });

  final String name;

  /// Startup sector, investor's first sector, or program type.
  final String tag;
  final String city;

  /// Startup tagline / investor about / program summary.
  final String body;
  final HueAvatarKind kind;
  final VoidCallback? onTap;
  final VoidCallback? onShare;

  /// Null hides the bookmark button.
  final VoidCallback? onBookmark;
  final bool bookmarked;

  /// e.g.
  final int? matchPercent;
  final String? matchReason;

  final String? highlight;
  final String? highlightReason;

  /// Position in the list, for the entrance stagger.
  final int index;

  /// Set false to skip the cardIn entrance.
  final bool animate;

  final int bodyMaxLines;

  /// Optional small capsules next to the name (the role, "Private").
  final List<Widget> badges;

  final String? actionLabel;

  /// The startup's logo or the person's photo (the initials when none).
  final String? imageUrl;

  /// The saved copy of the picture (base64): shown first when there is one.
  final String? imageData;

  @override
  Widget build(BuildContext context) {
    final showActions = onShare != null || onBookmark != null;
    final card = _HoverCard(
      onTap: onTap,
      builder: (context, hover) => Semantics(
        container: true,
        button: true,
        label: '$name, $tag, $city',
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.homeCard),
            boxShadow: AppShadow.homeCard,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HueAvatar(
                          name: name,
                          kind: kind,
                          size: 58,
                          imageUrl: imageUrl,
                          imageData: imageData,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _NameBlock(
                            name: name,
                            tag: tag,
                            city: city,
                            badges: badges,
                          ),
                        ),
                        if (showActions) const SizedBox(width: 63),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Text(
                        body,
                        style: AppText.cardBody,
                        maxLines: bodyMaxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (matchPercent != null || highlight != null) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(right: 22),
                        child: Row(
                          children: [
                            _MatchPill(highlight ?? '$matchPercent% match'),
                            if ((highlight != null
                                    ? highlightReason
                                    : matchReason) !=
                                null) ...[
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  (highlight != null
                                      ? highlightReason
                                      : matchReason)!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.sans(
                                    size: 13,
                                    color: AppColors.metaText,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (actionLabel != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          label: actionLabel,
                          excludeSemantics: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                actionLabel!,
                                style: AppText.sans(
                                  size: 15,
                                  weight: FontWeight.w600,
                                  color: AppColors.mossText,
                                ),
                              ),
                              const SizedBox(width: 2),
                              _CardChevron(hover: hover),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showActions)
                Positioned(
                  top: 15,
                  right: 13,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onShare != null)
                        _CardAction(
                          label: 'Share',
                          onTap: onShare,
                          child: AppIcon.outline(
                            AppIcons.cardShare,
                            size: 19,
                            color: AppColors.grey,
                          ),
                        ),
                      if (onBookmark != null)
                        _CardAction(
                          label: bookmarked
                              ? 'Remove bookmark'
                              : 'Add bookmark',
                          toggled: bookmarked,
                          onTap: onBookmark,
                          child: bookmarked
                              ? Pop(
                                  key: ValueKey('bm-on'),
                                  child: AppIcon.filled(
                                    AppIcons.bookFill,
                                    size: 19,
                                    color: AppColors.bookmarkOn,
                                  ),
                                )
                              : AppIcon.filled(
                                  AppIcons.bookOut,
                                  size: 19,
                                  color: AppColors.grey,
                                  key: ValueKey('bm-off'),
                                ),
                        ),
                    ],
                  ),
                ),
              if (actionLabel == null)
                Positioned(
                  right: 14,
                  bottom: 18,
                  child: _CardChevron(hover: hover),
                ),
            ],
          ),
        ),
      ),
    );
    if (!animate) return card;
    return Rise.card(delay: Motion.stagger(context, index), child: card);
  }
}

/// Name + (tag chip, pin, city) column shared by HomeCard and RailCard.
class _NameBlock extends StatelessWidget {
  const _NameBlock({
    required this.name,
    required this.tag,
    required this.city,
    this.badges = const [],
  });

  final List<Widget> badges;
  final String name;
  final String tag;
  final String city;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (badges.isEmpty)
          _FitName(name)
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [_FitName(name), ...badges],
          ),
        const SizedBox(height: 5),
        Row(
          children: [
            TagChip(tag),
            const SizedBox(width: 8),
            Flexible(child: PinCity(city)),
          ],
        ),
      ],
    );
  }
}

/// The card name on ONE line.
class _FitName extends StatelessWidget {
  const _FitName(this.name);

  final String name;

  static const double _lineHeight = 23;
  static const double _minScale = 0.72;

  @override
  Widget build(BuildContext context) {
    final base = AppText.cardName;
    final size = base.fontSize ?? 18;
    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: name, style: base),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final fits = !box.hasBoundedWidth || painter.width <= box.maxWidth;
        final scale = fits
            ? 1.0
            : (box.maxWidth / painter.width).clamp(_minScale, 1.0);
        final fontSize = size * scale;
        return Text(
          name,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(
            fontSize: fontSize,
            height: _lineHeight / fontSize,
          ),
        );
      },
    );
  }
}

class _MatchPill extends StatelessWidget {
  const _MatchPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mossChip,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppText.sans(
          size: 12.5,
          color: AppColors.mossText,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CardChevron extends StatelessWidget {
  const _CardChevron({this.hover = false});

  final bool hover;

  @override
  Widget build(BuildContext context) {
    final moves = hover && !Motion.reduced(context);
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: Motion.dur(context, AppDur.base),
        curve: AppCurves.easeOut,
        transform: Matrix4.translationValues(moves ? 2 : 0, 0, 0),
        child: AppIcon.outline(
          AppIcons.cardChevron,
          size: 18,
          stroke: 2.2,
          color: AppColors.chevron,
        ),
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  const _HoverCard({required this.onTap, required this.builder});

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool hover) builder;

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hover = false;

  static final _radius = BorderRadius.circular(AppRadius.homeCard);
  static BoxDecoration get _hoverDecoration => BoxDecoration(
    borderRadius: _radius,
    boxShadow: [
      BoxShadow(
        color: Color(0x8C1F3F27),
        offset: Offset(0, 18),
        blurRadius: 30,
        spreadRadius: -20,
      ),
      BoxShadow(color: AppColors.hoverRing, spreadRadius: 1.5),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!_hover && mounted) setState(() => _hover = true);
      },
      onExit: (_) {
        if (_hover && mounted) setState(() => _hover = false);
      },
      child: Pressable(
        onTap: widget.onTap,
        scale: PressScale.homeCard,
        hoverOffset: const Offset(0, -2),
        hoverDecoration: _hoverDecoration,
        hoverDuration: AppDur.base,
        borderRadius: _radius,
        child: widget.builder(
          context,
          _hover && widget.onTap != null && !Motion.reduced(context),
        ),
      ),
    );
  }
}

/// 36 x 38 icon button on a home card (share / bookmark).
class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.child,
    required this.label,
    required this.onTap,
    this.toggled,
  });

  final Widget child;
  final String label;
  final VoidCallback? onTap;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      toggled: toggled,
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        scale: PressScale.cardAction,
        hoverColor: AppColors.hoverFill,
        hoverDuration: AppDur.base,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 36, height: 38, child: Center(child: child)),
      ),
    );
  }
}

/// The "New on Start.sa" rail card (prototype hc1 v3 rcard).
class RailCard extends StatelessWidget {
  const RailCard({
    super.key,
    required this.name,
    required this.tag,
    required this.city,
    required this.body,
    required this.joined,
    this.kind = HueAvatarKind.startup,
    this.onTap,
    this.imageUrl,
    this.imageData,
  });

  final String name;
  final String tag;
  final String city;
  final String body;

  /// e.g.
  final String joined;
  final HueAvatarKind kind;
  final VoidCallback? onTap;
  final String? imageUrl;
  final String? imageData;

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      onTap: onTap,
      builder: (context, hover) => Semantics(
        container: true,
        button: true,
        label: 'New: $name, $tag, $city. $joined',
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.homeCard),
            boxShadow: AppShadow.homeCard,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HueAvatar(
                          name: name,
                          kind: kind,
                          size: 58,
                          imageUrl: imageUrl,
                          imageData: imageData,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _NameBlock(name: name, tag: tag, city: city),
                        ),
                        const SizedBox(width: 14),
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: _NewBadge(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 46),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.cardBody,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      joined,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 12.5,
                        color: AppColors.gold700,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 14,
                bottom: 18,
                child: _CardChevron(hover: hover),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mossChip,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'NEW',
        style: AppText.sans(
          size: 10,
          color: AppColors.mossText,
          weight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class SnapRail extends StatelessWidget {
  const SnapRail({
    super.key,
    required this.children,
    this.peek = 60,
    this.gap = 12,
    this.padding = const EdgeInsets.fromLTRB(16, 2, 16, 10),
    this.controller,
  });

  final List<Widget> children;

  /// How much narrower than the rail each item is (shows the next card).
  final double peek;
  final double gap;
  final EdgeInsets padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - peek).clamp(160.0, 4000.0);
        return SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: padding,
          clipBehavior: Clip.none,
          physics: _SnapPhysics(extent: itemWidth + gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                SizedBox(width: itemWidth, child: children[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// scroll-snap-type: x mandatory: settles on multiples of extent.
class _SnapPhysics extends ScrollPhysics {
  const _SnapPhysics({super.parent, required this.extent});

  final double extent;

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapPhysics(parent: buildParent(ancestor), extent: extent);

  double _target(ScrollMetrics position, double velocity, Tolerance tol) {
    var page = position.pixels / extent;
    if (velocity < -tol.velocity) {
      page -= 0.5;
    } else if (velocity > tol.velocity) {
      page += 0.5;
    }
    return page.roundToDouble() * extent;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tol = toleranceFor(position);
    final target = _target(
      position,
      velocity,
      tol,
    ).clamp(position.minScrollExtent, position.maxScrollExtent);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tol,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}
