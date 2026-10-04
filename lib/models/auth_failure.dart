/// Everything that can go wrong in the auth flows and data access,
/// independent of Firebase.
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

  /// Firestore/Storage refused the request (security rules), or nobody is
  /// signed in when an action needs an account.
  permissionDenied,

  /// The document or file no longer exists (e.g. deleted on another device).
  notFound,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException($failure)';
}
