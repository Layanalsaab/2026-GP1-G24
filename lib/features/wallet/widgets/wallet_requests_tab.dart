import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../app_constants/wallet_strings.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../startups/widgets/manage_card.dart';

/// Wallet -> Requests (front end only).
class WalletRequestsTab extends StatelessWidget {
  const WalletRequestsTab({super.key});

  static const _filters = ['All', 'Pending', 'Accepted', 'Declined'];

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
                selected: label == 'All',
                onTap: () {},
              ),
          ],
        ),
        const SizedBox(height: 12),
        ManageCard(
          child: Text(
            WalletStrings.noRequests,
            style: AppText.sans(size: 16, height: 24, color: AppColors.grey),
          ),
        ),
      ],
    );
  }
}
