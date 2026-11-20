import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// A tappable card with a checkbox on the left and a title (and an optional description) next to it.
class CheckboxCard extends StatelessWidget {
  const CheckboxCard({
    super.key,
    required this.title,
    required this.checked,
    required this.onChanged,
    this.description,
    this.compact = false,
  });

  final bool compact;

  final String title;
  final String? description;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      label: description == null ? title : '$title. $description',
      excludeSemantics: true,
      onTap: () => onChanged(!checked),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!checked),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: checked ? AppColors.moss50 : AppColors.surface,
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            border: Border.all(
              color: checked ? AppColors.mossText : AppColors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: description == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: checked ? AppColors.moss600 : AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: checked ? AppColors.mossText : AppColors.hint,
                    width: 2,
                  ),
                ),
                child: checked
                    ? const Center(
                        child: AppIcon.outline(
                          AppIcons.checkStroke,
                          size: 14,
                          stroke: 2.4,
                          color: AppColors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.sans(
                        size: compact ? 16 : 15,
                        weight: FontWeight.w600,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: AppText.sans(
                          size: 13,
                          color: AppColors.grey,
                          height: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
