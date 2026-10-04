/// Roles that have an account. Startup seekers never have one.
enum AccountRole {
  founder('founder'),
  investor('investor');

  const AccountRole(this.value);

  /// The string stored in Firestore (`users/{uid}.role`).
  final String value;

  static AccountRole? fromValue(Object? value) {
    for (final role in AccountRole.values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

/// A signed-up user's profile, stored in `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.fullName,
    required this.email,
    this.onboardingCompleted = false,
    this.city,
    this.bio = '',
    this.preferredSectors = const [],
    this.preferredStages = const [],
    this.ticketSize,
  });

  final String uid;
  final AccountRole role;
  final String fullName;
  final String email;

  /// True once the user has finished their role's onboarding questions.
  /// Missing in older profiles, which counts as not completed.
  final bool onboardingCompleted;

  /// Where the user is based. Null until they choose one.
  final String? city;

  /// A short "about me" text. Empty when the user hasn't written one.
  final String bio;

  /// Investors only: the sectors and stages they invest in (one or more of
  /// each) and their typical ticket size. Empty / null until they answer the
  /// investor onboarding.
  final List<String> preferredSectors;
  final List<String> preferredStages;
  final String? ticketSize;

  AppUser copyWith({
    String? fullName,
    String? city,
    String? bio,
    bool? onboardingCompleted,
    List<String>? preferredSectors,
    List<String>? preferredStages,
    String? ticketSize,
  }) =>
      AppUser(
        uid: uid,
        role: role,
        fullName: fullName ?? this.fullName,
        email: email,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        city: city ?? this.city,
        bio: bio ?? this.bio,
        preferredSectors: preferredSectors ?? this.preferredSectors,
        preferredStages: preferredStages ?? this.preferredStages,
        ticketSize: ticketSize ?? this.ticketSize,
      );

  /// Returns null when the document is missing a valid role, so callers never
  /// treat a half-created profile as a usable account.
  static AppUser? fromMap(String uid, Map<String, dynamic>? data) {
    if (data == null) return null;
    final role = AccountRole.fromValue(data['role']);
    if (role == null) return null;
    return AppUser(
      uid: uid,
      role: role,
      fullName: (data['fullName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      onboardingCompleted: data['onboardingCompleted'] == true,
      city: data['city'] as String?,
      bio: (data['bio'] as String?) ?? '',
      preferredSectors: _strings(data['preferredSectors']),
      preferredStages: _strings(data['preferredStages']),
      ticketSize: data['ticketSize'] as String?,
    );
  }

  /// A Firestore list as a list of strings (anything else is ignored).
  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}
