import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../helpers/formatters.dart';
import '../../../models/investment_ticket.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/overlays/app_bottom_sheet.dart';
import 'investor_profile_body.dart' show ProfileValueRows;

Future<void> showTicketInfoSheet(
  BuildContext context,
  InvestmentTicket ticket, {
  bool canSendRequest = false,
}) => showAppBottomSheet<void>(
  context,
  builder: (_) =>
      TicketInfoSheet(ticket: ticket, canSendRequest: canSendRequest),
);

class TicketInfoSheet extends StatelessWidget {
  const TicketInfoSheet({
    super.key,
    required this.ticket,
    this.canSendRequest = false,
  });

  final InvestmentTicket ticket;
  final bool canSendRequest;

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    return AppSheetScaffold(
      title: t.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileValueRows(ProfileStrings.ticketStatus, [
                    t.status.label,
                  ]),
                  ProfileValueRows(ProfileStrings.sectors, t.sectors),
                  ProfileValueRows(ProfileStrings.stages, t.stages),
                  ProfileValueRows(ProfileStrings.ticketMinimum, [
                    Formatters.sar(t.amountMin),
                  ]),
                  ProfileValueRows(ProfileStrings.ticketMaximum, [
                    Formatters.sar(t.amountMax),
                  ]),
                  if (t.createdAt != null)
                    ProfileValueRows(ProfileStrings.ticketCreated, [
                      Formatters.dayMonthYear(t.createdAt!),
                    ]),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: canSendRequest && t.isOpen
                ? AppButton(
                    label: ProfileStrings.sendTicketRequest,
                    onPressed: () {},
                  )
                : AppButton(
                    label: ProfileStrings.done,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
          ),
        ],
      ),
    );
  }
}
