import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../startups/widgets/manage_card.dart';

/// Manage startup -> EOI (front end only).
class InterestTab extends StatelessWidget {
  const InterestTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ManageTabHeader(
          title: FounderToolsStrings.interestTitle,
          subtitle: FounderToolsStrings.interestSubtitle,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppFilterChip(
              label: FounderToolsStrings.filterLabel(
                FounderToolsStrings.interestNew,
                0,
              ),
              selected: true,
              onTap: () {},
            ),
            AppFilterChip(
              label: FounderToolsStrings.filterLabel(
                FounderToolsStrings.interestAll,
                0,
              ),
              selected: false,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        ManageCard(
          padding: const EdgeInsets.all(16),
          child: Text(
            FounderToolsStrings.interestEmpty,
            style: AppText.sans(size: 14, height: 20, color: AppColors.grey),
          ),
        ),
      ],
    );
  }
}
