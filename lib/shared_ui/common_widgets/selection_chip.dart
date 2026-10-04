import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'svg_asset.dart';

/// Pill-shaped option chip. Selected chips get a moss fill and a check mark.
class SelectionChip extends StatelessWidget {
  const SelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.only(left: selected ? 10 : 14, right: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.moss100 : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.moss600 : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              svgIcon('check.svg', size: 16),
              const SizedBox(width: 6),
            ],
            // Flexible + ellipsis: a long label on a narrow screen (or with
            // large system text) shrinks instead of overflowing.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(
                  size: 14,
                  color: selected ? AppColors.green : AppColors.ink,
                  weight: FontWeight.w500,
                  height: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
