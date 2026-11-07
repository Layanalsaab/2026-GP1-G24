import 'package:flutter/material.dart';

import '../../../app_constants/wallet_strings.dart';
import '../../../helpers/formatters.dart';
import '../../../helpers/ticket_rules.dart';
import '../../../models/connection_request.dart';
import '../../../models/investment_ticket.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../../startup_profile/screens/startup_profile_screen.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../startups/widgets/manage_card.dart';
import '../../startups/widgets/manage_rounds_tab.dart' show PillButton;
import '../../startups/widgets/round_detail.dart'
    show DetailBackLink, InfoBox, SectionTitle;
import '../view_models/wallet_view_model.dart';
import 'ticket_form.dart';

/// Investment Wallet -> one ticket: back link "All tickets", the ticket card
/// (status, sectors and stages, Minimum and Maximum, "Edit ticket" and "Close
/// ticket" for an open one), the "Requests" sent with it and, for an open
/// ticket, its "Matches". Built like the round page.
class TicketDetail extends StatelessWidget {
  const TicketDetail({
    super.key,
    required this.vm,
    required this.ticketId,
    required this.onBack,
  });

  final WalletViewModel vm;
  final String ticketId;
  final VoidCallback onBack;

  Future<void> _close(BuildContext context, InvestmentTicket ticket) async {
    final go = await showDiscardDialog(
      context,
      title: WalletStrings.closeTitle(ticket.name),
      message: WalletStrings.closeMessage,
      discardLabel: WalletStrings.closeTicket,
      keepLabel: WalletStrings.cancel,
    );
    if (!go || !context.mounted) return;
    final ok = await vm.closeTicket(ticket);
    if (!context.mounted) return;
    if (ok) {
      AppToast.confirm(context, WalletStrings.ticketClosed);
    } else if (vm.error != null) {
      AppToast.error(context, vm.error!);
    }
  }

  void _openStartup(BuildContext context, String id) {
    final startup = vm.startupById(id);
    if (startup == null) {
      AppToast.error(context, 'This startup isn’t available.');
      return;
    }
    StartupProfileScreen.open(context, startup: startup);
  }

  @override
  Widget build(BuildContext context) {
    final ticket = vm.ticketById(ticketId);
    if (ticket == null) return const SizedBox.shrink();
    final editingThis = vm.editing?.id == ticket.id;
    final mine = vm.requestsOfTicket(ticket);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailBackLink(label: WalletStrings.allTickets, onTap: onBack),
        const SizedBox(height: 14),
        if (editingThis) ...[
          TicketForm(vm: vm, editing: true),
          const SizedBox(height: 14),
        ],
        _TicketCard(
          vm: vm,
          ticket: ticket,
          // Open ticket, and no form open.
          canChange: ticket.isOpen && !vm.formOpen && !vm.editOpen,
          onEdit: () => vm.openEdit(ticket),
          onClose: () => _close(context, ticket),
          onOpenStartup: () => _openStartup(context, ticket.startupId!),
        ),
        const SizedBox(height: 22),
        const SectionTitle(
          title: WalletStrings.requestsHeading,
          subtitle: WalletStrings.requestsSub,
        ),
        const SizedBox(height: 10),
        if (mine.isEmpty)
          const ManageCard(child: _Grey(WalletStrings.noTicketRequests))
        else
          for (final r in mine) ...[
            _RequestRow(vm: vm, request: r),
            const SizedBox(height: 10),
          ],
        if (ticket.isOpen) ...[
          const SizedBox(height: 12),
          const SectionTitle(
            title: WalletStrings.matchesHeading,
            subtitle: WalletStrings.matchesSub,
          ),
          const SizedBox(height: 10),
          _Matches(
            vm: vm,
            ticket: ticket,
            onOpen: (id) => _openStartup(context, id),
          ),
        ],
      ],
    );
  }
}

class _Grey extends StatelessWidget {
  const _Grey(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppText.sans(size: 14, height: 20, color: AppColors.grey),
  );
}

