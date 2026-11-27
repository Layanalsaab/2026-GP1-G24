import '../app_constants/firestore_collections.dart';

/// Where an investment ticket stands.
enum TicketStatus {
  open(TicketFields.open, 'Open'),
  closed(TicketFields.closed, 'Closed'),
  used(TicketFields.used, 'Used');

  const TicketStatus(this.value, this.label);

  final String value;
  final String label;

  static TicketStatus fromValue(Object? raw) {
    for (final s in values) {
      if (s.value == raw) return s;
    }
    return TicketStatus.open;
  }
}

/// An investor's investment ticket: a document of tickets/{investorId}-T{n}.
class InvestmentTicket {
  const InvestmentTicket({
    required this.id,
    required this.investorId,
    required this.name,
    required this.sectors,
    required this.stages,
    required this.amountMin,
    required this.amountMax,
    this.status = TicketStatus.open,
    this.startupId,
    this.createdAt,
  });

  final String id;
  final String investorId;
  final String name;

  /// Sector labels ("Logistics", "E-commerce").
  final List<String> sectors;

  /// Stage labels ("Pre-seed", "Seed").
  final List<String> stages;
  final int amountMin;
  final int amountMax;
  final TicketStatus status;

  /// The startup the ticket was used for (status TicketStatus.used).
  final String? startupId;
  final DateTime? createdAt;

  bool get isOpen => status == TicketStatus.open;

  /// 3 for abc-T3; 0 when the id has no number.
  int get number => numberOf(id);

  static int numberOf(String id) {
    final at = id.lastIndexOf('-T');
    if (at < 0) return 0;
    return int.tryParse(id.substring(at + 2)) ?? 0;
  }

  InvestmentTicket copyWith({
    String? name,
    List<String>? sectors,
    List<String>? stages,
    int? amountMin,
    int? amountMax,
    TicketStatus? status,
  }) => InvestmentTicket(
    id: id,
    investorId: investorId,
    name: name ?? this.name,
    sectors: sectors ?? this.sectors,
    stages: stages ?? this.stages,
    amountMin: amountMin ?? this.amountMin,
    amountMax: amountMax ?? this.amountMax,
    status: status ?? this.status,
    startupId: startupId,
    createdAt: createdAt,
  );

  Map<String, Object?> editableFields() => {
    TicketFields.name: name,
    TicketFields.sectors: sectors,
    TicketFields.stages: stages,
    TicketFields.amountMin: amountMin,
    TicketFields.amountMax: amountMax,
  };

  /// Null for a document the app can't show.
  static InvestmentTicket? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final investor = data[TicketFields.investorId];
    final name = data[TicketFields.name];
    final min = data[TicketFields.amountMin];
    final max = data[TicketFields.amountMax];
    if (investor is! String || name is! String) return null;
    if (min is! num || max is! num) return null;
    List<String> strings(Object? raw) => raw is List
        ? [
            for (final v in raw)
              if (v is String && v.trim().isNotEmpty) v.trim(),
          ]
        : const [];
    final created = data[TicketFields.createdAt];
    final startup = data[TicketFields.startupId];
    return InvestmentTicket(
      id: id,
      investorId: investor,
      name: name.trim(),
      sectors: strings(data[TicketFields.sectors]),
      stages: strings(data[TicketFields.stages]),
      amountMin: min.round(),
      amountMax: max.round(),
      status: TicketStatus.fromValue(data[TicketFields.status]),
      startupId: startup is String && startup.isNotEmpty ? startup : null,
      createdAt: created is DateTime ? created : null,
    );
  }
}
