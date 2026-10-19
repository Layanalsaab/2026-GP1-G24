import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/discovery_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../engagement_analytics/screens/activity_card.dart';
import '../../engagement_analytics/view_models/activity_view_model.dart';
import 'founder_ui.dart';
import 'manage_card.dart';

/// Manage startup -> Overview (docs/05 D3): Edit startup + Preview buttons, the
/// Activity card, Associated investors and the Valuation calculator link.
class ManageOverviewTab extends StatelessWidget {
  const ManageOverviewTab({
    super.key,
    required this.startupId,
    required this.activity,
    required this.onEdit,
    required this.onPreview,
    required this.onCalculator,
  });

  final String startupId;
  final ActivityViewModel activity;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onCalculator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: FounderToolsStrings.editStartup,
                icon: AppIcons.edit,
                onPressed: onEdit,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: FounderToolsStrings.preview,
                icon: AppIcons.eye,
                variant: AppButtonVariant.outline,
                onPressed: onPreview,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ActivityCard(vm: activity),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: RequestRepository.instance.inboxChanges,
          builder: (context, _) {
            final investors = DiscoveryRepository.instance.associatedInvestors(
              startupId,
            );
            return ManageCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Semantics(
                          header: true,
                          child: Text(
                            FounderToolsStrings.associatedTitle,
                            style: AppText.sans(
                              size: 17,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '${investors.length}',
                        style: AppText.sans(size: 13, color: AppColors.grey),
                      ),
                    ],
                  ),
                  if (investors.isEmpty)
                    const ManageEmptyText(FounderToolsStrings.associatedEmpty)
                  else
                    for (final i in investors)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            TileAvatar(
                              initials: i.initials,
                              size: 38,
                              fontSize: 13,
                              round: true,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    i.name,
                                    style: AppText.sans(
                                      size: 15,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${i.title} · ${i.city}',
                                    style: AppText.sans(
                                      size: 12.5,
                                      height: 17,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const AppPill(
                              label: FounderToolsStrings.shownOnProfile,
                              height: 28,
                              fontSize: 13,
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: FounderToolsStrings.calcCardTitle,
          excludeSemantics: true,
          child: ManageCard(
            onTap: onCalculator,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.tagGoldFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: AppIcon.filled(
                      AppIcons.calc,
                      size: 20,
                      color: AppColors.tagGoldText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FounderToolsStrings.calcCardTitle,
                        style: AppText.sans(size: 15, weight: FontWeight.w600),
                      ),
                      Text(
                        FounderToolsStrings.calcCardText,
                        style: AppText.sans(
                          size: 12.5,
                          height: 17,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const AppIcon.filled(
                  AppIcons.chevRight,
                  size: 22,
                  color: AppColors.hint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
