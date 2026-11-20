import 'package:flutter/material.dart';

import '../../../helpers/picture_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

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

class _AvatarPicture extends StatelessWidget {
  const _AvatarPicture({this.data, this.url, required this.fallback});

  final String? data;
  final String? url;
  final Widget fallback;

  /// True when there is something to draw.
  static bool has(String? data, String? url) =>
      PictureData.bytes(data) != null || (url ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final bytes = PictureData.bytes(data);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    final u = (url ?? '').trim();
    if (u.isEmpty) return fallback;
    return Image.network(
      u,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}

/// What a HueAvatar represents: startups and programs are rounded squares, investors are circles.
enum HueAvatarKind { startup, investor, program }

class HueAvatar extends StatelessWidget {
  const HueAvatar({
    super.key,
    required this.name,
    this.kind = HueAvatarKind.startup,
    this.size = 58,
    this.fontSize,
    this.imageUrl,
    this.imageData,
  });

  final String name;
  final HueAvatarKind kind;
  final double size;

  /// The startup's logo or the person's photo.
  final String? imageUrl;

  /// The saved copy of the picture (base64): shown first when there is one.
  final String? imageData;

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
    final initials = Text(
      appInitials(name),
      maxLines: 1,
      style: AppText.sans(
        size: fontSize ?? _defaultFont(size),
        color: AppColors.avatarInk(hue),
        weight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
    final hasPicture = _AvatarPicture.has(imageData, imageUrl);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        clipBehavior: hasPicture ? Clip.antiAlias : Clip.none,
        decoration: BoxDecoration(
          color: AppColors.avatarFill(hue),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
          border: Border.all(color: AppColors.avatarRing(hue), width: 1.5),
        ),
        child: hasPicture
            ? _AvatarPicture(
                data: imageData,
                url: imageUrl,
                fallback: Center(child: initials),
              )
            : initials,
      ),
    );
  }
}

/// Colour family of a TileAvatar.
enum TileTone {
  /// Gradient #EEF4EF -> #DFEAE1, moss600 text.
  moss,

  /// Gradient #FAF3E3 -> #F2E6C9, #7A5A12 text.
  gold,
}

/// The tile avatar (prototype .avatar-tile): a gradient tile with initials.
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
    this.imageUrl,
    this.imageData,
  });

  /// Initials to show (use appInitials).
  final String initials;
  final TileTone tone;
  final double size;

  /// Corner radius; defaults to 14.
  final double? radius;

  /// Defaults to 15 at 46 px, scaled with size.
  final double? fontSize;

  /// t-round: a circle.
  final bool round;
  final List<BoxShadow>? shadows;

  final String? imageUrl;

  /// The saved copy of the picture (base64): shown first when there is one.
  final String? imageData;

  @override
  Widget build(BuildContext context) {
    final gold = tone == TileTone.gold;
    final text = Text(
      initials,
      maxLines: 1,
      style: AppText.sans(
        size: fontSize ?? size * 15 / 46,
        color: gold ? AppColors.tagGoldText : AppColors.mossText,
        weight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
    final hasPicture = _AvatarPicture.has(imageData, imageUrl);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        clipBehavior: hasPicture ? Clip.antiAlias : Clip.none,
        decoration: BoxDecoration(
          shape: round ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: round ? null : BorderRadius.circular(radius ?? 14),
          boxShadow: shadows,
          // CSS 145deg.
          gradient: LinearGradient(
            begin: const Alignment(-0.574, -0.819),
            end: const Alignment(0.574, 0.819),
            colors: gold
                ? [AppColors.tileGoldTop, AppColors.tileGoldBottom]
                : [AppColors.tileMossTop, AppColors.tileMossBottom],
          ),
        ),
        child: hasPicture
            ? _AvatarPicture(
                data: imageData,
                url: imageUrl,
                fallback: Center(child: text),
              )
            : text,
      ),
    );
  }
}
