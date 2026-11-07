import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';

/// The pieces of the "Contact Information" section, shared by the investor's
/// own profile, a founder's own profile and an investor seen by someone else,
/// so the three look and read the same.

/// The intro line of the section on your own profile.
class ContactIntro extends StatelessWidget {
  const ContactIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        ProfileStrings.contactIntro,
        style: AppText.sans(size: 13.5, height: 20, color: AppColors.grey),
      ),
    );
  }
}

/// Your own email or phone: the label, the value, a note saying who sees it
/// ("Shown on your profile" / "Private. Only you can see your email") and a
/// Public / Only you tag at the end.
class OwnContactRow extends StatelessWidget {
  const OwnContactRow({
    super.key,
    required this.icon,
    required this.label,
    required this.noun,
    required this.value,
    required this.isPublic,
    this.showDivider = false,
  });

  /// A filled [AppIcons] path (mail, phone).
  final String icon;

  /// "Email" / "Phone".
  final String label;

  /// "email" / "phone number": the end of the private note.
  final String noun;
  final String value;
  final bool isPublic;
  final bool showDivider;

  /// "Shown on your profile" or "Private. Only you can see your email".
  static String note({required bool isPublic, required String noun}) => isPublic
      ? ProfileStrings.contactShown
      : ProfileStrings.contactPrivateNote(noun);

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      showDivider: showDivider,
      icon: icon,
      trailing: ContactVisibilityPill(isPublic: isPublic),
      children: [
        Text(label, style: AppText.sans(size: 12, color: AppColors.hint)),
        Text(
          value.trim().isEmpty ? ProfileStrings.notAdded : value,
          style: AppText.sans(size: 15, weight: FontWeight.w600),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            note(isPublic: isPublic, noun: noun),
            style: AppText.sans(size: 12.5, height: 17, color: AppColors.grey),
          ),
        ),
      ],
    );
  }
}

/// Someone else's detail that they made Public: the label and the value.
class PublicContactRow extends StatelessWidget {
  const PublicContactRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = false,
  });

  final String icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      showDivider: showDivider,
      icon: icon,
      children: [
        Text(label, style: AppText.sans(size: 12, color: AppColors.hint)),
        Text(value, style: AppText.sans(size: 15, weight: FontWeight.w600)),
      ],
    );
  }
}

/// Someone else's detail that is private: "Email is private" with no value,
/// and a lock with the "Private" tag at the end.
class PrivateContactRow extends StatelessWidget {
  const PrivateContactRow({
    super.key,
    required this.icon,
    required this.label,
    this.showDivider = false,
  });

  final String icon;
  final String label;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      showDivider: showDivider,
      icon: icon,
      trailing: const _PrivateTag(),
      children: [
        Text(label, style: AppText.sans(size: 12, color: AppColors.hint)),
        Text(
          ProfileStrings.detailPrivate(label),
          style: AppText.sans(
            size: 15,
            weight: FontWeight.w500,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }
}

/// The small "Public" / "Only you" tag at the end of one of your own rows:
/// height 22, 12 px semibold; Public in moss, Only you in grey.
class ContactVisibilityPill extends StatelessWidget {
  const ContactVisibilityPill({super.key, required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final color = isPublic ? AppColors.moss600 : AppColors.grey;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isPublic ? const Color(0xFFEEF4EF) : const Color(0xFFF0EDE6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isPublic ? const Color(0xFFCFE0D3) : const Color(0xFFF0EDE6),
        ),
      ),
      child: Text(
        isPublic ? ProfileStrings.contactPublic : ProfileStrings.contactOnlyYou,
        style: AppText.sans(size: 12, weight: FontWeight.w600, color: color),
      ),
    );
  }
}

/// The "Private" tag with a lock, for a detail someone else keeps private.
class _PrivateTag extends StatelessWidget {
  const _PrivateTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon.filled(AppIcons.lock, size: 12, color: AppColors.grey),
          const SizedBox(width: 4),
          Text(
            ProfileStrings.privateTag,
            style: AppText.sans(
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// The shared row layout: a 20 px icon, the lines, the optional tag.
class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.icon,
    required this.children,
    required this.showDivider,
    this.trailing,
  });

  final String icon;
  final List<Widget> children;
  final bool showDivider;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(top: BorderSide(color: AppColors.rowSeparator))
            : null,
      ),
      child: Row(
        children: [
          AppIcon.filled(icon, size: 20, color: AppColors.metaText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
