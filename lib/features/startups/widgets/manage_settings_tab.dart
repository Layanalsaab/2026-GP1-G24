import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import 'founder_ui.dart';
import 'manage_card.dart';

/// Manage startup -> Settings (docs/05 D3): the "Public profile" switch card
/// and the red "Delete startup" card.
class ManageSettingsTab extends StatelessWidget {
  const ManageSettingsTab({
    super.key,
    required this.isPublic,
    required this.onVisibilityChanged,
    required this.onDelete,
  });

  final bool isPublic;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ManageCard(
          child: Row(
            children: [
              const _IconBox(
                icon: AppIcons.globe,
                fill: AppColors.moss50,
                color: AppColors.moss600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Texts(
                  title: FounderToolsStrings.publicProfile,
                  text: isPublic
                      ? FounderToolsStrings.publicProfileOn
                      : FounderToolsStrings.publicProfileOff,
                ),
              ),
              const SizedBox(width: 12),
              AppSwitch(
                value: isPublic,
                onChanged: onVisibilityChanged,
                semanticLabel: FounderToolsStrings.publicProfile,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: FounderToolsStrings.deleteStartup,
          excludeSemantics: true,
          child: Pressable(
            onTap: onDelete,
            child: const ManageCard(
              child: Row(
                children: [
                  _IconBox(
                    icon: AppIcons.trash,
                    fill: AppColors.errorFill,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _Texts(
                      title: FounderToolsStrings.deleteStartup,
                      text: FounderToolsStrings.deleteStartupText,
                      titleColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.fill, required this.color});

  final String icon;
  final Color fill;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(child: AppIcon.filled(icon, size: 20, color: color)),
  );
}

class _Texts extends StatelessWidget {
  const _Texts({required this.title, required this.text, this.titleColor});

  final String title;
  final String text;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppText.sans(
          size: 15,
          weight: FontWeight.w600,
          color: titleColor ?? AppColors.ink,
        ),
      ),
      Text(
        text,
        style: AppText.sans(size: 12.5, height: 17, color: AppColors.grey),
      ),
    ],
  );
}
