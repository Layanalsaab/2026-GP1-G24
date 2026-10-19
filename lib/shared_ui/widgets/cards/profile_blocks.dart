import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import '../lists/press_surface.dart';

/// Colour of the 34 px icon box of a [ProfileCard].
enum ProfileIconTone { moss, gold, red }

/// Startup-profile card (prototype `.card.pcard`): white, border `#EBE7DF`,
/// radius 20, padding 16, gap 10. Header = 34 px icon box (radius 10) with a
/// filled 18 px [icon] path + title 16/700; [child] below.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.tone = ProfileIconTone.moss,
  });

  final String icon;
  final String title;
  final Widget child;
  final ProfileIconTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      ProfileIconTone.moss => (AppColors.moss100, AppColors.moss600),
      ProfileIconTone.gold => (AppColors.tagGoldFill, AppColors.tagGoldText),
      ProfileIconTone.red => (AppColors.errorFill, AppColors.error),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: AppIcon.filled(icon, size: 18, color: fg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppText.sans(size: 16, weight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Paragraph text used inside profile cards (14.5/22 `#3E4A41`).
class ProfileText extends StatelessWidget {
  const ProfileText(this.text, {super.key, this.muted = false});

  final String text;

  /// Grey variant used for empty hints ("No startups yet.").
  final bool muted;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: muted
        ? AppText.paragraph.copyWith(color: AppColors.metaText)
        : AppText.paragraph,
  );
}

/// White section of the own / investor profile (prototype `.ps`): radius 18,
/// padding 16, home-card shadow. Header = title 16/700 (ls -0.1) and an
/// optional right action link ([actionLabel], e.g. "+ Add", 13.5/600 moss).
/// Rises in unless [rise] is false; use [delay] to stagger.
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    this.rise = true,
    this.delay = Duration.zero,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool rise;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final section = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadow.homeCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: AppText.sectionTitle),
                ),
              ),
              if (actionLabel != null)
                Semantics(
                  button: true,
                  label: actionLabel,
                  excludeSemantics: true,
                  onTap: onAction,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onAction,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        actionLabel!,
                        style: AppText.sans(
                          size: 13.5,
                          color: AppColors.moss600,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
    if (!rise) return section;
    return Rise(delay: delay, child: section);
  }
}

/// A label/value row (prototype `.crow`): optional 20 px [icon] (grey),
/// label 12 `#8C918D` above value 15/600; padding 10 0 with a `#F0EDE6`
/// divider above when [showDivider].
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.showDivider = false,
  });

  final String label;
  final String value;

  /// Filled [AppIcons] path.
  final String? icon;
  final bool showDivider;

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
          if (icon != null) ...[
            AppIcon.filled(icon!, size: 20, color: AppColors.metaText),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppText.sans(size: 12, color: AppColors.hint),
                ),
                Text(
                  value,
                  style: AppText.sans(size: 15, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-column grid of cream cells (prototype `.pkv`): radius 12, padding
/// 10 12, label 12 grey over value 16/700 tabular; gap 8.
class KeyValueGrid extends StatelessWidget {
  const KeyValueGrid({super.key, required this.items});

  /// (label, value) pairs.
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, value) in items)
              Container(
                width: w,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppText.sans(size: 12, color: AppColors.grey),
                    ),
                    Text(
                      value,
                      style: AppText.sans(
                        size: 16,
                        weight: FontWeight.w700,
                        tabular: true,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A tappable list row (prototype `.srow` / `.prow`): [leading] avatar,
/// title + subtitle and a chevron. Default style is the own-profile row
/// (title 15/700, subtitle 13 grey, 18 px stroke chevron, padding 6 0,
/// `#F0EDE6` divider above when [showDivider]). [ListRow.card] is the
/// startup-profile "Associated investors" row (title 15/600, subtitle 12.5,
/// 22 px filled chevron, padding 8 0).
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.showDivider = false,
    this.trailing,
    this.showChevron = true,
  }) : _card = false;

  const ListRow.card({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.showDivider = false,
    this.trailing,
    this.showChevron = true,
  }) : _card = true;

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showDivider;

  /// Replaces the chevron (e.g. a pill).
  final Widget? trailing;
  final bool showChevron;
  final bool _card;

  @override
  Widget build(BuildContext context) {
    final chevron = _card
        ? const AppIcon.filled(
            AppIcons.chevRight,
            size: 22,
            color: AppColors.hint,
          )
        : const AppIcon.outline(
            AppIcons.rowChevron,
            size: 18,
            stroke: 2,
            color: AppColors.hint,
          );
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(top: BorderSide(color: AppColors.rowSeparator))
            : null,
      ),
      child: PressSurface(
        onTap: onTap,
        pressedColor: const Color(0xFFF7F5F0),
        semanticLabel: subtitle == null ? title : '$title, $subtitle',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: _card ? 8 : 6),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 15,
                        weight: _card ? FontWeight.w600 : FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(
                          size: _card ? 12.5 : 13,
                          color: _card ? AppColors.grey : AppColors.metaText,
                          height: _card ? 17 : 18,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (trailing == null && showChevron && onTap != null) chevron,
            ],
          ),
        ),
      ),
    );
  }
}

/// The delta pill (prototype `.dl`): `#E3F3E8` fill, `#1F7A42` 11/700 text,
/// padding 2 7, a trend icon 11 px before the text, e.g. "+18%".
class StatDelta extends StatelessWidget {
  const StatDelta(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.deltaFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon.filled(
            AppIcons.trend,
            size: 11,
            color: AppColors.deltaText,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: AppText.sans(
              size: 11,
              color: AppColors.deltaText,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
