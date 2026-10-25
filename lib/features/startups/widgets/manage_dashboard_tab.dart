import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/discovery_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../helpers/formatters.dart';
import '../../../models/funding_round.dart';
import '../../../models/startup.dart';
import '../../engagement_analytics/screens/activity_card.dart';
import '../../engagement_analytics/view_models/activity_view_model.dart';
import '../../profiles/screens/investor_profile_screen.dart';
import 'founder_ui.dart';
import 'manage_card.dart';
import 'stat_tile.dart';
import 'hover_lift_card.dart';

/// Manage startup -> Dashboard (top to bottom): the Raising and Valuation
/// tiles, the Activity card, the Valuation calculator link and the Associated
/// investors card. (Preview, Visibility, Team, quick actions and "Needs your
/// attention" are not here any more.)
class ManageDashboardTab extends StatelessWidget {
  const ManageDashboardTab({
    super.key,
    required this.startup,
    required this.openRound,
    required this.activity,
    required this.onRaising,
    required this.onValuation,
    required this.onCalculator,
    this.emptyInvestorsText = FounderToolsStrings.associatedEmpty,
  });

  final Startup startup;

  /// The open funding round (from the Rounds tab), or null.
  final FundingRound? openRound;
  final ActivityViewModel activity;

  /// Tap on the Raising tile (opens the Rounds tab).
  final VoidCallback onRaising;

  /// Tap on the Valuation tile (opens the Finance and Growth section).
  final VoidCallback onValuation;
  final VoidCallback onCalculator;

  /// Shown when there is no associated investor.
  final String emptyInvestorsText;

  @override
  Widget build(BuildContext context) {
    final round = openRound;
    final open = round != null;
    final valuation = startup.valuation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatTile(
                  dark: open,
                  label: FounderToolsStrings.raisingLabel,
                  value: open
                      ? Formatters.sarShort(round.amount)
                      : FounderToolsStrings.notRaisingValue,
                  sub: open
                      ? 'Round ${round.number} · Open'
                      : FounderToolsStrings.noOpenRound,
                  onTap: onRaising,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  dark: false,
                  label: FounderToolsStrings.valuationTile,
                  value: valuation == null
                      ? '—'
                      : Formatters.sarShort(valuation),
                  sub: FounderToolsStrings.valuationCurrent,
                  onTap: onValuation,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ActivityCard(vm: activity),
        const SizedBox(height: 12),
        _CalculatorCard(onTap: onCalculator),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: RequestRepository.instance.inboxChanges,
          builder: (context, _) {
            final investors = DiscoveryRepository.instance.associatedInvestors(
              startup.id,
            );
            return ManageCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      FounderToolsStrings.associatedTitle,
                      style: AppText.sans(
                        size: 19,
                        height: 26,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (investors.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        emptyInvestorsText,
                        style: AppText.sans(
                          size: 14,
                          height: 20,
                          color: AppColors.grey,
                        ),
                      ),
                    )
                  else
                    for (final i in investors)
                      Semantics(
                        button: true,
                        label: i.name,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => InvestorProfileScreen.open(context, i),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                TileAvatar(
                                  initials: i.initials,
                                  size: 40,
                                  fontSize: 14,
                                  round: true,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        i.name,
                                        style: AppText.sans(
                                          size: 16.5,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${i.title} · ${i.city}',
                                        style: AppText.sans(
                                          size: 14,
                                          height: 20,
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
                      ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Valuation calculator link: white, 1 px border, radius 18, padding 14 / 16,
/// a 40 px gold-tint tile with the calculator icon, just the title (no
/// sub-text) and a chevron.
class _CalculatorCard extends StatelessWidget {
  const _CalculatorCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: FounderToolsStrings.calcCardTitle,
      excludeSemantics: true,
      child: HoverLiftCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        radius: 18,
        baseShadow: AppShadow.card,
        border: Border.all(color: AppColors.cardBorder),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
              child: Text(
                FounderToolsStrings.calcCardTitle,
                style: AppText.sans(size: 16.5, weight: FontWeight.w600),
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
    );
  }
}
