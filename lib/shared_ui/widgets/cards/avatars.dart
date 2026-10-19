import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// Initials rule (docs/02 §6): first letter of the first word plus the first
/// letter of the last word; a single word gives its first two letters.
/// Uppercase. Returns '' for an empty name.
String appInitials(String? name) {
  final words = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '';
  final first = words.first;
  final String second;
  if (words.length > 1) {
    second = words.last.characters.first;
  } else {
    second = first.characters.length > 1 ? first.characters.elementAt(1) : '';
  }
  return (first.characters.first + second).toUpperCase();
}

/// What a [HueAvatar] represents: startups and programs are rounded squares,
/// investors are circles.
enum HueAvatarKind { startup, investor, program }

/// The hue avatar (prototype `.av.avC`): fill = 10 % of the name's hue on
/// white, text = the hue, inner ring 1.5 px = 35 % hue. Used on home cards,
/// rails, trending rows, profile lists and dropdown options.
///
/// Common sizes: 58 (home card, font 18), 50 (trending, 15), 44 (lists, 15),
/// 36 (dropdown, 12.5). [name] drives both the initials and the hue.
class HueAvatar extends StatelessWidget {
  const HueAvatar({
    super.key,
    required this.name,
    this.kind = HueAvatarKind.startup,
    this.size = 58,
    this.fontSize,
  });

  final String name;
  final HueAvatarKind kind;
  final double size;

  /// Overrides the size-based default font size.
  final double? fontSize;

  static double _defaultFont(double size) {
    if (size >= 58) return 18;
    if (size >= 50) return 15;
    if (size >= 44) return 15;
    if (size >= 36) return 12.5;
    return size * 0.34;
  }

  @override
  Widget build(BuildContext context) {
    final hue = AppColors.hueFor(name);
    final circle = kind == HueAvatarKind.investor;
    final radius = size >= 58 ? 16.0 : 14.0;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.avatarFill(hue),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
          border: Border.all(color: AppColors.avatarRing(hue), width: 1.5),
        ),
        child: Text(
          appInitials(name),
          maxLines: 1,
          style: AppText.sans(
            size: fontSize ?? _defaultFont(size),
            color: hue,
            weight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// Colour family of a [TileAvatar].
enum TileTone {
  /// Gradient `#EEF4EF -> #DFEAE1`, moss600 text.
  moss,

  /// Gradient `#FAF3E3 -> #F2E6C9`, `#7A5A12` text.
  gold,
}

/// The tile avatar (prototype `.avatar-tile`): a gradient tile with initials.
/// Defaults to 46 px, radius 14, 15/700. Variants used by the prototype:
/// profile header gold 60 / radius 17 / font 20; team member moss 40 / radius
/// 12 / font 13; request rows 38 round; My Startups gold 48 / radius 14.
class TileAvatar extends StatelessWidget {
  const TileAvatar({
    super.key,
    required this.initials,
    this.tone = TileTone.moss,
    this.size = 46,
    this.radius,
    this.fontSize,
    this.round = false,
    this.shadows,
  });

  /// Initials to show (use [appInitials]).
  final String initials;
  final TileTone tone;
  final double size;

  /// Corner radius; defaults to 14. Ignored when [round].
  final double? radius;

  /// Defaults to 15 at 46 px, scaled with [size].
  final double? fontSize;

  /// `t-round`: a circle.
  final bool round;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final gold = tone == TileTone.gold;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: round ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: round ? null : BorderRadius.circular(radius ?? 14),
          boxShadow: shadows,
          // CSS 145deg.
          gradient: LinearGradient(
            begin: const Alignment(-0.574, -0.819),
            end: const Alignment(0.574, 0.819),
            colors: gold
                ? const [Color(0xFFFAF3E3), Color(0xFFF2E6C9)]
                : const [Color(0xFFEEF4EF), Color(0xFFDFEAE1)],
          ),
        ),
        child: Text(
          initials,
          maxLines: 1,
          style: AppText.sans(
            size: fontSize ?? size * 15 / 46,
            color: gold ? AppColors.tagGoldText : AppColors.moss600,
            weight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
