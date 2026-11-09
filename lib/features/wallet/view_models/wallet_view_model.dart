import 'package:flutter/material.dart';

import '../../../data_access/repositories/matching_repository.dart';
import '../../../data_access/repositories/ticket_repository.dart';
import '../../../helpers/formatters.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/ticket_rules.dart';
import '../../../models/investment_ticket.dart';
import '../../../models/match_summary.dart';
import '../../../models/startup.dart';
import '../../../app_constants/wallet_strings.dart';

/// The filters of the Requests tab.
enum RequestFilter {
  all('All'),
  pending('Pending'),
  accepted('Accepted'),
  declined('Declined');

  const RequestFilter(this.label);

  final String label;
}

/// State of the Investment Wallet (investor only): the tickets, the Add /
/// Edit ticket form, the matches of a ticket, "Send request" and the
/// Requests tab.
///
/// Built like Manage -> Rounds (RoundsViewModel): a list, a page and a form.
class WalletViewModel extends ChangeNotifier with SafeNotifier {
  WalletViewModel({
    required this.investorId,
    this.commerceModels = const [],
    TicketRepository? tickets,
    MatchingRepository? matching,
    DateTime Function()? now,
  }) : _ticketsOverride = tickets,
       _matchingOverride = matching,
       _fixedNow = now {
    for (final c in [name, min, max, sendAmount]) {
      c.addListener(notifyListeners);
    }
    // A startup opened, closed or changed its round: matches follow.
    _pool.changes.addListener(_onPoolChange);
  }

  final String investorId;

  /// The investor's profile commerce models (labels): the 20% part of every
  /// ticket's match score.
  final List<String> commerceModels;

  final TicketRepository? _ticketsOverride;
  final MatchingRepository? _matchingOverride;
  final DateTime Function()? _fixedNow;

  TicketRepository get _repo => _ticketsOverride ?? TicketRepository.instance;
  MatchingRepository get _pool =>
      _matchingOverride ?? MatchingRepository.instance;

  // ------------------------------------------------------------ loading

  List<InvestmentTicket> tickets = const [];
  List<TicketRequest> requests = const [];
  List<Startup> _startups = const [];

  bool isLoading = true;
  bool loadFailed = false;

  /// The startups could not be read: the matches say so instead of "none".
  bool matchesFailed = false;

  Future<void> load() async {
    isLoading = true;
    loadFailed = false;
    notifyListeners();
    try {
      tickets = await _repo.ticketsOf(investorId);
      requests = await _repo.requestsOf(investorId);
    } catch (_) {
      loadFailed = true;
    }
    isLoading = false;
    notifyListeners();
    await _loadStartups();
  }

  Future<void> _loadStartups() async {
    try {
      _startups = await _pool.publicStartups();
      matchesFailed = false;
    } catch (_) {
      matchesFailed = true;
    }
    _matches.clear();
    notifyListeners();
  }

  /// The watched startups changed: read the (already updated) pool again
  /// (no extra Firestore reads).
  void _onPoolChange() => _loadStartups();

