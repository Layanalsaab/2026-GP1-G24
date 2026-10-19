import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/startup.dart';
import 'founder_ui.dart';

/// The saved draft at the top of My Startups: a gold "Draft" pill, the name
/// typed so far (or "Untitled startup"), "Continue editing", and a trash
/// button that discards it. Tap continues the form where it stopped.
class DraftCard extends StatelessWidget {
  const DraftCard({
    super.key,
    required this.draft,
    required this.onTap,
    required this.onDiscard,
  });

  final Map<String, Object?> draft;
  final VoidCallback onTap;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final name = ((draft['name'] as String?) ?? '').trim();
    final step = (((draft['step'] as num?)?.toInt() ?? 0) + 1).clamp(1, 4);
    return Pressable(
      onTap: onTap,
      child: Semantics(
        button: true,
        label:
            '${FounderToolsStrings.draftBadge}, '
            '${name.isEmpty ? FounderToolsStrings.untitledStartup : name}, '
            '${FounderToolsStrings.draftContinue}',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.homeCard),
            boxShadow: AppShadow.listCard,
            border: Border.all(color: AppColors.gold.withValues(alpha: .55)),
          ),
          child: Row(
            children: [
              TileAvatar(
                initials: name.isEmpty ? '?' : Startup.initialsOf(name),
                tone: TileTone.gold,
                size: 48,
                radius: 14,
                fontSize: 16,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tagGoldFill,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            FounderToolsStrings.draftBadge,
                            style: AppText.sans(
                              size: 11.5,
                              weight: FontWeight.w700,
                              color: AppColors.gold700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Step $step of 4',
                          style: AppText.sans(size: 12, color: AppColors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name.isEmpty ? FounderToolsStrings.untitledStartup : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(size: 17, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      FounderToolsStrings.draftContinue,
                      style: AppText.sans(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: AppColors.moss600,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: FounderToolsStrings.discardDraftTitle,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDiscard,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: AppIcon.filled(
                        AppIcons.trash,
                        size: 20,
                        color: AppColors.grey,
                      ),
                    ),
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
