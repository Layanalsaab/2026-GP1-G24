import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';

/// The small Start.sa logo of the headers (`assets/images/logo_small.png`),
/// fading in once (500 ms). 42 px on auth/step/manage/profile headers with a
/// 6 px right margin; pass `size: 36` for the home header.
class HeaderLogo extends StatelessWidget {
  const HeaderLogo({
    super.key,
    this.size = AppSize.headerLogoAuth,
    this.rightMargin = 6,
    this.animate = true,
  });

  final double size;

  /// Space to the right of the logo (6 on the auth-style headers).
  final double rightMargin;

  /// Fade in on mount (the documented `fade-in`).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/logo_small.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Start.sa',
    );
    return Padding(
      padding: EdgeInsets.only(right: rightMargin),
      child: animate ? FadeInOnce(child: image) : image,
    );
  }
}

/// Plain 44 x 44 circular icon button (`.iconbtn`): transparent, press scale
/// 0.92. Pass a filled [icon] path from [AppIcons] (24 viewBox) or an
/// outline one via [stroke].
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.color = AppColors.ink,
    this.iconSize = 24,
    this.size = AppSize.iconButton,
    this.stroke,
    this.child,
  });

  final String icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final Color color;
  final double iconSize;
  final double size;

  /// Stroke width for outline icons (null = filled icon).
  final double? stroke;

  /// Replaces the icon (e.g. a popping bookmark).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final glyph =
        child ??
        (stroke == null
            ? AppIcon.filled(icon, size: iconSize, color: color)
            : AppIcon.outline(
                icon,
                size: iconSize,
                color: color,
                stroke: stroke,
              ));
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Pressable(
        scale: 0.92,
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: glyph),
        ),
      ),
    );
  }
}

/// White back chevron on a green header (44 x 44, filled `chevLeft`, 24).
/// Use `HeaderBackButton.profile` for the thin stroked chevron of the
/// profile banner.
class HeaderBackButton extends StatelessWidget {
  const HeaderBackButton({
    super.key,
    required this.onTap,
    this.semanticLabel = 'Back',
    this.color = AppColors.onDark,
    this.close = false,
  }) : profile = false;

  /// Profile banner back button (`m15 18-6-6 6-6`, stroke 2, radius 12).
  const HeaderBackButton.profile({
    super.key,
    required this.onTap,
    this.semanticLabel = 'Back',
    this.color = AppColors.onDark,
  }) : profile = true,
       close = false;

  final VoidCallback? onTap;
  final String semanticLabel;
  final Color color;

  /// Show a close (x) instead of a chevron (startup preview mode).
  final bool close;
  final bool profile;

  @override
  Widget build(BuildContext context) {
    if (profile) {
      return AppIconButton(
        icon: AppIcons.profileBack,
        stroke: 2,
        iconSize: 24,
        color: color,
        onTap: onTap,
        semanticLabel: semanticLabel,
      );
    }
    return AppIconButton(
      icon: close ? AppIcons.close : AppIcons.chevLeft,
      color: color,
      onTap: onTap,
      semanticLabel: semanticLabel,
    );
  }
}

/// Round 40 x 40 "glass" icon button on a green header (`.hicb`): white 12 %
/// fill, white icon (20 share / 21 bookmark), press 0.92.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.iconSize = 20,
    this.stroke,
    this.child,
    this.selected,
  });

  /// Share glass button.
  const GlassIconButton.share({super.key, required this.onTap})
    : icon = AppIcons.share,
      semanticLabel = 'Share',
      iconSize = 20,
      stroke = null,
      child = null,
      selected = null;

  final String icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double iconSize;
  final double? stroke;
  final Widget? child;

  /// Reports a pressed/selected state to screen readers (bookmark).
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final glyph =
        child ??
        (stroke == null
            ? AppIcon.filled(icon, size: iconSize, color: AppColors.onDark)
            : AppIcon.outline(
                icon,
                size: iconSize,
                color: AppColors.onDark,
                stroke: stroke,
              ));
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Pressable(
        scale: 0.92,
        onTap: onTap,
        child: Container(
          width: AppSize.glassIconButton,
          height: AppSize.glassIconButton,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.glassFill,
          ),
          child: glyph,
        ),
      ),
    );
  }
}

