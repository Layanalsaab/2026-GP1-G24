import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../startups/widgets/manage_card.dart';

/// The investment requests of an open round (front end only).
class RequestsTab extends StatelessWidget {
  const RequestsTab({super.key});

  static const _filters = [
    'All',
    FounderToolsStrings.pending,
    FounderToolsStrings.accepted,
    FounderToolsStrings.declined,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in _filters)
              AppFilterChip(
                label: FounderToolsStrings.filterLabel(label, 0),
                selected: label == FounderToolsStrings.pending,
                onTap: () {},
              ),
          ],
        ),
        const SizedBox(height: 12),
        ManageCard(
          child: Text(
            FounderToolsStrings.requestsEmpty('pending'),
            style: AppText.sans(size: 16, height: 24, color: AppColors.grey),
          ),
        ),
      ],
    );
  }
}
