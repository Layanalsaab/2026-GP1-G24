import 'package:flutter/material.dart';

import '../../../app_constants/wallet_strings.dart';
import '../../../helpers/formatters.dart';
import '../../../models/received_request.dart';
import '../../connection_requests/widgets/request_status_pill.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../startups/widgets/manage_card.dart';
import '../view_models/wallet_view_model.dart';

class ReceivedRequestCard extends StatelessWidget {
  const ReceivedRequestCard({
    super.key,
    required this.vm,
    required this.request,
    this.showTicket = false,
  });

  final WalletViewModel vm;
  final ReceivedRequest request;

  final bool showTicket;

  Future<void> _answer(BuildContext context, bool accept) async {
    final ok = await vm.answerReceived(request, accept: accept);
    if (!context.mounted) return;
    if (ok) {
      AppToast.confirm(
        context,
        accept ? WalletStrings.requestAccepted : WalletStrings.requestDeclined,
      );
    } else if (vm.error != null) {
      AppToast.error(context, vm.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = request;
    return ManageCard(
      padding: const EdgeInsets.all(14),
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
                      style: AppText.sans(
                        size: 16,
                        height: 22,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      showTicket
                          ? '${WalletStrings.requestReceived} · ${vm.ticketName(r.ticketId)}'
                          : WalletStrings.requestReceived,
                      style: AppText.sans(
                        size: 13.5,
                        height: 19,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                  vm.dateOf(r.createdAt),
                  style: AppText.sans(size: 13.5, color: AppColors.grey),
                ),
              ],
            ),
          ),
          if (r.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: WalletStrings.decline,
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.small,
                    onPressed: () => _answer(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: WalletStrings.accept,
                    size: AppButtonSize.small,
                    onPressed: () => _answer(context, true),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
