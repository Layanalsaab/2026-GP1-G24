import 'package:flutter/material.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../helpers/formatters.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/theme/app_theme.dart';
import 'startup_logo.dart';
import 'visibility_badge.dart';

/// A founder's own startup in the My Startups list: logo, name, sector,
/// stage and a Public/Private badge. Tapping opens Edit.
class MyStartupCard extends StatelessWidget {
  const MyStartupCard({super.key, required this.startup, required this.onTap});

  final Startup startup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(AppRadius.lg);
    final editedAt = startup.updatedAt;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: shape,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StartupLogo(
                      initial: startup.initial,
                      url: startup.logoUrl,
                      size: AppSizes.cardLogo,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _Heading(startup: startup)),
                    const SizedBox(width: AppSpacing.sm),
                    VisibilityBadge(isPublic: startup.isPublic),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _MetaChip(
                      icon: Icons.category_outlined,
                      label: startup.sector.label,
                    ),
                    _MetaChip(
                      icon: Icons.trending_up_rounded,
                      label: startup.stage.label,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        editedAt == null
                            ? ''
                            : StartupStrings.editedAgo(
                                Formatters.relativeTime(editedAt),
                              ),
                        style: AppText.caption,
                      ),
                    ),
                    Text(StartupStrings.editTitle, style: AppText.link),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: AppSizes.icon,
                      color: AppColors.moss600,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.startup});

  final Startup startup;

  @override
  Widget build(BuildContext context) {
    final tagline = startup.tagline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          startup.name,
          style: AppText.cardTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (tagline != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            tagline,
            style: AppText.bodyMuted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xxs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.moss50,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.moss100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.moss600),
          const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
          Text(label, style: AppText.badge.copyWith(color: AppColors.green)),
        ],
      ),
    );
  }
}
