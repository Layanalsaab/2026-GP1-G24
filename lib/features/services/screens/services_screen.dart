import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../navigation/placeholder_features.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../../startups/screens/my_startups_screen.dart';

/// Figma "V2 · 35 · Services": the founder's Services tab, a grid of tools.
/// My Startups is built; the others open a "Coming in a later sprint" page.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Tile(
        icon: Icons.business_center_outlined,
        label: StartupStrings.tileMyStartups,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const MyStartupsScreen())),
      ),
      _Tile.placeholder(
        context,
        Icons.groups_outlined,
        StartupStrings.tileAssociations,
        PlaceholderFeature.investmentAssociations,
      ),
      _Tile.placeholder(
        context,
        Icons.trending_up_rounded,
        StartupStrings.tileCalculator,
        PlaceholderFeature.fundraisingCalculator,
      ),
      _Tile.placeholder(
        context,
        Icons.auto_awesome_outlined,
        StartupStrings.tileAskGemini,
        PlaceholderFeature.askGemini,
      ),
      _Tile.placeholder(
        context,
        Icons.space_dashboard_outlined,
        StartupStrings.tileDashboard,
        PlaceholderFeature.activityDashboard,
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            const GreenTopBar(title: StartupStrings.servicesTitle),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(AppSpacing.lg),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.25,
                children: tiles,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  /// A tile for a feature that isn't built yet.
  _Tile.placeholder(
    BuildContext context,
    this.icon,
    this.label,
    PlaceholderFeature feature,
  ) : onTap = (() => feature.open(context));

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(AppRadius.md);
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
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: shape,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: AppSizes.tileIconBox,
                  height: AppSizes.tileIconBox,
                  decoration: BoxDecoration(
                    color: AppColors.moss100,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    icon,
                    size: AppSizes.icon,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    label,
                    style: AppText.itemTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
