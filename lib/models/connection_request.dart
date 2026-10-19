/// Where an investor's request to a startup stands.
enum RequestStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined');

  const RequestStatus(this.value);

  final String value;

  static RequestStatus fromValue(Object? raw) {
    for (final s in values) {
      if (s.value == raw) return s;
    }
    return RequestStatus.pending;
  }
}

/// An investor's request to invest in a startup (Manage startup -> Requests).
/// Accepting it makes the investor an "associated investor" of the startup.
class ConnectionRequest {
  const ConnectionRequest({
    required this.id,
    required this.startupId,
    required this.investorId,
    required this.message,
    required this.amount,
    required this.equityPercent,
    required this.status,
    this.founderId,
    this.createdAt,
    this.whenLabel,
  });

  final String id;
  final String startupId;
  final String? founderId;
  final String investorId;

  /// What the investor wrote ("I like the traction in Riyadh...").
  final String message;

  /// The offered amount in SAR.
  final int amount;

  /// The equity asked for, in percent (15 means 15 %).
  final double equityPercent;
  final RequestStatus status;
  final DateTime? createdAt;

  /// "2h ago" / "3d ago" for sample data that has no real timestamp.
  final String? whenLabel;

  /// "SAR 300,000 for 15%".
  String get offerLabel {
    final eq = equityPercent == equityPercent.roundToDouble()
        ? equityPercent.toStringAsFixed(0)
        : equityPercent.toString();
    return 'SAR ${_thousands(amount)} for $eq%';
  }

  static String _thousands(int v) {
    final digits = v.abs().toString();
    final b = StringBuffer(v < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
      b.write(digits[i]);
    }
    return b.toString();
  }

  ConnectionRequest copyWith({RequestStatus? status}) => ConnectionRequest(
    id: id,
    startupId: startupId,
    founderId: founderId,
    investorId: investorId,
    message: message,
    amount: amount,
    equityPercent: equityPercent,
    status: status ?? this.status,
    createdAt: createdAt,
    whenLabel: whenLabel,
  );
}
