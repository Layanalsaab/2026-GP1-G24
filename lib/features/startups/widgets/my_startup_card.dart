import 'package:flutter/material.dart';

import '../../../models/startup.dart';
import '../../../shared_ui/theme/app_theme.dart';
import 'startup_logo.dart';
import 'visibility_badge.dart';

/// A founder's own startup in the My Startups list (Figma "V2 · 24"):
/// logo or initials, name, "Sector · Stage", and a Public/Private badge.
/// Tapping opens Edit.
class MyStartupCard extends StatelessWidget {
  const MyStartupCard({super.key, required this.startup, required this.onTap});

  final Startup startup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(AppRadius.md);
    return Material(
      color: AppColors.surface,
      borderRadius: shape,
      child: InkWell(
        borderRadius: shape,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              StartupLogo(
                initials: startup.initials,
                url: startup.logoUrl,
                size: AppSizes.listLogo,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startup.name,
                      style: AppText.itemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${startup.sector.label} · ${startup.stage.label}',
                      style: AppText.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              VisibilityBadge(isPublic: startup.isPublic),
            ],
          ),
        ),
      ),
    );
  }
}
