import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Round avatar showing the person's initials ("Khalid Al-Mansour" -> "KA").
/// Photos are not supported yet: uploading them needs Cloud Storage.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.size = 72,
    this.goldBorder = false,
  });

  final String name;
  final double size;

  /// Gold ring, used on the green Account header.
  final bool goldBorder;

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
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.moss100,
          shape: BoxShape.circle,
          border: goldBorder
              ? Border.all(color: AppColors.gold, width: 2)
              : null,
        ),
        child: Text(
          initialsOf(name),
          style: AppText.serif(size: size / 3, color: AppColors.green),
        ),
      ),
    );
  }
}
