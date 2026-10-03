import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/theme/app_theme.dart';

/// Guest explore page for startup seekers, who never create an account.
/// Placeholder until the Seeker hub/explore (Figma "11 · Explore — Seeker") is built.
class SeekerExploreScreen extends StatelessWidget {
  const SeekerExploreScreen({super.key});

  @override
  Widget build(BuildContext context) => FormPageScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.seekerExploreTitle,
              style: AppText.serif(size: 22, color: AppColors.ink, height: 28),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.seekerNote,
              style: AppText.sans(size: 14, color: AppColors.grey, height: 20),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.comingSoon,
              style: AppText.sans(size: 14, color: AppColors.grey, height: 20),
            ),
          ],
        ),
      );
}
