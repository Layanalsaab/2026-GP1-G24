import 'package:flutter/material.dart';

import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';

/// The calculated runway under the Monthly burn rate field. Deliberately
/// quiet so it reads as worked out, not typed: indented, a hairline on its
/// left, a tiny calculator, the word "Runway" and the value. No box, no
/// colour.
class RunwayLine extends StatelessWidget {
  const RunwayLine({super.key, required this.value});

  /// "About 6 months", "Cash-flow positive" or "No money left".
  final String value;

  static const _iconGrey = Color(0xFFA3A7A2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 12),
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.border, width: 1.5)),
        ),
        child: Semantics(
          label: 'Runway: $value',
          excludeSemantics: true,
          child: Row(
            children: [
              const AppIcon.filled(AppIcons.calc, size: 12, color: _iconGrey),
              const SizedBox(width: 6),
              Text(
                'Runway:',
                style: AppText.sans(size: 12.5, color: AppColors.hint),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: AppText.sans(
                    size: 12.5,
                    color: AppColors.grey,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
