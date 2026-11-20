class StartupNotice {
  const StartupNotice({
    this.id = '',
    required this.type,
    required this.startupId,
    required this.startupName,
    this.person = '',
    this.stay,
    this.createdAt,
  });

  static const closed = 'closed';

  /// The startup was deleted: to its team.
  static const deleted = 'deleted';

  /// The startup was handed to the reader: they are its founder now.
  static const newFounder = 'newFounder';

  /// The startup got a new founder (person): to the rest of its team.
  static const founderChanged = 'founderChanged';

  static const handedOver = 'handedOver';

  static const declined = 'declined';

  /// The founder removed the reader from the team.
  static const removed = 'removed';

  /// A member (person) left the team: to its founder.
  static const left = 'left';

  static const types = [
    closed,
    deleted,
    newFounder,
    founderChanged,
    handedOver,
    declined,
    removed,
    left,
  ];

  final String id;
  final String type;
  final String startupId;

  /// The name when it happened (a deleted startup can't be read any more).
  final String startupName;

  /// Who it is about (a name, or an e-mail for declined); empty if none.
  final String person;

  /// For handedOver: coFounder, member, or null (left for good).
  final String? stay;
  final DateTime? createdAt;

  /// Whether the reader can still open the startup from the pop-up.
  bool get canView => type != deleted && type != removed && type != declined;

  Map<String, Object?> toMap() => {
    'type': type,
    'startupId': startupId,
    'startupName': startupName,
    if (person.isNotEmpty) 'person': person,
    if (stay != null) 'stay': stay,
  };

  static StartupNotice? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final type = data['type'];
    final startupId = data['startupId'];
    if (type is! String || !types.contains(type) || startupId is! String) {
      return null;
    }
    return StartupNotice(
      id: id,
      type: type,
      startupId: startupId,
      startupName: (data['startupName'] as String?) ?? '',
      person: (data['person'] as String?) ?? '',
      stay: data['stay'] as String?,
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : null,
    );
  }
}
