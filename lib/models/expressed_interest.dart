/// A guest's "Express interest" in a startup (Manage startup -> Interest).
class ExpressedInterest {
  const ExpressedInterest({
    required this.id,
    required this.startupId,
    required this.name,
    required this.roleLine,
    required this.message,
    this.seenByFounder = false,
    this.createdAt,
    this.whenLabel,
  });

  final String id;
  final String startupId;
  final String name;

  /// "Registered nurse", "Startup seeker".
  final String roleLine;
  final String message;
  final bool seenByFounder;
  final DateTime? createdAt;

  /// "1h ago" / "4d ago" for sample data that has no real timestamp.
  final String? whenLabel;

  bool get isNew => !seenByFounder;

  ExpressedInterest markSeen() => ExpressedInterest(
    id: id,
    startupId: startupId,
    name: name,
    roleLine: roleLine,
    message: message,
    seenByFounder: true,
    createdAt: createdAt,
    whenLabel: whenLabel,
  );
}
