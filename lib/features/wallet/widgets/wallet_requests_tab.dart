import 'package:flutter/material.dart';

import '../../../app_constants/wallet_strings.dart';
import '../../../helpers/formatters.dart';
import '../../../models/investment_ticket.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../startups/widgets/manage_card.dart';
import '../view_models/wallet_view_model.dart';
import 'ticket_detail.dart' show RequestStatusPill;

/// Investment Wallet -> Requests: the requests the investor sent through
/// their tickets, with the All / Pending / Accepted / Declined filters.
///
/// A card is NOT tappable (nothing opens). A Pending request has "Withdraw".
class WalletRequestsTab extends StatelessWidget {
  const WalletRequestsTab({super.key, required this.vm});

  final WalletViewModel vm;

  Future<void> _withdraw(BuildContext context, TicketRequest r) async {
    final go = await showDiscardDialog(
      context,
      title: WalletStrings.withdrawTitle,
      message: WalletStrings.withdrawMessage(r.startupName),
      discardLabel: WalletStrings.withdraw,
      keepLabel: WalletStrings.cancel,
    );
    if (!go || !context.mounted) return;
    final ok = await vm.withdraw(r);
    if (!context.mounted) return;
    if (ok) {
      AppToast.confirm(context, WalletStrings.requestWithdrawn);
    } else if (vm.error != null) {
      AppToast.error(context, vm.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final rows = vm.visibleRequests;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in RequestFilter.values)
                  AppFilterChip(
                    label: f.label,
                    selected: vm.filter == f,
                    onTap: () => vm.setFilter(f),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              ManageCard(
                child: Text(
                  vm.requests.isEmpty
                      ? WalletStrings.noRequests
                      : WalletStrings.noRequestsOf(vm.filter.label),
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
                  vm: vm,
                  request: rows[i],
                  onWithdraw: () => _withdraw(context, rows[i]),
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
    required this.vm,
    required this.request,
    required this.onWithdraw,
  });

  final WalletViewModel vm;
  final TicketRequest request;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return ManageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HueAvatar(name: r.startupName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.startupName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(size: 16.5, weight: FontWeight.w600),
                    ),
                    Text(
                      'Ticket: ${vm.ticketName(r.ticketId)}',
                      style: AppText.sans(
                        size: 14,
                        height: 20,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              RequestStatusPill(status: r.status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    Formatters.sar(r.amount),
                    style: AppText.sans(size: 17, weight: FontWeight.w700),
                  ),
                ),
                Text(
                  vm.ago(r.createdAt),
                  style: AppText.sans(size: 13.5, color: AppColors.grey),
                ),
              ],
            ),
          ),
          if (r.isPending) ...[
            const SizedBox(height: 12),
            AppButton(
              label: WalletStrings.withdraw,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.small,
              onPressed: onWithdraw,
            ),
          ],
        ],
      ),
    );
  }
}
