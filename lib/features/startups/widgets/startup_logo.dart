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
  });

  final String initials;
  final double size;
  final String? url;
  final File? file;

  /// Adds a white ring and shadow, for logos placed on the green header.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Initials(initials: initials, size: size);
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
    final radius = BorderRadius.circular(size * 0.22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: AppColors.moss100,
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
  const _Initials({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.moss100,
      child: Center(child: Text(initials, style: AppText.initials(size))),
    );
  }
}
