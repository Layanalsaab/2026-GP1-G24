import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import 'avatars.dart';
import 'pills.dart';

/// The home card (prototype `hc1 v3`, docs/05 §B2): used on Hub, results,
/// Matches, Recommended and Support Channels.
///
/// White, radius 20, padding 20. Top row: [HueAvatar] 58, name (18/700), tag
/// chip + pin + [city], then the share and (optionally) bookmark buttons. Then
/// the [body] line (15.5/23), the optional match row and a chevron at the
/// bottom-right.
///
/// * [onBookmark] null hides the bookmark button (guests can never bookmark).
///   [bookmarked] draws the filled `#A87A25` icon with a Pop.
/// * [matchPercent] + [matchReason] show the "92% match" row (Matches tab).
/// * [index] staggers the cardIn entrance by 40 ms x index. To replay the
///   stagger when the list content changes, give the list/cards a new key.
/// * Press scales to 0.985.
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
    this.index = 0,
    this.animate = true,
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

  /// e.g. 92 -> "92% match".
  final int? matchPercent;
  final String? matchReason;

  /// Position in the list, for the entrance stagger.
  final int index;

  /// Set false to skip the cardIn entrance.
  final bool animate;

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
                        HueAvatar(name: name, kind: kind, size: 58),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _NameBlock(name: name, tag: tag, city: city),
                        ),
                        // Space reserved for the absolutely placed actions
                        // (the prototype pulls them out with negative margins).
                        if (showActions) const SizedBox(width: 63),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      // A long description stops at 3 lines with "..."; the
                      // profile (tap the card) shows all of it.
                      child: Text(
                        body,
                        style: AppText.cardBody,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (matchPercent != null) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(right: 22),
                        child: Row(
                          children: [
                            _MatchPill('$matchPercent% match'),
                            if (matchReason != null) ...[
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  matchReason!,
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
                          child: const AppIcon.outline(
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
                              ? const Pop(
                                  key: ValueKey('bm-on'),
                                  child: AppIcon.filled(
                                    AppIcons.bookFill,
                                    size: 19,
                                    color: AppColors.bookmarkOn,
                                  ),
                                )
                              : const AppIcon.filled(
                                  AppIcons.bookOut,
                                  size: 19,
                                  color: AppColors.grey,
                                  key: ValueKey('bm-off'),
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
    if (!animate) return card;
    return Rise.card(delay: Motion.stagger(context, index), child: card);
  }
}

/// Name + (tag chip, pin, city) column shared by [HomeCard] and [RailCard].
class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.name, required this.tag, required this.city});

  final String name;
  final String tag;
  final String city;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.cardName,
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            TagChip(tag),
            const SizedBox(width: 8),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIcon.filled(
                    AppIcons.pin,
                    size: 13,
                    color: AppColors.hint,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(size: 13, color: AppColors.metaText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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
          color: AppColors.moss600,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The chevron nudges 2 px to the right while the card is hovered (200 ms
/// easeOut; not under reduced motion).
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
        child: const AppIcon.outline(
          AppIcons.cardChevron,
          size: 18,
          stroke: 2.2,
          color: AppColors.chevron,
        ),
      ),
    );
  }
}

/// Shared hover/press wrapper of [HomeCard] and [RailCard]: press .985, and on
/// a mouse pointer lift -2 + shadow `0 18 30 -20 rgba(31,63,39,.55)` + ring
/// `0 0 0 1.5 #CFDCD2` over 200 ms easeOut. [builder] gets the hover flag (for
/// the chevron).
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
  static final _hoverDecoration = BoxDecoration(
    borderRadius: _radius,
    boxShadow: const [
      BoxShadow(
        color: Color(0x8C1F3F27),
        offset: Offset(0, 18),
        blurRadius: 30,
        spreadRadius: -20,
      ),
      BoxShadow(color: Color(0xFFCFDCD2), spreadRadius: 1.5),
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

/// 36 x 38 icon button on a home card (share / bookmark). Press scale 0.90,
/// hover fill `#F3F1EC` (200 ms).
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
        hoverColor: const Color(0xFFF3F1EC),
        hoverDuration: AppDur.base,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 36, height: 38, child: Center(child: child)),
      ),
    );
  }
}

/// The "New on Start.sa" rail card (prototype `hc1 v3 rcard`).
///
/// Same look as [HomeCard] but with a static "New" badge instead of the
/// share/bookmark actions, a body clamped to 2 lines (min height 46) and a
/// "Joined ..." line in gold. No entrance animation. Press scale 0.985.
/// Put these in a [SnapRail] (which gives them their width of screen - 60).
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
  });

  final String name;
  final String tag;
  final String city;
  final String body;

  /// e.g. "Joined today", "Joined 2 days ago".
  final String joined;
  final HueAvatarKind kind;
  final VoidCallback? onTap;

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
                        HueAvatar(name: name, kind: kind, size: 58),
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
          color: AppColors.moss600,
          weight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Horizontal rail of snapping cards (prototype `.rail`): padding 2 16 10,
/// gap 12, every item [peek] px narrower than the rail (screen - 60 at the
/// default) and snapping to the start with a 16 px inset.
///
/// Place it full-bleed (outside the 16 px page padding of the list): it adds
/// its own side padding. Children are given their width.
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

/// `scroll-snap-type: x mandatory`: settles on multiples of [extent].
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
