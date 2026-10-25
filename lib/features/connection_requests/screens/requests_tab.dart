import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/connection_request.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../startups/widgets/manage_card.dart';
import '../view_models/requests_view_model.dart';

/// Manage startup -> Requests (docs/05 D3): Pending / Accepted / Declined
/// chips and one card per investor request. [onCheck] opens the valuation
/// calculator with the offer; [onToast] shows the toasts.
class RequestsTab extends StatelessWidget {
  const RequestsTab({
    super.key,
    required this.vm,
    required this.onCheck,
    required this.onToast,
    this.canAct = true,
  });

  final RequestsViewModel vm;

  /// False hides Accept / Decline (a team member only reads).
  final bool canAct;
  final void Function(ConnectionRequest request) onCheck;
  final void Function(String message) onToast;

  static const _filters = [
    (RequestStatus.pending, FounderToolsStrings.pending),
    (RequestStatus.accepted, FounderToolsStrings.accepted),
    (RequestStatus.declined, FounderToolsStrings.declined),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final rows = vm.rows;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (status, label) in _filters)
                  AppFilterChip(
                    label: FounderToolsStrings.filterLabel(
                      label,
                      vm.count(status),
                    ),
                    selected: vm.filter == status,
                    onTap: () => vm.select(status),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              ManageCard(
                child: Text(
                  FounderToolsStrings.requestsEmpty(vm.filter.value),
                  style: AppText.sans(
                    size: 16,
                    height: 24,
                    color: AppColors.grey,
                  ),
                ),
              )
            else
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _RequestCard(
                  row: rows[i],
                  canAct: canAct,
                  onCheck: () => onCheck(rows[i].request),
                  onAccept: () {
                    if (!canAct) return;
                    final name = vm.accept(rows[i]);
                    onToast(FounderToolsStrings.acceptedToast(name));
                  },
                  onDecline: () {
                    if (!canAct) return;
                    vm.decline(rows[i]);
                    onToast(FounderToolsStrings.declinedToast);
                  },
                ),
              ],
          ],
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.row,
    required this.onCheck,
    required this.onAccept,
    required this.onDecline,
    required this.canAct,
  });

  final bool canAct;
  final RequestRow row;
  final VoidCallback onCheck;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final r = row.request;
    return ManageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TileAvatar(
                initials: row.initials,
                tone: TileTone.gold,
                size: 42,
                fontSize: 14,
                round: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      style: AppText.sans(size: 16.5, weight: FontWeight.w600),
                    ),
                    Text(
                      row.sub,
                      style: AppText.sans(
                        size: 14,
                        height: 20,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '“${r.message}”',
            style: AppText.sans(
              size: 16,
              height: 24,
              color: AppColors.paragraph,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FounderToolsStrings.offer,
                  style: AppText.sans(size: 14, color: AppColors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  r.offerLabel,
                  style: AppText.sans(size: 17, weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Semantics(
                  button: true,
                  label: FounderToolsStrings.checkInCalculator,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onCheck,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon.filled(
                          AppIcons.calc,
                          size: 15,
                          color: AppColors.moss600,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          FounderToolsStrings.checkInCalculator,
                          style: AppText.sans(
                            size: 14,
                            weight: FontWeight.w600,
                            color: AppColors.moss600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (r.status != RequestStatus.pending || canAct)
            const SizedBox(height: 12),
          switch (r.status) {
            RequestStatus.pending when !canAct => const SizedBox.shrink(),
            RequestStatus.pending => Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: FounderToolsStrings.decline,
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.small,
                    onPressed: onDecline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: FounderToolsStrings.accept,
                    size: AppButtonSize.small,
                    onPressed: onAccept,
                  ),
                ),
              ],
            ),
            RequestStatus.accepted => const Align(
              alignment: Alignment.centerLeft,
              child: AppPill(
                label: FounderToolsStrings.acceptedPill,
                icon: AppIcons.check,
                weight: FontWeight.w600,
              ),
            ),
            RequestStatus.declined => const Align(
              alignment: Alignment.centerLeft,
              child: AppPill(
                label: FounderToolsStrings.declinedPill,
                tone: AppPillTone.grey,
                weight: FontWeight.w600,
              ),
            ),
          },
        ],
      ),
    );
  }
}
