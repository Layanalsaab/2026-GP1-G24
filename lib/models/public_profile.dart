import 'startup.dart';

/// One startup a person belongs to, as listed on their profile.
class ProfileStartupRef {
  const ProfileStartupRef({
    required this.id,
    required this.name,
    required this.role,
    this.startup,
  });

  final String id;
  final String name;

  /// The startup itself, when it was loaded for the profile (so it can be
  /// shown as a full card). Never stored.
  final Startup? startup;

  /// `founder`, `coFounder` or `member`.
  final String role;

  static ProfileStartupRef? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    if (id is! String || name is! String) return null;
    return ProfileStartupRef(
      id: id,
      name: name,
      role: (raw['role'] as String?) ?? 'member',
    );
  }

  Map<String, Object?> toMap() => {'id': id, 'name': name, 'role': role};
}

/// The public face of an account (Firestore `publicProfiles/{id}`): always
/// public. The e-mail and the phone are in it ONLY when the person made that
/// one Public (each on its own).
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.fullName,
    this.role = 'founder',
    this.city = '',
    this.bio = '',
    this.sectors = const [],
    this.linkedin = '',
    this.photoUrl,
    this.photoData,
    this.email,
    this.phone,
    this.emailPublic = false,
    this.phonePublic = false,
    this.startups = const [],
    this.isSample = false,
  });

  final String id;
  final String fullName;
  final String role;
  final String city;
  final String bio;
  final List<String> sectors;
  final String linkedin;
  final String? photoUrl;

  /// The photo as base64 text (null: the initials show).
  final String? photoData;

  /// Present only when [emailPublic] / [phonePublic].
  final String? email;
  final String? phone;
  final bool emailPublic;
  final bool phonePublic;

  /// The startups stored on the profile (sample profiles). Real accounts get
  /// theirs from the startups themselves.
  final List<ProfileStartupRef> startups;
  final bool isSample;

  bool get isFounder => role != 'investor';

  /// Two letters for the avatar.
  String get initials {
    final words = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final a = String.fromCharCode(words.first.runes.first);
    if (words.length == 1) {
      final r = words.first.runes.toList();
      return (a + (r.length > 1 ? String.fromCharCode(r[1]) : ''))
          .toUpperCase();
    }
    return (a + String.fromCharCode(words.last.runes.first)).toUpperCase();
  }

  static PublicProfile? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final name = data['fullName'];
    if (name is! String || name.trim().isEmpty) return null;
    final sectors = data['sectorsOfInterest'] ?? data['sectors'];
    final emailPublic = data['emailPublic'] == true;
    final phonePublic = data['phonePublic'] == true;
    return PublicProfile(
      id: id,
      fullName: name,
      role: (data['role'] as String?) ?? 'founder',
      city: (data['city'] as String?) ?? '',
      bio: ((data['bio'] ?? data['about']) as String?) ?? '',
      sectors: [
        if (sectors is List)
          for (final s in sectors)
            if (s is String && s.trim().isNotEmpty) s,
      ],
      linkedin: ((data['linkedinUrl'] ?? data['linkedin']) as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      photoData: (data['photoData'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['photoData'] as String?,
      // Never trust a field whose switch is off.
      email: emailPublic ? data['email'] as String? : null,
      phone: phonePublic ? data['phone'] as String? : null,
      emailPublic: emailPublic,
      phonePublic: phonePublic,
      startups: [
        if (data['startups'] is List)
          for (final r in data['startups'] as List)
            ?ProfileStartupRef.fromMap(r),
      ],
      isSample: data['isSample'] == true,
    );
  }
}
