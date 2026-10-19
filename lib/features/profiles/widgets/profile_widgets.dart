import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/bookmark_repository.dart';
import '../../../data_access/repositories/interest_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';

/// Side effects shared by the startup, investor and program profiles: the
/// bookmark, share and request / interest toggles with their exact toasts.
class ProfileActions {
  ProfileActions._();

  /// Share: the prototype only shows the toast.
  static void share(BuildContext context) =>
      AppToast.show(context, ProfileStrings.linkCopied);

  /// Toggles the bookmark under [key] (`s-<id>`, `i-<id>`, `p-<id>`).
  static void toggleBookmark(BuildContext context, String key) {
    final on = BookmarkRepository.instance.toggle(key);
    AppToast.show(
      context,
      on
          ? ProfileStrings.addedToBookmarks
          : ProfileStrings.removedFromBookmarks,
    );
  }

  /// Investor -> startup / founder -> investor "Send investment request",
  /// toggled: a second tap withdraws it.
  static void toggleRequest(BuildContext context, String key, String name) {
    final sent = RequestRepository.instance.toggleOutgoing(key);
    AppToast.show(
      context,
      sent
          ? ProfileStrings.requestSentTo(name)
          : ProfileStrings.withdrawnFrom(name),
    );
  }

  /// Guest "Express interest", toggled.
  static void toggleInterest(BuildContext context, String key, String name) {
    final sent = InterestRepository.instance.toggleSent(key);
    AppToast.show(
      context,
      sent
          ? ProfileStrings.interestSentTo(name)
          : ProfileStrings.withdrawnFrom(name),
    );
  }
}

/// The pinned bottom bar of the startup and investor profiles (prototype
/// `.pcta`): cream, top hairline, padding 12 16 20, one 52 px button. When
/// [done] the button gets the "done" look (check icon, moss border).
class ProfileCtaBar extends StatelessWidget {
  const ProfileCtaBar({
    super.key,
    required this.label,
    required this.icon,
    required this.done,
    required this.onPressed,
  });

  final String label;

  /// Filled icon path shown while not [done].
  final String icon;
  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, math.max(20, inset)),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.dividerSoft)),
      ),
      child: AppButton(
        label: label,
        icon: done ? null : icon,
        variant: done ? AppButtonVariant.done : AppButtonVariant.primary,
        size: AppButtonSize.cta,
        onPressed: onPressed,
      ),
    );
  }
}

/// The head block of the own and investor profiles (prototype `.ptop`):
/// avatar 96 (4 px `#F6F4EF` ring, [photoUrl] when set), [name] 24/30, [role]
/// line, meta row ([city] + dot + [metaTail]), the caps label [tagsLabel]
/// with [tags] chips and the optional LinkedIn pill. Sits directly under a
/// `ProfileBanner` (which reports its 48 px overlap).
class ProfileHead extends StatelessWidget {
  const ProfileHead({
    super.key,
    required this.initials,
    required this.name,
    required this.role,
    required this.metaTail,
    required this.tagsLabel,
    required this.tags,
    this.city,
    this.photoUrl,
    this.linkedin,
    this.onLinkedin,
  });

  final String initials;
  final String name;
  final String role;
  final String? city;
  final String metaTail;
  final String tagsLabel;
  final List<String> tags;
  final String? photoUrl;

  /// Shows the LinkedIn pill when non-empty.
  final String? linkedin;
  final VoidCallback? onLinkedin;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (photoUrl ?? '').isNotEmpty;
    final hasCity = (city ?? '').trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.mossChip,
              border: Border.all(color: AppColors.profileBg, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x73000000),
                  blurRadius: 20,
                  spreadRadius: -10,
                  offset: Offset(0, 8),
                ),
              ],
              image: hasPhoto
                  ? DecorationImage(
                      image: NetworkImage(photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasPhoto
                ? null
                : Text(
                    initials,
                    style: AppText.sans(
                      size: 30,
                      weight: FontWeight.w700,
                      color: AppColors.moss600,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              name,
              style: AppText.sans(
                size: 24,
                height: 30,
                weight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            role,
            style: AppText.sans(
              size: 15,
              weight: FontWeight.w500,
              color: AppColors.paragraph,
            ),
          ),
          const SizedBox(height: 6),
          DefaultTextStyle(
            style: AppText.sans(size: 13, color: AppColors.metaText),
            child: Row(
              children: [
                if (hasCity) ...[
                  const AppIcon.filled(
                    AppIcons.pin,
                    size: 15,
                    color: AppColors.metaText,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      city!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.chevron,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    metaTail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              tagsLabel.toUpperCase(),
              style: AppText.sans(
                size: 11.5,
                weight: FontWeight.w600,
                color: AppColors.hint,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final t in tags) _SectorChip(t)],
            ),
          ],
          if ((linkedin ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _LinkedInPill(onTap: onLinkedin),
          ],
        ],
      ),
    );
  }
}

class _SectorChip extends StatelessWidget {
  const _SectorChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.mossChip,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: AppText.sans(
        size: 12.5,
        weight: FontWeight.w600,
        color: AppColors.moss600,
      ),
    ),
  );
}

class _LinkedInPill extends StatelessWidget {
  const _LinkedInPill({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: ProfileStrings.linkedin,
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          scale: 0.97,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.chipBorderSoft),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon.filled(
                  AppIcons.linkedIn,
                  size: 16,
                  color: AppColors.linkedIn,
                ),
                const SizedBox(width: 7),
                Text(
                  ProfileStrings.linkedin,
                  style: AppText.sans(size: 13.5, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A divided list of sections of the own / investor profile: the standard
/// `.psecs` column (padding 0 16 32, gap 12).
class ProfileSections extends StatelessWidget {
  const ProfileSections({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ),
    );
  }
}
