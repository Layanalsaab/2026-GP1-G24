/// Where an invitation stands.
enum InvitationStatus {
  /// Sent, waiting for the person.
  pending('pending'),

  /// The person joined the team.
  accepted('accepted'),

  /// The person said no (or signed up as an investor and chose not to join).
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

/// An invitation to join a startup's team (Firestore `invitations/{id}`).
///
/// The id is `startupId~email` (the e-mail lower-case), so there is one
/// invitation per startup and e-mail. The e-mail address is what links the
/// invitation to the person: whoever signs in with a VERIFIED account of that
/// e-mail can accept it.
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
    this.lastSentAt,
    this.acceptedBy,
  });

  /// `coFounder` or `member` (the same words as `Startup.memberRoles`).
  static const roleCoFounder = 'coFounder';
  static const roleMember = 'member';

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
  final DateTime? lastSentAt;

  /// The account that accepted (set when [status] is accepted).
  final String? acceptedBy;

  bool get isCoFounder => role == roleCoFounder;
  bool get isPending => status == InvitationStatus.pending;

  String get id => idOf(startupId, emailLower);

  static String idOf(String startupId, String email) =>
      '$startupId~${email.trim().toLowerCase()}';

  /// What a founder can resend: nothing was sent yet, or an hour has passed.
  bool canResend(DateTime now) =>
      isPending &&
      (lastSentAt == null ||
          now.difference(lastSentAt!) >= const Duration(hours: 1));

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
      lastSentAt: data['lastSentAt'] as DateTime?,
      acceptedBy: data['acceptedBy'] as String?,
    );
  }
}
