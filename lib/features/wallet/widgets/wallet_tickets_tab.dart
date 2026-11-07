import 'package:flutter/material.dart';

import '../../../app_constants/wallet_strings.dart';
import '../../../helpers/formatters.dart';
import '../../../helpers/ticket_rules.dart';
import '../../../models/investment_ticket.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../startups/widgets/manage_card.dart';
import '../../startups/widgets/manage_rounds_tab.dart'
    show PillButton, StatusDot;
import '../view_models/wallet_view_model.dart';
import 'ticket_detail.dart';
import 'ticket_form.dart';

/// Investment Wallet -> Tickets: built like Manage -> Rounds.
///
/// Top row: "Investment tickets" with "All amounts in SAR" and a green "Add
/// ticket". Below, the "New ticket" form when it is open, then the tickets
/// table, newest first. Tapping a ticket opens its page ([TicketDetail])
/// inside this tab.
class WalletTicketsTab extends StatefulWidget {
  const WalletTicketsTab({super.key, required this.vm});

  final WalletViewModel vm;

  @override
  State<WalletTicketsTab> createState() => _WalletTicketsTabState();
}

class _WalletTicketsTabState extends State<WalletTicketsTab> {
  /// The ticket whose page is open, or null for the list. It lives here (not
  /// in the view model), so switching tabs always comes back to the list.
  String? _detail;

  WalletViewModel get vm => widget.vm;

  @override
  void initState() {
    super.initState();
    // Back on the list: a form left open is dropped.
    vm.resetView();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final detail = _detail;
        if (detail != null && vm.ticketById(detail) != null) {
          return TicketDetail(
            vm: vm,
            ticketId: detail,
            onBack: () {
              // A form left open is dropped with the page.
              vm.resetView();
              setState(() => _detail = null);
            },
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          WalletStrings.ticketsHeading,
                          style: AppText.sans(
                            size: 19,
                            height: 26,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        WalletStrings.allAmounts,
                        style: AppText.sans(
                          size: 13,
                          color: const Color(0xFF8C918D),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!vm.formOpen && !vm.isLoading && !vm.loadFailed)
                  PillButton(
                    label: WalletStrings.addTicket,
                    icon: AppIcons.plus,
                    filled: true,
                    onTap: vm.openForm,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (vm.formOpen) ...[
              TicketForm(vm: vm),
              const SizedBox(height: 14),
            ],
            _TicketsTable(
              vm: vm,
              onOpen: (t) => setState(() => _detail = t.id),
            ),
            if (vm.tickets.isNotEmpty) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  WalletStrings.tapHint,
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 13, color: const Color(0xFF8C918D)),
                ),
              ),
            ],
            if (vm.loadFailed) ...[
              const SizedBox(height: 10),
              Center(
                child: PillButton(
                  label: WalletStrings.tryAgain,
                  onTap: vm.load,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------ table

/// Column widths: Ticket · Amount · Matches, gap 10.
const _flex = [130, 95, 78];
const _gap = 10.0;

/// Right padding of a row: room for the chevron.
const double _chevronRoom = 32;

class _TicketsTable extends StatelessWidget {
  const _TicketsTable({required this.vm, required this.onOpen});

  final WalletViewModel vm;
  final ValueChanged<InvestmentTicket> onOpen;

  @override
  Widget build(BuildContext context) {
    final tickets = vm.tickets;
    final emptyText = vm.isLoading
        ? WalletStrings.loading
        : vm.loadFailed
        ? WalletStrings.loadFailed
        : WalletStrings.noTickets;
    final table = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderRow(),
        if (tickets.isEmpty)
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              emptyText,
              style: AppText.sans(size: 14, color: AppColors.grey),
            ),
          ),
        for (final t in tickets) ...[
          const Divider(height: 1, color: AppColors.dividerSoft),
          _TicketRow(vm: vm, ticket: t, onTap: () => onOpen(t)),
        ],
      ],
    );
    return ManageCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(borderRadius: BorderRadius.circular(19), child: table),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    TextStyle style() => AppText.sans(
      size: 11.5,
      weight: FontWeight.w700,
      letterSpacing: 0.5,
      color: const Color(0xFF8C918D),
    );
    Widget cell(int i, String text, {bool center = false}) => Expanded(
      flex: _flex[i],
      child: Text(
        text.toUpperCase(),
        textAlign: center ? TextAlign.center : TextAlign.start,
        maxLines: 1,
        style: style(),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, _chevronRoom, 12),
      child: Row(
        children: [
          cell(0, WalletStrings.colTicket),
          const SizedBox(width: _gap),
          cell(1, WalletStrings.colAmount, center: true),
          const SizedBox(width: _gap),
          cell(2, WalletStrings.colMatches),
        ],
      ),
    );
  }
}

/// One ticket: the first line of every cell has the same 22 px line height,
/// so the three first lines sit on one line.
class _TicketRow extends StatefulWidget {
  const _TicketRow({
    required this.vm,
    required this.ticket,
    required this.onTap,
  });

  final WalletViewModel vm;
  final InvestmentTicket ticket;
  final VoidCallback onTap;

  static const double line = 22;

  @override
  State<_TicketRow> createState() => _TicketRowState();
}

class _TicketRowState extends State<_TicketRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return Semantics(
      button: true,
      label: '${t.name}, ${t.status.label.toLowerCase()}',
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: ColoredBox(
          color: _pressed ? AppColors.moss50 : Colors.transparent,
          child: Stack(
            children: [
              _content(),
              const Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: ExcludeSemantics(
                    child: AppIcon.outline(
                      AppIcons.rowChevron,
                      size: 20,
                      stroke: 2.2,
                      color: Color(0xFF9AA19B),
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

  Widget _content() {
    final t = widget.ticket;
    final vm = widget.vm;
    const line = _TicketRow.line;
    final matches = vm.matchesLabel(t);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, _chevronRoom, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ticket: status dot and name, the status word, "Sectors · Stages".
          Expanded(
            flex: _flex[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: line,
                  child: Row(
                    children: [
                      StatusDot(open: t.isOpen, label: t.status.label),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(
                            size: 16,
                            height: line,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  t.status.label,
                  style: AppText.sans(
                    size: 12.5,
                    height: 17,
                    weight: FontWeight.w600,
                    color: t.isOpen
                        ? const Color(0xFF2F8A4A)
                        : const Color(0xFF8C918D),
                  ),
                ),
                Text(
                  '${shortList(t.sectors)} · ${shortList(t.stages)}',
                  style: AppText.sans(
                    size: 13,
                    height: 18,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _gap),
          // Amount: "100K – 300K", centred, never wraps.
          Expanded(
            flex: _flex[1],
            child: SizedBox(
              height: line,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${Formatters.shortMoney(t.amountMin)} – '
                    '${Formatters.shortMoney(t.amountMax)}',
                    maxLines: 1,
                    softWrap: false,
                    style: AppText.sans(
                      size: 15,
                      height: line,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: _gap),
          // Matches: "2 matches", the startup (used) or "—" (closed).
          Expanded(
            flex: _flex[2],
            child: SizedBox(
              height: line,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  matches,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: t.isOpen && matches != '0 matches'
                        ? AppColors.moss600
                        : AppColors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
