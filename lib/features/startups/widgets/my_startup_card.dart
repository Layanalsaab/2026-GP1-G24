import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../helpers/formatters.dart';
import '../../../models/startup.dart';
import '../../../models/startup_enums.dart';
import 'founder_ui.dart';
import 'hover_lift_card.dart';

/// The card line under the Public / Private pill: "Raising SAR 500,000" when
/// the startup looks for funding and has an amount, else "Looking for
/// partnership" (the first thing it looks for).
String startupNeedsLine(Startup s) {
  final amount = s.fundingRequirement;
  if (s.seeksFunding && amount != null && amount > 0) {
    return FounderToolsStrings.raising(Formatters.sar(amount));
  }
  if (s.lookingFor.isEmpty) return '';
  final first = LookingFor.values.firstWhere((l) => s.lookingFor.contains(l));
  return FounderToolsStrings.lookingForLine(s.lookingForLabelOf(first));
}

/// A My Startups list card (prototype `.scard`): gold tile 48, name 18/700,
/// tagline, sector / stage / city pills, and a footer with the visibility
/// pill, the needs line and "Manage ›". Tap opens Manage.
class MyStartupCard extends StatelessWidget {
  const MyStartupCard({super.key, required this.startup, required this.onTap});

  final Startup startup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = startup;
    final needs = startupNeedsLine(s);
    return Semantics(
      button: true,
      label: '${s.name}, ${FounderToolsStrings.manage}',
      excludeSemantics: true,
      child: HoverLiftCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TileAvatar(
                  initials: s.initials,
                  tone: TileTone.gold,
                  size: 48,
                  radius: 14,
                  fontSize: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(
                          size: 18,
                          weight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (s.summary.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          s.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(
                            size: 13,
                            height: 18,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppPill(label: s.sectorLabel, height: 26, fontSize: 12),
                AppPill(label: s.stageLabel, height: 26, fontSize: 12),
                AppPill(label: s.location.label, height: 26, fontSize: 12),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.dividerSoft)),
              ),
              child: Row(
                children: [
                  AppPill(
                    label: s.isPublic
                        ? FounderToolsStrings.publicPill
                        : FounderToolsStrings.privatePill,
                    tone: s.isPublic ? AppPillTone.moss : AppPillTone.grey,
                    icon: s.isPublic ? AppIcons.globe : AppIcons.lock,
                    height: 26,
                    fontSize: 12,
                    weight: FontWeight.w600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      needs,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: AppColors.tagGoldText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    FounderToolsStrings.manage,
                    style: AppText.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: AppColors.moss600,
                    ),
                  ),
                  const AppIcon.outline(
                    AppIcons.rowChevron,
                    size: 18,
                    color: AppColors.moss600,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