  InvestmentTicket? ticketById(String id) {
    for (final t in tickets) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ------------------------------------------------------------ matches

  /// Matches already worked out, by ticket (and what it holds).
  final Map<String, List<TicketMatch>> _matches = {};

  /// The ticket's matches, best first: listed startups that are raising,
  /// exact matches before close ones. None for a used or closed ticket.
  List<TicketMatch> matchesOf(InvestmentTicket ticket) {
    if (!ticket.isOpen) return const [];
    final key = [
      ticket.id,
      ticket.sectors.join('|'),
      ticket.stages.join('|'),
      ticket.amountMin,
      ticket.amountMax,
    ].join('~');
    return _matches[key] ??= () {
      final byId = {for (final s in _startups) s.id: s};
      return [
        for (final r in MatchingRepository.matchesForTicket(
          ticket,
          commerceModels,
          _startups,
        ))
          TicketMatch(startup: byId[r.id]!, result: r),
      ];
    }();
  }

  /// Why [match] matched [ticket], for the top of the startup's profile.
  MatchSummary summaryOf(InvestmentTicket ticket, TicketMatch match) =>
      MatchSummary.forTicket(ticket.name, match.result);

  /// The startup a used ticket was used for.
  String usedForName(InvestmentTicket t) {
    for (final r in requests) {
      if (r.ticketId == t.id && r.startupId == t.startupId) {
        return r.startupName;
      }
    }
    for (final s in _startups) {
      if (s.id == t.startupId) return s.name;
    }
    return 'Startup';
  }

  Startup? startupById(String id) {
    for (final s in _startups) {
      if (s.id == id) return s;
    }
    return _pool.startupById(id);
  }

  // --------------------------------------------------------------- form

  final name = TextEditingController();
  final min = TextEditingController();
  final max = TextEditingController();
  final Set<String> sectors = {};

  /// What was typed for "Other" in the sectors (the ticket then keeps that
  /// text as its sector).
  String sectorOther = '';
  final Set<String> stages = {};

  /// The "New ticket" form is open (above the list).
  bool formOpen = false;

  /// The ticket being edited (the form is on its page), or null.
  InvestmentTicket? editing;

  bool tried = false;
  bool isSaving = false;
  String? error;
  String _baseline = '';

  bool get editOpen => editing != null;

  /// "Ticket N": the highest number plus 1.
  String get defaultName {
    var highest = 0;
    for (final t in tickets) {
      if (t.number > highest) highest = t.number;
    }
    return 'Ticket ${highest + 1}';
  }

  String _signature() => [
    name.text.trim(),
    (sectors.toList()..sort()).join('|'),
    sectorOther.trim(),
    (stages.toList()..sort()).join('|'),
    minValue ?? '',
    maxValue ?? '',
  ].join('~');

  void openForm() {
    if (formOpen || editing != null) return;
    formOpen = true;
    _fill(name: defaultName);
    notifyListeners();
  }

  void openEdit(InvestmentTicket ticket) {
    if (!ticket.isOpen || formOpen || editing != null) return;
    editing = ticket;
    _fill(
      name: ticket.name,
      sectors: ticket.sectors,
      stages: ticket.stages,
      min: ticket.amountMin,
      max: ticket.amountMax,
    );
    notifyListeners();
  }

  void _fill({
    required String name,
    List<String> sectors = const [],
    List<String> stages = const [],
    int? min,
    int? max,
  }) {
    this.name.text = name;
    // A sector that is not in the list was typed under "Other".
    final known = _sectorOrder.toSet();
    final custom = [
      for (final x in sectors)
        if (known.isNotEmpty && !known.contains(x)) x,
    ];
    sectorOther = custom.isEmpty ? '' : custom.first;
    this.sectors
      ..clear()
      ..addAll([
        for (final x in sectors)
          if (!custom.contains(x)) x,
        if (custom.isNotEmpty) 'Other',
      ]);
    this.stages
      ..clear()
      ..addAll(stages);
    this.min.text = min == null ? '' : Formatters.thousands(min);
    this.max.text = max == null ? '' : Formatters.thousands(max);
    tried = false;
    error = null;
    _baseline = _signature();
  }

  /// A new ticket's default name alone is not a change.
  bool get formDirty =>
      (formOpen || editing != null) && _signature() != _baseline;

  void cancelForm() {
    formOpen = false;
    editing = null;
    error = null;
    notifyListeners();
  }

  /// Back on the list: a form left open is dropped.
  void resetView() {
    if (!formOpen && editing == null && sendingTo == null) return;
    formOpen = false;
    editing = null;
    sendingTo = null;
    notifyListeners();
  }

  void toggleSector(String value) {
    if (sectors.contains(value)) {
      sectors.remove(value);
      // Unticking Other forgets what was typed for it.
      if (value == 'Other') sectorOther = '';
    } else {
      sectors.add(value);
    }
    notifyListeners();
  }

  void setSectorOther(String value) {
    sectorOther = value;
    notifyListeners();
  }

  /// The picker closed with Other ticked and nothing typed: untick it.
  void undoSectorOther() {
    sectors.remove('Other');
    sectorOther = '';
    notifyListeners();
  }

  /// The sectors as the ticket keeps them: the list's order, and the typed
  /// text in place of "Other".
  List<String> get sectorsToSave {
    final listed = _ordered({...sectors}..remove('Other'), _sectorOrder);
    final typed = sectorOther.trim();
    return [
      ...listed,
      if (sectors.contains('Other') && typed.isNotEmpty) typed,
    ];
  }

  void toggleStage(String value) {
    stages.contains(value) ? stages.remove(value) : stages.add(value);
    notifyListeners();
  }

  int? get minValue => Formatters.parseMoney(min.text);
  int? get maxValue => Formatters.parseMoney(max.text);

  // A box that is still empty shows its error only after Add ticket / Save
  // changes was pressed; a wrong value shows it at once.
  String? get nameError => tried ? TicketErrors.name(name.text) : null;
  String? get sectorsError =>
      tried ? TicketErrors.sectors(sectors, other: sectorOther) : null;
  String? get stagesError => tried ? TicketErrors.stages(stages) : null;

  String? get minError {
    if (minValue == null && !tried) return null;
    return TicketErrors.minimum(minValue);
  }

  String? get maxError {
    if (maxValue == null && !tried) return null;
    // "More than the minimum" waits for a valid minimum.
    return TicketErrors.maximum(maxValue, minValue);
  }

  bool get formValid =>
      TicketErrors.name(name.text) == null &&
      TicketErrors.sectors(sectors, other: sectorOther) == null &&
      TicketErrors.stages(stages) == null &&
      TicketErrors.minimum(minValue) == null &&
      TicketErrors.maximum(maxValue, minValue) == null;

  /// Add ticket / Save changes. False (and the errors show) when the form is
  /// not valid or saving failed ([error] says so).
  Future<bool> submit() async {
    if (isSaving) return false;
    tried = true;
    if (!formValid) {
      notifyListeners();
      return false;
    }
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      final edited = editing;
      final fields = InvestmentTicket(
        id: edited?.id ?? '',
        investorId: investorId,
        name: name.text.trim(),
        sectors: sectorsToSave,
        stages: _ordered(stages, _stageOrder),
        amountMin: minValue!,
        amountMax: maxValue!,
      );
      if (edited != null) {
        final saved = edited.copyWith(
          name: fields.name,
          sectors: fields.sectors,
          stages: fields.stages,
          amountMin: fields.amountMin,
          amountMax: fields.amountMax,
        );
        await _repo.update(saved);
        tickets = [for (final t in tickets) t.id == saved.id ? saved : t];
      } else {
        final created = await _repo.create(investorId, fields, tickets);
        tickets = [created, ...tickets];
      }
      formOpen = false;
      editing = null;
      return true;
    } catch (_) {
      error = WalletStrings.saveFailed;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// The order of the onboarding lists, so a ticket shows "Logistics,
  /// E-commerce" the way the lists do.
  List<String> _sectorOrder = const [];
  List<String> _stageOrder = const [];

  void setOptionOrder({
    required List<String> sectors,
    required List<String> stages,
  }) {
    _sectorOrder = sectors;
    _stageOrder = stages;
  }

  static List<String> _ordered(Set<String> chosen, List<String> order) => [
    for (final o in order)
      if (chosen.contains(o)) o,
    for (final c in chosen)
      if (!order.contains(c)) c,
  ];

  /// Closes an open ticket. True on success.
  Future<bool> closeTicket(InvestmentTicket ticket) async {
    if (!ticket.isOpen || isSaving) return false;
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repo.close(ticket);
      tickets = [
        for (final t in tickets)
          t.id == ticket.id ? t.copyWith(status: TicketStatus.closed) : t,
      ];
      if (sendingTo != null) sendingTo = null;
      return true;
    } catch (_) {
      error = WalletStrings.saveFailed;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------- send request

  /// The startup whose "Send request" form is open.
  String? sendingTo;
  final sendAmount = TextEditingController();
  bool sendTried = false;
  bool isSending = false;

  /// Only open tickets send requests.
  void startSend(InvestmentTicket ticket, String startupId) {
    if (!ticket.isOpen) return;
    sendingTo = startupId;
    sendAmount.clear();
    sendTried = false;
    error = null;
    notifyListeners();
  }

  void cancelSend() {
    sendingTo = null;
    notifyListeners();
  }

  int? get sendValue => Formatters.parseMoney(sendAmount.text);

  bool get sendDirty => sendAmount.text.trim().isNotEmpty;

  String? sendError(InvestmentTicket ticket, int remaining) {
    final v = sendValue;
    if (v == null && !sendTried) return null;
    return TicketSend.error(v, ticket, remaining);
  }

  bool sendValid(InvestmentTicket ticket, int remaining) =>
      TicketSend.error(sendValue, ticket, remaining) == null;

  /// A pending request of [ticket] to [startupId] exists.
  bool requestSent(InvestmentTicket ticket, String startupId) => requests.any(
    (r) => r.ticketId == ticket.id && r.startupId == startupId && r.isPending,
  );

  /// Marks the form as tried (the error shows); true when it can be sent.
  bool trySend(InvestmentTicket ticket, int remaining) {
    sendTried = true;
    notifyListeners();
    return ticket.isOpen && sendValid(ticket, remaining);
  }

  Future<bool> sendRequest(InvestmentTicket ticket, TicketMatch match) async {
    final amount = sendValue;
    if (isSending || amount == null || !ticket.isOpen) return false;
    if (!sendValid(ticket, match.remaining)) return false;
    isSending = true;
    error = null;
    notifyListeners();
    try {
      final sent = await _repo.sendRequest(
        ticket: ticket,
        startupId: match.startup.id,
        startupName: match.startup.name,
        founderId: match.startup.founderId,
        amount: amount,
      );
      requests = [sent, ...requests];
      sendingTo = null;
      return true;
    } catch (_) {
      error = WalletStrings.sendFailed;
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------ requests

  RequestFilter filter = RequestFilter.all;

  void setFilter(RequestFilter value) {
    if (filter == value) return;
    filter = value;
    notifyListeners();
  }

  int get pendingCount => requests.where((r) => r.isPending).length;

  List<TicketRequest> get visibleRequests => [
    for (final r in requests)
      if (filter == RequestFilter.all || r.status.value == filter.name) r,
  ];

  List<TicketRequest> requestsOfTicket(InvestmentTicket t) => [
    for (final r in requests)
      if (r.ticketId == t.id) r,
  ];

  String ticketName(String ticketId) => ticketById(ticketId)?.name ?? 'Ticket';

  Future<bool> withdraw(TicketRequest request) async {
    if (!request.isPending || isSaving) return false;
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repo.withdraw(request.id);
      requests = [
        for (final r in requests)
          if (r.id != request.id) r,
      ];
      return true;
    } catch (_) {
      error = WalletStrings.withdrawFailed;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  String ago(DateTime? when) => timeAgo(when, now: _fixedNow?.call());

  @override
  void dispose() {
    _pool.changes.removeListener(_onPoolChange);
    for (final c in [name, min, max, sendAmount]) {
      c.removeListener(notifyListeners);
      c.dispose();
    }
    super.dispose();
  }
}