/// Bookmark toggle for headers: outline when off, filled (Pop on mount) when
/// on. Glass (40 px, icon 21) by default; `glass: false` gives the plain 44 px
/// icon button (icon 22, [color]). Never show it to guests.
class HeaderBookmarkButton extends StatelessWidget {
  const HeaderBookmarkButton({
    super.key,
    required this.bookmarked,
    required this.onTap,
    this.glass = true,
    this.color = AppColors.onDark,
  });

  final bool bookmarked;
  final VoidCallback? onTap;
  final bool glass;

  /// Icon color for the plain (non-glass) variant.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = glass ? 21.0 : 22.0;
    final c = glass ? AppColors.onDark : color;
    final icon = bookmarked
        ? Pop(
            key: const ValueKey('bm-on'),
            child: AppIcon.filled(AppIcons.bookFill, size: size, color: c),
          )
        : AppIcon.filled(AppIcons.bookOut, size: size, color: c);
    final label = bookmarked ? 'Remove bookmark' : 'Bookmark';
    if (glass) {
      return GlassIconButton(
        icon: AppIcons.bookOut,
        semanticLabel: label,
        selected: bookmarked,
        onTap: onTap,
        child: icon,
      );
    }
    return AppIconButton(
      icon: AppIcons.bookOut,
      semanticLabel: label,
      onTap: onTap,
      child: icon,
    );
  }
}

/// Size of a [GoldPillButton].
enum GoldPillSize {
  /// Guest "Sign up" on the home header: 28 high, padding 0 11, 12/600,
  /// border 1.2, press 0.95.
  compact,

  /// My Startups "Add": 36 high, padding 0 15 0 11, 14/600, icon 18, gap 2,
  /// 6 px right margin.
  regular,
}

/// The gold outline pill on green headers: guest "Sign up" and My Startups
/// "Add" (text `#F3E6C4`, border `#E3CF9B` 75 %, transparent fill).
class GoldPillButton extends StatefulWidget {
  const GoldPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.size = GoldPillSize.compact,
    this.semanticLabel,
  });

  /// Guest "Sign up" pill.
  const GoldPillButton.signUp({super.key, required this.onTap})
    : label = 'Sign up',
      icon = null,
      size = GoldPillSize.compact,
      semanticLabel = null;

  /// My Startups "Add" pill (plus icon).
  const GoldPillButton.add({super.key, required this.onTap, this.label = 'Add'})
    : icon = AppIcons.plus,
      size = GoldPillSize.regular,
      semanticLabel = null;

  final String label;
  final VoidCallback? onTap;

  /// Optional filled icon path shown before the label.
  final String? icon;
  final GoldPillSize size;
  final String? semanticLabel;

  @override
  State<GoldPillButton> createState() => _GoldPillButtonState();
}

class _GoldPillButtonState extends State<GoldPillButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final compact = widget.size == GoldPillSize.compact;
    final text = Text(
      widget.label,
      maxLines: 1,
      style: AppText.sans(
        size: compact ? 12 : 14,
        weight: FontWeight.w600,
        color: AppColors.goldPillText,
        letterSpacing: compact ? 0.1 : null,
      ),
    );
    final pill = Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedContainer(
        duration: Motion.dur(context, Motion.press),
        curve: Motion.easeOut,
        height: compact ? 28 : 36,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 11)
            : const EdgeInsets.fromLTRB(11, 0, 15, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: _down ? AppColors.goldPillPressed : Colors.transparent,
          border: Border.all(
            color: AppColors.goldPillBorder,
            width: compact ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              AppIcon.filled(
                widget.icon!,
                size: 18,
                color: AppColors.goldPillText,
              ),
              SizedBox(width: compact ? 4 : 2),
            ],
            text,
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(right: compact ? 0 : 6),
        child: Pressable(
          scale: compact ? 0.95 : 0.97,
          onTap: widget.onTap,
          child: pill,
        ),
      ),
    );
  }
}

/// "Edit profile" outline pill on the profile banner: 36 high, padding 0 14,
/// white 8 % fill, white 30 % border, pencil icon + 13.5/600 label.
class ProfileEditPill extends StatelessWidget {
  const ProfileEditPill({
    super.key,
    required this.onTap,
    this.label = 'Edit profile',
  });

  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        scale: 0.95,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: AppColors.editPillFill,
            border: Border.all(color: AppColors.editPillBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.outline(
                AppIcons.pencil,
                size: 18,
                color: AppColors.onDark,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.sans(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: AppColors.onDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
