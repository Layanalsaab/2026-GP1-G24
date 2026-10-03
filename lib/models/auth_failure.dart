/// Everything that can go wrong in the auth flows, independent of Firebase.
enum AuthFailure {
  emailInUse,
  weakPassword,
  invalidEmail,
  invalidCredentials,
  emailNotVerified,
  profileMissing,
  profileSaveFailed,
  tooManyRequests,
  network,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException($failure)';
}
