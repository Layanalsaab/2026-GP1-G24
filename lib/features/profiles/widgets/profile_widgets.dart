import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../helpers/share_link.dart';
import '../../../data_access/repositories/bookmark_repository.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';

/// Side effects shared by the startup, investor and program profiles: the
/// bookmark, share and request / interest toggles with their exact toasts.
class ProfileActions {
  ProfileActions._();

  /// Share: copies the link of the item behind [key] (`s-<id>`, `i-<id>`,
  /// `p-<id>`) and says "Link copied".
  static void share(BuildContext context, String key) =>
      ShareLink.copyKey(context, key);

  /// Toggles the bookmark under [key] (`s-<id>`, `i-<id>`, `p-<id>`).
  static void toggleBookmark(BuildContext context, String key) {
    BookmarkRepository.instance.toggle(key);
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
    this.onPressed,
  });

  final String label;

  /// Filled icon path shown while not [done].
  final String icon;
  final bool done;

  /// Null while requests are not built yet: the button looks the same and
  /// does nothing (no message either).
  final VoidCallback? onPressed;

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
          _AvatarIn(
            child: Container(
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
            // The sectors as plain text under the city line: a small target
            // icon and "Interested in HealthTech, Fintech" (sectors bolder).
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: AppIcon.filled(
                    AppIcons.target,
                    size: 15,
                    color: Color(0xFF8C918D),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      text: '$tagsLabel ',
                      style: AppText.sans(
                        size: 14,
                        height: 21,
                        color: const Color(0xFF6B726C),
                      ),
                      children: [
                        TextSpan(
                          text: tags.join(', '),
                          style: AppText.sans(
                            size: 14,
                            height: 21,
                            weight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
          scale: PressScale.smallPill,
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

/// Big profile avatar entrance: opacity 0 -> 1 and scale .9 -> 1 over 450 ms
/// easeOut. Under reduced motion it is a plain 200 ms fade.
class _AvatarIn extends StatefulWidget {
  const _AvatarIn({required this.child});

  final Widget child;

  @override
  State<_AvatarIn> createState() => _AvatarInState();
}

class _AvatarInState extends State<_AvatarIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) _c.duration = Motion.reducedFade;
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final a = CurvedAnimation(
      parent: _c,
      curve: reduced ? Curves.linear : AppCurves.easeOut,
    );
    return AnimatedBuilder(
      animation: a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: a.value,
        child: reduced
            ? child
            : Transform.scale(
                scale: 0.9 + 0.1 * a.value,
                alignment: Alignment.center,
                child: child,
              ),
      ),
    );
  }
}
