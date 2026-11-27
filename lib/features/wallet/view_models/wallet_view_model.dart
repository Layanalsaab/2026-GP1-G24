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
    for (final c in [name, min, max]) {
      c.addListener(notifyListeners);
    }
    _pool.changes.addListener(_onPoolChange);
  }

  final String investorId;

  final List<String> commerceModels;

  final TicketRepository? _ticketsOverride;
  final MatchingRepository? _matchingOverride;
  final DateTime Function()? _fixedNow;

  TicketRepository get _repo => _ticketsOverride ?? TicketRepository.instance;
  MatchingRepository get _pool =>
      _matchingOverride ?? MatchingRepository.instance;

  List<InvestmentTicket> tickets = const [];
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

  void _onPoolChange() => _loadStartups();

  InvestmentTicket? ticketById(String id) {
    for (final t in tickets) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Matches already worked out, by ticket (and what it holds).
  final Map<String, List<TicketMatch>> _matches = {};

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

  /// Why match matched ticket, for the top of the startup's profile.
  MatchSummary summaryOf(InvestmentTicket ticket, TicketMatch match) =>
      MatchSummary.forTicket(ticket.name, match.result);

  /// The startup a used ticket was used for.
  String usedForName(InvestmentTicket t) {
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

  final name = TextEditingController();
  final min = TextEditingController();
  final max = TextEditingController();
  final Set<String> sectors = {};

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
    if (!formOpen && editing == null) return;
    formOpen = false;
    editing = null;
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

  /// Add ticket / Save changes.
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

  /// Closes an open ticket.
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
      return true;
    } catch (_) {
      error = WalletStrings.saveFailed;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// A real date ("8 Nov 2026").
  String dateOf(DateTime? when) =>
      Formatters.dayMonthYear(when ?? _fixedNow?.call() ?? DateTime.now());

  @override
  void dispose() {
    _pool.changes.removeListener(_onPoolChange);
    for (final c in [name, min, max]) {
      c.removeListener(notifyListeners);
      c.dispose();
    }
    super.dispose();
  }
}
