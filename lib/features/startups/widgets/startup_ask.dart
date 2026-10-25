import 'package:flutter/material.dart';

import '../../../helpers/formatters.dart';
import '../../../models/startup.dart';
import '../../../models/startup_enums.dart';
import 'founder_ui.dart';

/// What a startup asks for, read from what it looks for: Funding (an amount
/// and the lead-investor answer), Partnership and Support (mentorship,
/// advisors, marketing, tech development, talent...). Shared by the Manage
/// Details tab and the startup page so both say the same thing.
class StartupAsk {
  StartupAsk._();

  static bool funding(Startup s) => s.seeksFunding;

  /// Partnership is selected when its box was ticked or partner types exist.
  static bool partnership(Startup s) =>
      s.lookingFor.contains(LookingFor.partnership) ||
      s.partnerTypes.isNotEmpty;

  /// Support is selected when its box was ticked or support types exist.
  static bool supportSelected(Startup s) =>
      s.lookingFor.contains(LookingFor.support) || s.supportTypes.isNotEmpty;

  /// The partner types the founder picked ("Other" is the typed text).
  static List<String> partners(Startup s) => s.partnerTypes;

  /// The support types the founder picked ("Other" is the typed text).
  static List<String> support(Startup s) => s.supportTypes;

  /// "Raising SAR 500,000 · SAR 200,000 raised so far · Looking for a lead
  /// investor" (or "· No lead investor needed"), full amounts with commas.
  static String fundingDetail(Startup s) {
    final amount = s.fundingRequirement ?? 0;
    final raised = s.raisedInRound;
    final lead = s.wantsLeadInvestor;
    return [
      if (amount > 0) 'Raising ${Formatters.sar(amount)}',
      if (raised != null && raised > 0)
        '${Formatters.sar(raised)} raised so far',
      if (lead != null)
        lead ? 'Looking for a lead investor' : 'No lead investor needed',
    ].join(' · ');
  }
}

/// One row of the Startup Ask. Selected = solid border, moss-50 fill, green
/// icon tile and (when [showStatus]) "Selected"; not selected = dashed grey
/// border and "Not selected" / "Off".
class AskRow extends StatelessWidget {
  const AskRow({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.detail,
    this.showStatus = true,
  });

  final String icon;
  final String title;
  final bool selected;
  final String detail;

  /// False hides the "Selected" / "Not selected" word on the right (the
  /// startup page lists only the selected rows).
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: selected ? AppColors.moss100 : AppColors.mutedFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: AppIcon.filled(
                icon,
                size: 18,
                color: selected ? AppColors.moss600 : AppColors.hint,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.sans(
                    size: 16,
                    weight: FontWeight.w600,
                    color: selected ? AppColors.ink : AppColors.grey,
                  ),
                ),
                Text(
                  detail.isEmpty ? 'Selected' : detail,
                  style: AppText.sans(
                    size: 14,
                    height: 20,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (showStatus)
            Text(
              selected ? 'Selected' : 'Not selected',
              style: AppText.sans(
                size: 13,
                weight: FontWeight.w600,
                color: selected ? AppColors.moss600 : AppColors.hint,
              ),
            ),
        ],
      ),
    );
    if (selected) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.moss50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.moss600.withValues(alpha: 0.5)),
        ),
        child: content,
      );
    }
    return CustomPaint(
      painter: DashedBorderPainter(color: AppColors.borderStrong, radius: 14),
      child: content,
    );
  }
}