// ------------------------------------------------------------------ card

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.vm,
    required this.ticket,
    required this.canChange,
    required this.onEdit,
    required this.onClose,
    required this.onOpenStartup,
  });

  final WalletViewModel vm;
  final InvestmentTicket ticket;
  final bool canChange;
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final VoidCallback onOpenStartup;

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    return ManageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    t.name,
                    style: AppText.sans(
                      size: 20,
                      height: 26,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              AppPill(
                label: t.status.label,
                tone: t.isOpen ? AppPillTone.moss : AppPillTone.grey,
                height: 26,
                fontSize: 12.5,
                weight: FontWeight.w600,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${t.sectors.join(', ')} · ${t.stages.join(', ')}',
            style: AppText.sans(size: 14, height: 20, color: AppColors.grey),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InfoBox(
                  label: WalletStrings.minimum,
                  value: Formatters.sar(t.amountMin),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InfoBox(
                  label: WalletStrings.maximum,
                  value: Formatters.sar(t.amountMax),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Created ${vm.ago(t.createdAt)}',
            style: AppText.sans(size: 13, color: AppColors.grey),
          ),
          if (t.status == TicketStatus.used && t.startupId != null) ...[
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: '${WalletStrings.usedFor} ${vm.usedForName(t)}',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onOpenStartup,
                child: Text.rich(
                  TextSpan(
                    text: '${WalletStrings.usedFor} ',
                    style: AppText.sans(size: 14, color: AppColors.grey),
                    children: [
                      TextSpan(
                        text: vm.usedForName(t),
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
            ),
          ],
          if (canChange) ...[
            const SizedBox(height: 16),
            // Same styles as Edit round (outline) and Close round (white pill).
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: WalletStrings.editTicket,
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.small,
                    onPressed: onEdit,
                  ),
                ),
                const SizedBox(width: 12),
                PillButton(label: WalletStrings.closeTicket, onTap: onClose),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- requests

/// One request sent with the ticket: the startup, "SAR amount · time ago" and
/// its status.
class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.vm, required this.request});

  final WalletViewModel vm;
  final TicketRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return ManageCard(
      padding: const EdgeInsets.all(14),
      child: Row(
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
                  '${Formatters.sar(r.amount)} · ${vm.ago(r.createdAt)}',
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
    );
  }
}

/// Pending (gold), Accepted (green), Declined (grey).
class RequestStatusPill extends StatelessWidget {
  const RequestStatusPill({super.key, required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) => AppPill(
    label: switch (status) {
      RequestStatus.pending => 'Pending',
      RequestStatus.accepted => 'Accepted',
      RequestStatus.declined => 'Declined',
    },
    tone: switch (status) {
      RequestStatus.pending => AppPillTone.gold,
      RequestStatus.accepted => AppPillTone.moss,
      RequestStatus.declined => AppPillTone.grey,
    },
    height: 26,
    fontSize: 12.5,
    weight: FontWeight.w600,
  );
}

// --------------------------------------------------------------- matches

class _Matches extends StatelessWidget {
  const _Matches({
    required this.vm,
    required this.ticket,
    required this.onOpen,
  });

  final WalletViewModel vm;
  final InvestmentTicket ticket;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (vm.matchesFailed) {
      return const ManageCard(child: _Grey(WalletStrings.matchesFailed));
    }
    final matches = vm.matchesOf(ticket);
    if (matches.isEmpty) {
      return const ManageCard(child: _Grey(WalletStrings.noMatches));
    }
    return Column(
      children: [
        for (final m in matches) ...[
          _MatchCard(
            vm: vm,
            ticket: ticket,
            match: m,
            onOpen: () => onOpen(m.startup.id),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.vm,
    required this.ticket,
    required this.match,
    required this.onOpen,
  });

  final WalletViewModel vm;
  final InvestmentTicket ticket;
  final TicketMatch match;
  final VoidCallback onOpen;

  Future<void> _cancel(BuildContext context) async {
    if (vm.sendDirty) {
      final discard = await showDiscardDialog(
        context,
        title: WalletStrings.discardTitle,
        message: WalletStrings.discardMessage,
        discardLabel: WalletStrings.discard,
        keepLabel: WalletStrings.keepEditing,
      );
      if (!discard) return;
    }
    vm.cancelSend();
  }

  Future<void> _send(BuildContext context) async {
    // Invalid: the error shows first, no confirm.
    if (!vm.trySend(ticket, match.remaining)) return;
    final name = match.startup.name;
    final amount = Formatters.sar(vm.sendValue!);
    final go = await showSaveConfirmDialog(
      context,
      title: WalletStrings.sendTitle,
      message: WalletStrings.sendMessage(name, amount),
      confirmLabel: WalletStrings.sendRequest,
    );
    if (!go || !context.mounted) return;
    final ok = await vm.sendRequest(ticket, match);
    if (!context.mounted) return;
    if (ok) {
      AppToast.confirm(context, WalletStrings.requestSent(name));
    } else if (vm.error != null) {
      AppToast.error(context, vm.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = match.startup;
    final sent = vm.requestSent(ticket, s.id);
    final sending = vm.sendingTo == s.id && !sent;
    return ManageCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The top part opens the startup.
          Semantics(
            button: true,
            label: '${s.name}, ${s.sectorLabel} · ${s.stageLabel}',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HueAvatar(
                    name: s.name,
                    size: 44,
                    imageUrl: s.logoUrl,
                    imageData: s.logoData,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(
                            size: 16,
                            height: 22,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${s.sectorLabel} · ${s.stageLabel}',
                          style: AppText.sans(
                            size: 13.5,
                            height: 19,
                            color: AppColors.grey,
                          ),
                        ),
                        Text(
                          'Raising · ${Formatters.sar(match.remaining)} left',
                          style: AppText.sans(
                            size: 13.5,
                            height: 19,
                            weight: FontWeight.w600,
                            color: AppColors.tagGoldText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mossChip,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${match.percent}% match',
                                style: AppText.sans(
                                  size: 12.5,
                                  color: AppColors.moss600,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              match.reason,
                              style: AppText.sans(
                                size: 12.5,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const AppIcon.outline(
                    AppIcons.rowChevron,
                    size: 20,
                    stroke: 2.2,
                    color: Color(0xFF9AA19B),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (sent)
            const Align(
              alignment: Alignment.centerLeft,
              child: AppPill(
                label: WalletStrings.requestSentPill,
                icon: AppIcons.check,
                weight: FontWeight.w600,
              ),
            )
          else if (!sending)
            AppButton(
              label: WalletStrings.sendRequest,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.small,
              onPressed: () => vm.startSend(ticket, s.id),
            )
          else ...[
            AppField(
              label: 'Amount',
              required: true,
              sentenceCase: true,
              hint: TicketSend.range(ticket, match.remaining),
              error: vm.sendError(ticket, match.remaining),
              child: MoneyField(
                controller: vm.sendAmount,
                hasError: vm.sendError(ticket, match.remaining) != null,
                semanticLabel: 'Amount',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: WalletStrings.cancel,
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.small,
                    onPressed: () => _cancel(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: WalletStrings.sendRequest,
                    variant: vm.sendValid(ticket, match.remaining)
                        ? AppButtonVariant.primary
                        : AppButtonVariant.off,
                    size: AppButtonSize.small,
                    onPressed: () => _send(context),
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
