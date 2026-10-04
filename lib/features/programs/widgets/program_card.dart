import 'package:flutter/material.dart';

import '../../../models/program.dart';
import '../../../shared_ui/common_widgets/listing_card_parts.dart';
import '../../../shared_ui/theme/app_theme.dart';

/// A program in the Programs list (Figma "V2 · 16 · Programs"): a letter
/// logo, the name, and "Type  City". Tapping works only when [onTap] is given.
class ProgramCard extends StatelessWidget {
  const ProgramCard({super.key, required this.program, this.onTap});

  final Program program;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(14);
    return Material(
      color: AppColors.surface,
      borderRadius: shape,
      child: InkWell(
        borderRadius: shape,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              InitialsBadge(
                initials: program.initial,
                size: 44,
                radius: 10,
                fontSize: 16,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.name,
                      style: AppText.itemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Text(program.type.label, style: AppText.caption),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            program.city,
                            style: AppText.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
