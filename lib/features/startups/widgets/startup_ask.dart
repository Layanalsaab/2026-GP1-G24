import 'package:flutter/material.dart';

import '../../../helpers/formatters.dart';
import '../../../models/startup.dart';
import '../../../models/startup_enums.dart';
import 'founder_ui.dart';

class StartupAsk {
  StartupAsk._();

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

  static String fundingDetail(Startup s) {
    final amount = s.fundingRequirement ?? 0;
    final raised = s.raisedInRound;
    return [
      if (amount > 0) 'Raising ${Formatters.sar(amount)}',
      if (raised != null && raised > 0)
        '${Formatters.sar(raised)} raised so far',
    ].join(' · ');
  }
}

/// One row of the Startup Ask.
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
                color: selected ? AppColors.mossText : AppColors.hint,
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
                color: selected ? AppColors.mossText : AppColors.hint,
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
          border: Border.all(color: AppColors.mossText.withValues(alpha: 0.5)),
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
