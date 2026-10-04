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

  AppUser copyWith({
    String? fullName,
    String? city,
    String? bio,
    bool? onboardingCompleted,
  }) =>
      AppUser(
        uid: uid,
        role: role,
        fullName: fullName ?? this.fullName,
        email: email,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        city: city ?? this.city,
        bio: bio ?? this.bio,
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
    );
  }
}
