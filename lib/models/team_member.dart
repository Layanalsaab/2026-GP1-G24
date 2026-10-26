/// One person in a startup's team (Startup Team step, Team tab on the
/// startup profile). Stored inside the startup document as a map.
class TeamMember {
  const TeamMember({
    required this.name,
    required this.role,
    required this.contribution,
    this.email = '',
    this.coFounder = false,
    this.invited = false,
    this.isFounder = false,
    this.uid,
    this.photoData,
  });

  static const nameMax = 50;
  static const roleMax = 40;
  static const emailMax = 100;
  static const contributionMax = 300;

  final String name;

  /// Lower-case, trimmed. Empty on older startups.
  final String email;

  /// e.g. "CTO".
  final String role;

  /// What this person brings to the startup.
  final String contribution;

  /// Co-founders can edit the startup; other members can only view it.
  final bool coFounder;

  /// Added by an email that is not (yet) a Start.sa account.
  final bool invited;

  /// The startup's founder: always the first member.
  final bool isFounder;

  /// The account this person is, once it is linked. A linked member shows
  /// the account's CURRENT name (it follows Edit profile); an unlinked one
  /// shows the typed text.
  final String? uid;

  /// The person's photo (base64), read from their public profile when a team is
  /// shown. Never stored on the startup (null: the default picture).
  final String? photoData;

  TeamMember copyWith({
    String? name,
    String? email,
    String? role,
    String? contribution,
    bool? coFounder,
    bool? invited,
    bool? isFounder,
    String? uid,
    String? photoData,
  }) => TeamMember(
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    contribution: contribution ?? this.contribution,
    coFounder: coFounder ?? this.coFounder,
    invited: invited ?? this.invited,
    isFounder: isFounder ?? this.isFounder,
    uid: uid ?? this.uid,
    photoData: photoData ?? this.photoData,
  );

  /// The sub-line on a team row: the role.
  String get meta => role;

  /// Two letters for the avatar (first letter of the first and last word).
  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final list = words.toList();
    if (list.isEmpty) return '?';
    final first = String.fromCharCode(list.first.runes.first);
    if (list.length == 1) {
      final runes = list.first.runes.toList();
      return (first + (runes.length > 1 ? String.fromCharCode(runes[1]) : ''))
          .toUpperCase();
    }
    return (first + String.fromCharCode(list.last.runes.first)).toUpperCase();
  }

  Map<String, Object?> toMap() => {
    'fullName': name,
    'email': email,
    'role': role,
    'contribution': contribution,
    'coFounder': coFounder,
    'invited': invited,
    'isFounder': isFounder,
    if (uid != null) 'uid': uid,
  };

  static TeamMember? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['fullName'] ?? raw['name'];
    final role = raw['role'];
    if (name is! String || role is! String) return null;
    return TeamMember(
      name: name,
      email: ((raw['email'] as String?) ?? '').trim().toLowerCase(),
      role: role,
      // Older startups kept a "short bio" here.
      contribution:
          ((raw['contribution'] ?? raw['shortBio'] ?? raw['bio']) as String?) ??
          '',
      coFounder: raw['coFounder'] == true,
      invited: raw['invited'] == true,
      isFounder: raw['isFounder'] == true,
      uid: raw['uid'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TeamMember &&
      other.name == name &&
      other.email == email &&
      other.role == role &&
      other.contribution == contribution &&
      other.coFounder == coFounder &&
      other.invited == invited &&
      other.isFounder == isFounder &&
      other.uid == uid;

  @override
  int get hashCode => Object.hash(
    name,
    email,
    role,
    contribution,
    coFounder,
    invited,
    isFounder,
    uid,
  );
}
