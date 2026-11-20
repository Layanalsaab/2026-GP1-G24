import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../data_access/repositories/ticket_request_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/formatters.dart';
import '../../../helpers/ticket_rules.dart';
import '../../../models/investment_ticket.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/money_field.dart';
import '../../../shared_ui/widgets/overlays/app_bottom_sheet.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../../../shared_ui/widgets/overlays/picker_sheet.dart';

Future<bool> showSendTicketRequestSheet(
  BuildContext context, {
  required InvestmentTicket ticket,
  required String investorName,
}) async {
  final sent = await showAppBottomSheet<bool>(
    context,
    builder: (_) =>
        SendTicketRequestSheet(ticket: ticket, investorName: investorName),
  );
  return sent ?? false;
}

class SendTicketRequestSheet extends StatefulWidget {
  const SendTicketRequestSheet({
    super.key,
    required this.ticket,
    required this.investorName,
    this.startups,
    this.repository,
  });

  final InvestmentTicket ticket;
  final String investorName;

  /// The startups that can send (tests); null reads the founder's own.
  final List<Startup>? startups;
  final TicketRequestRepository? repository;

  @override
  State<SendTicketRequestSheet> createState() => _SendTicketRequestSheetState();
}

class _SendTicketRequestSheetState extends State<SendTicketRequestSheet> {
  final _amount = TextEditingController();
  List<Startup> _startups = const [];
  Set<String> _sent = const {};
  Startup? _picked;
  bool _loading = true;
  bool _tried = false;
  bool _sending = false;

  TicketRequestRepository get _repo =>
      widget.repository ?? TicketRequestRepository.instance;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// What the open round of s still needs, in SAR (0: not raising).
  static int remainingOf(Startup s) {
    final need = s.fundingRequirement ?? 0;
    if (need <= 0) return 0;
    final left = need - (s.raisedInRound ?? 0);
    return left < 0 ? 0 : left;
  }

  Future<void> _load() async {
    var startups = widget.startups;
    var sent = <String>{};
    try {
      startups ??= await StartupRepository.instance.fetchMyStartups();
      final uid = AppSession.instance.user?.uid;
      if (uid != null) sent = await _repo.sentBy(uid);
    } catch (_) {
      startups ??= const [];
    }
    if (!mounted) return;
    final eligible = [
      for (final s in startups)
        if (!s.isClosed && remainingOf(s) > 0) s,
    ];
    final free = [
      for (final s in eligible)
        if (!sent.contains(
          TicketRequestRepository.idOf(s.id, widget.ticket.id),
        ))
          s,
    ];
    setState(() {
      _startups = eligible;
      _sent = sent;
      _picked = free.isEmpty ? null : free.first;
      _loading = false;
    });
  }

  bool _alreadySent(Startup s) =>
      _sent.contains(TicketRequestRepository.idOf(s.id, widget.ticket.id));

  int? get _value => Formatters.parseMoney(_amount.text);

  String? get _error {
    final p = _picked;
    if (p == null) return null;
    if (_value == null && !_tried) return null;
    return TicketSend.error(_value, widget.ticket, remainingOf(p));
  }

  bool get _valid {
    final p = _picked;
    return p != null &&
        TicketSend.error(_value, widget.ticket, remainingOf(p)) == null;
  }

  Future<void> _send() async {
    setState(() => _tried = true);
    final p = _picked;
    final amount = _value;
    if (_sending || p == null || amount == null || !_valid) return;
    setState(() => _sending = true);
    try {
      await _repo.send(ticket: widget.ticket, startup: p, amount: amount);
      if (!mounted) return;
      AppToast.confirm(
        context,
        ProfileStrings.requestSentTo(widget.investorName),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      AppToast.error(context, ProfileStrings.sendRequestFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: ProfileStrings.sendTicketRequest,
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          : _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_startups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Text(
          ProfileStrings.noRaisingStartup,
          style: AppText.sans(size: 15, height: 22, color: AppColors.grey),
        ),
      );
    }
    final p = _picked;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_startups.length > 1) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(
                ProfileStrings.chooseStartup,
                style: AppText.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
            ),
            for (final s in _startups)
              PickerOptionRow(
                label: _alreadySent(s)
                    ? '${s.name} · ${ProfileStrings.requestSent}'
                    : s.name,
                selected: _picked?.id == s.id,
                onTap: () {
                  if (_alreadySent(s)) return;
                  setState(() => _picked = s);
                },
              ),
            const SizedBox(height: 12),
          ],
          if (p == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                ProfileStrings.requestAlreadySent,
                style: AppText.sans(
                  size: 15,
                  height: 22,
                  color: AppColors.grey,
                ),
              ),
            )
          else ...[
            AppField(
              label: ProfileStrings.requestAmount,
              required: true,
              sentenceCase: true,
              hint: TicketSend.range(widget.ticket, remainingOf(p)),
              error: _error,
              child: MoneyField(
                controller: _amount,
                hasError: _error != null,
                semanticLabel: ProfileStrings.requestAmount,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: ProfileStrings.sendTicketRequest,
              variant: _valid ? AppButtonVariant.primary : AppButtonVariant.off,
              onPressed: _send,
            ),
          ],
        ],
      ),
    );
  }
}
