/// One person in a startup's team (Add startup step 3, Team tab on the
/// startup profile). Stored inside the startup document as a map.
class TeamMember {
  const TeamMember({
    required this.name,
    required this.role,
    required this.specialization,
    required this.yearsExperience,
    required this.bio,
    this.uid,
  });

  static const nameMax = 50;
  static const roleMax = 40;
  static const specializationMax = 60;
  static const yearsMaxDigits = 2;
  static const bioMax = 1000;

  final String name;

  /// e.g. "CTO".
  final String role;

  /// e.g. "Mobile and cloud".
  final String specialization;
  final int yearsExperience;
  final String bio;

  /// The account this person is, once it is linked. A linked member shows
  /// the account's CURRENT name (it follows Edit profile); an unlinked one
  /// shows the typed text.
  final String? uid;

  TeamMember copyWith({String? name, String? uid}) => TeamMember(
    name: name ?? this.name,
    role: role,
    specialization: specialization,
    yearsExperience: yearsExperience,
    bio: bio,
    uid: uid ?? this.uid,
  );

  /// "CTO · 10 yrs · Mobile and cloud" (the sub-line on a team row).
  String get meta => '$role · $yearsExperience yrs · $specialization';

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
    'role': role,
    'specialization': specialization,
    'yearsOfExperience': yearsExperience,
    'shortBio': bio,
    if (uid != null) 'uid': uid,
  };

  static TeamMember? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['fullName'] ?? raw['name'];
    final role = raw['role'];
    if (name is! String || role is! String) return null;
    return TeamMember(
      name: name,
      role: role,
      specialization: (raw['specialization'] as String?) ?? '',
      yearsExperience:
          ((raw['yearsOfExperience'] ?? raw['yearsExperience']) as num?)
              ?.toInt() ??
          0,
      bio: ((raw['shortBio'] ?? raw['bio']) as String?) ?? '',
      uid: raw['uid'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TeamMember &&
      other.name == name &&
      other.role == role &&
      other.specialization == specialization &&
      other.yearsExperience == yearsExperience &&
      other.bio == bio;

  @override
  int get hashCode =>
      Object.hash(name, role, specialization, yearsExperience, bio);
}
