import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../../startups/screens/my_startups_screen.dart';

/// Figma "V2 · 35 · Services — Founder" and "V2 · 36 · Services — Investor":
/// the Services tab, a grid of tools.
///
/// A founder has five tiles; of these only My Startups is built. An investor
/// has two (Associations and Calculator), both design only. Tiles that aren't
/// built are shown but do nothing when tapped.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key, this.role = AccountRole.founder});

  final AccountRole role;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      if (role == AccountRole.founder)
        _Tile(
          icon: Icons.business_center_outlined,
          label: StartupStrings.tileMyStartups,
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const MyStartupsScreen())),
        ),
      // Not built yet: shown, but tapping them does nothing.
      const _Tile(
        icon: Icons.groups_outlined,
        label: StartupStrings.tileAssociations,
      ),
      const _Tile(
        icon: Icons.trending_up_rounded,
        label: StartupStrings.tileCalculator,
      ),
      if (role == AccountRole.founder) ...[
        const _Tile(
          icon: Icons.auto_awesome_outlined,
          label: StartupStrings.tileAskGemini,
        ),
        const _Tile(
          icon: Icons.space_dashboard_outlined,
          label: StartupStrings.tileDashboard,
        ),
      ],
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
  const _Tile({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;

  /// Null for a tile that isn't built yet: it then ignores taps completely.
  final VoidCallback? onTap;

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
