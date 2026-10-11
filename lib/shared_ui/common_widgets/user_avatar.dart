import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A person's round avatar. Shows, in order of preference: a freshly picked
/// [file], the saved [photoUrl], or the initials on moss green ("Khalid
/// Al-Mansour" gives "KA"). A photo that is loading, slow or broken shows the
/// initials, so the avatar is never empty.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.file,
    this.size = 40,
    this.ring = false,
    this.fontWeight = FontWeight.w600,
  });

  final String name;
  final String? photoUrl;
  final File? file;
  final double size;

  /// A thick cream ring around the avatar (the Profile and Edit profile
  /// designs, where it overlaps the green banner).
  final bool ring;

  final FontWeight fontWeight;

  /// First letter of the first and last words, upper-cased. "?" when empty.
  static String initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final first = words.first[0];
    final last = words.length > 1 ? words.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.moss600,
      child: Text(
        initialsOf(name),
        style: AppText.sans(
          size: size <= 44 ? size * 0.38 : size / 3,
          color: Colors.white,
          weight: fontWeight,
        ),
      ),
    );

    final url = photoUrl;
    final Widget content;
    if (file != null) {
      content = Image.file(
        file!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => initials,
      );
    } else if (url != null && url.isNotEmpty) {
      content = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Decode at the displayed size, not the uploaded size.
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : initials,
        errorBuilder: (_, _, _) => initials,
      );
    } else {
      content = initials;
    }

    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: ring ? Border.all(color: AppColors.cream, width: 4) : null,
        ),
        child: ClipOval(child: content),
      ),
    );
  }
}
