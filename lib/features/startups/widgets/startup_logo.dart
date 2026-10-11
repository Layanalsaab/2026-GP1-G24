import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared_ui/theme/app_theme.dart';

/// A startup's logo in a rounded square (Figma "V2 · 24 · My Startups").
/// Shows, in order of preference: a freshly picked [file], the uploaded
/// [url], or the startup's initials on light moss. A broken or slow URL
/// falls back to the initials.
class StartupLogo extends StatelessWidget {
  const StartupLogo({
    super.key,
    required this.initials,
    required this.size,
    this.url,
    this.file,
    this.ring = false,
    this.background = AppColors.moss100,
    this.foreground,
    this.fontSize,
    this.cornerFactor = 0.22,
  });

  final String initials;
  final double size;
  final String? url;
  final File? file;

  /// Adds a white ring and shadow, for logos placed on the green header.
  final bool ring;

  /// Square fill behind the initials (Figma: moss on lists, gold-tinted on
  /// the manage and profile pages).
  final Color background;

  /// Initials colour; defaults to the standard green.
  final Color? foreground;

  /// Initials size; defaults to a third of [size].
  final double? fontSize;

  /// Corner radius as a share of [size] (Figma: 0.27 on the larger logos).
  final double cornerFactor;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Initials(
      initials: initials,
      size: size,
      background: background,
      foreground: foreground,
      fontSize: fontSize,
    );
    Widget content;
    if (file != null) {
      content = Image.file(file!, fit: BoxFit.cover);
    } else if (url != null) {
      content = Image.network(
        url!,
        fit: BoxFit.cover,
        // Decode at the displayed size, not the uploaded size.
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
        errorBuilder: (_, _, _) => placeholder,
      );
    } else {
      content = placeholder;
    }

    // Corner radius grows with the logo, so small and large look alike.
    final radius = BorderRadius.circular(size * cornerFactor);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: background,
        border: ring
            ? Border.all(color: AppColors.surface, width: AppSpacing.xs)
            : null,
        boxShadow: ring ? AppShadows.raised : null,
      ),
      child: ClipRRect(borderRadius: radius, child: content),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({
    required this.initials,
    required this.size,
    required this.background,
    this.foreground,
    this.fontSize,
  });

  final String initials;
  final double size;
  final Color background;
  final Color? foreground;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Center(
        child: Text(
          initials,
          style: AppText.initials(size)
              .copyWith(fontSize: fontSize, color: foreground),
        ),
      ),
    );
  }
}
