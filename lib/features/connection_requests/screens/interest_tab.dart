import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../startups/widgets/manage_card.dart';
import '../view_models/interest_view_model.dart';

/// Manage startup -> Interest (docs/05 D3): New / All chips and one card
/// listing the people who expressed interest. The round reply button marks the
/// person as seen and calls [onToast] with "Messaging opens in the full app".
class InterestTab extends StatelessWidget {
  const InterestTab({super.key, required this.vm, required this.onToast});

  final InterestViewModel vm;
  final void Function(String message) onToast;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final items = vm.visible;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppFilterChip(
                  label: FounderToolsStrings.filterLabel(
                    FounderToolsStrings.interestNew,
                    vm.newCount,
                  ),
                  selected: vm.onlyNew,
                  onTap: () => vm.select(onlyNew: true),
                ),
                AppFilterChip(
                  label: FounderToolsStrings.filterLabel(
                    FounderToolsStrings.interestAll,
                    vm.allCount,
                  ),
                  selected: !vm.onlyNew,
                  onTap: () => vm.select(onlyNew: false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ManageCard(
              padding: items.isEmpty
                  ? const EdgeInsets.all(16)
                  : const EdgeInsets.symmetric(horizontal: 16),
              child: items.isEmpty
                  ? Text(
                      vm.onlyNew
                          ? FounderToolsStrings.interestEmpty
                          : FounderToolsStrings.interestAllEmpty,
                      style: AppText.sans(
                        size: 14,
                        height: 20,
                        color: AppColors.grey,
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: i == items.length - 1
                                  ? null
                                  : const Border(
                                      bottom: BorderSide(
                                        color: AppColors.dividerSoft,
                                      ),
                                    ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TileAvatar(
                                  initials: appInitials(items[i].name),
                                  tone: i.isEven
                                      ? TileTone.moss
                                      : TileTone.gold,
                                  size: 38,
                                  fontSize: 13,
                                  round: true,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              items[i].name,
                                              style: AppText.sans(
                                                size: 15,
                                                weight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (items[i].isNew) ...[
                                            const SizedBox(width: 6),
                                            Semantics(
                                              label: 'New',
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.gold,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        _sub(
                                          items[i].roleLine,
                                          items[i].whenLabel,
                                        ),
                                        style: AppText.sans(
                                          size: 12.5,
                                          height: 17,
                                          color: AppColors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        items[i].message,
                                        style: AppText.sans(
                                          size: 13.5,
                                          height: 19,
                                          color: AppColors.paragraph,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Semantics(
                                  button: true,
                                  label:
                                      '${FounderToolsStrings.replyLabel} ${items[i].name}',
                                  excludeSemantics: true,
                                  child: Pressable(
                                    onTap: () {
                                      vm.markReplied(items[i]);
                                      onToast(
                                        FounderToolsStrings.messagingToast,
                                      );
                                    },
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: const BoxDecoration(
                                        color: AppColors.moss50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: AppIcon.filled(
                                          AppIcons.chat,
                                          size: 20,
                                          color: AppColors.moss600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  static String _sub(String role, String? when) =>
      when == null || when.isEmpty ? role : '$role · $when';
}
