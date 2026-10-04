import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared_ui/theme/app_theme.dart';

/// A startup's logo in a circle. Shows, in order of preference: a freshly
/// picked [file], the uploaded [url], or the first letter of the name on a
/// moss-green circle. A broken or slow URL falls back to the letter.
class StartupLogo extends StatelessWidget {
  const StartupLogo({
    super.key,
    required this.initial,
    required this.size,
    this.url,
    this.file,
    this.ring = false,
  });

  final String initial;
  final double size;
  final String? url;
  final File? file;

  /// Adds a white ring, for logos placed on the green header.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Monogram(initial: initial, size: size);
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: ring
            ? Border.all(color: AppColors.surface, width: AppSpacing.xs)
            : Border.all(color: AppColors.border),
        boxShadow: ring ? AppShadows.raised : null,
      ),
      child: ClipOval(child: content),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.initial, required this.size});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.moss600, AppColors.green],
        ),
      ),
      child: Center(child: Text(initial, style: AppText.monogram(size))),
    );
  }
}
