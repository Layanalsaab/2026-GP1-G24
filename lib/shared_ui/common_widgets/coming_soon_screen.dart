import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_constants/startup_strings.dart';
import '../../navigation/placeholder_features.dart';
import '../theme/app_theme.dart';
import 'green_top_bar.dart';

/// Full page for a feature that isn't built yet, with a back button.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.feature});

  final PlaceholderFeature feature;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            GreenTopBar(
              title: feature.label,
              leading: const TopBarBackButton(),
            ),
            Expanded(child: ComingSoonView(feature: feature)),
          ],
        ),
      ),
    );
  }
}

/// The "coming in a later sprint" content, without a page frame, so it can
/// also fill a tab.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key, required this.feature});

  final PlaceholderFeature feature;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soft double ring around the feature icon.
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.gold100,
                shape: BoxShape.circle,
              ),
              child: Container(
                width: AppSizes.emptyStateIcon,
                height: AppSizes.emptyStateIcon,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: Icon(
                  feature.icon,
                  size: AppSizes.iconLg,
                  color: AppColors.moss600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              feature.label,
              style: AppText.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.moss100,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                StartupStrings.comingSoon,
                style: AppText.badge.copyWith(color: AppColors.moss600),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              StartupStrings.comingSoonBody,
              style: AppText.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
