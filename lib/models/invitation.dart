/// Where an invitation stands.
enum InvitationStatus {
  /// Sent, waiting for the person.
  pending('pending'),

  /// The person joined the team.
  accepted('accepted'),

  declined('declined'),

  /// The team cancelled it (removed the person before they joined).
  cancelled('cancelled');

  const InvitationStatus(this.value);

  final String value;

  static InvitationStatus fromValue(Object? raw) => values.firstWhere(
    (s) => s.value == raw,
    orElse: () => InvitationStatus.pending,
  );
}

/// An invitation to join a startup's team (Firestore invitations/{id}).
class Invitation {
  const Invitation({
    required this.startupId,
    required this.startupName,
    required this.emailLower,
    required this.role,
    required this.invitedBy,
    this.roleText = '',
    this.contribution = '',
    this.invitedByName = '',
    this.status = InvitationStatus.pending,
    this.emailSent = false,
    this.acceptedBy,
    this.acceptedByName = '',
    this.newUser = false,
    this.createdAt,
    this.previousFounderRole,
  });

  static const roleCoFounder = 'coFounder';
  static const roleMember = 'member';
  static const roleOwner = 'owner';

  final String startupId;
  final String startupName;
  final String emailLower;
  final String role;
  final String roleText;
  final String contribution;
  final String invitedBy;
  final String invitedByName;
  final InvitationStatus status;

  /// True once the e-mail really left (the relay said so).
  final bool emailSent;

  /// The account that accepted (set when status is accepted).
  final String? acceptedBy;

  final String acceptedByName;

  final bool newUser;

  /// When the invitation was made (the server time).
  final DateTime? createdAt;

  final String? previousFounderRole;

  static const ownerValidFor = Duration(days: 30);

  DateTime? get expiresAt =>
      isOwner && createdAt != null ? createdAt!.add(ownerValidFor) : null;

  /// A pending owner invitation that was not answered in time.
  bool isExpired(DateTime now) =>
      isPending && expiresAt != null && now.isAfter(expiresAt!);

  /// Whole days left of an owner invitation (0 = today), or null.
  int? daysLeft(DateTime now) {
    final end = expiresAt;
    if (end == null) return null;
    final left = end.difference(now);
    if (left.isNegative) return 0;
    return (left.inHours / 24).floor();
  }

  bool get isCoFounder => role == roleCoFounder;
  bool get isOwner => role == roleOwner;
  bool get isPending => status == InvitationStatus.pending;

  String get id => idOf(startupId, emailLower);

  static String idOf(String startupId, String email) =>
      '$startupId~${email.trim().toLowerCase()}';

  Map<String, Object?> toCreateMap() => {
    'startupId': startupId,
    'startupName': startupName,
    'emailLower': emailLower,
    'role': role,
    'roleText': roleText,
    'contribution': contribution,
    'invitedBy': invitedBy,
    'invitedByName': invitedByName,
    'status': InvitationStatus.pending.value,
    'emailSent': false,
    'newUser': newUser,
    'previousFounderRole': ?previousFounderRole,
  };

  static Invitation? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final startupId = data['startupId'];
    final email = data['emailLower'];
    final role = data['role'];
    final by = data['invitedBy'];
    if (startupId is! String ||
        email is! String ||
        role is! String ||
        by is! String) {
      return null;
    }
    return Invitation(
      startupId: startupId,
      startupName: (data['startupName'] as String?) ?? '',
      emailLower: email,
      role: role,
      roleText: (data['roleText'] as String?) ?? '',
      contribution: (data['contribution'] as String?) ?? '',
      invitedBy: by,
      invitedByName: (data['invitedByName'] as String?) ?? '',
      status: InvitationStatus.fromValue(data['status']),
      emailSent: data['emailSent'] == true,
      acceptedBy: data['acceptedBy'] as String?,
      acceptedByName: (data['acceptedByName'] as String?) ?? '',
      newUser: data['newUser'] == true,
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : null,
      previousFounderRole: switch (data['previousFounderRole']) {
        final String r when r == roleCoFounder || r == roleMember => r,
        _ => null,
      },
    );
  }
}
