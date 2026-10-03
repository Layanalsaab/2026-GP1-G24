import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';
import '../../models/auth_failure.dart';
import '../firebase_services/auth_service.dart';
import 'user_repository.dart';

class SignupResult {
  const SignupResult({required this.verificationEmailSent});

  /// False when the account was created but the verification email could not
  /// be sent. The user can still tap "Resend verification email".
  final bool verificationEmailSent;
}

enum ResendResult { sent, alreadyVerified }

/// All sign-up / log-in / log-out rules live here. Screens and view models
/// never talk to Firebase directly.
class AuthRepository {
  AuthRepository({AuthService? authService, UserRepository? userRepository})
      : _auth = authService ?? AuthService(),
        _users = userRepository ?? UserRepository();

  /// The app-wide instance. Tests replace it with a fake.
  static AuthRepository instance = AuthRepository();

  final AuthService _auth;
  final UserRepository _users;

  /// Creates the Auth account and the `users` profile, sends the verification
  /// email, then signs out. If the profile can't be saved, the Auth account is
  /// deleted so nobody is left with an account that has no role.
  Future<SignupResult> signUp({
    required String fullName,
    required String email,
    required String password,
    required AccountRole role,
  }) async {
    final account = await _auth.createAccount(email, password);

    try {
      await _users.createProfile(
        uid: account.uid,
        role: role,
        fullName: fullName,
        email: email,
      );
    } catch (e) {
      debugPrint('Saving the profile failed, removing the new account: $e');
      await _rollbackAccount();
      throw const AuthException(AuthFailure.profileSaveFailed);
    }

    var verificationEmailSent = true;
    try {
      await _auth.sendVerificationEmail();
    } catch (_) {
      verificationEmailSent = false;
    }
    await _safeSignOut();
    return SignupResult(verificationEmailSent: verificationEmailSent);
  }

  /// Logs in and returns the user's profile. Throws [AuthException] with
  /// [AuthFailure.invalidCredentials] for any wrong/missing email or password
  /// (never revealing which), and [AuthFailure.emailNotVerified] when the
  /// email isn't verified yet. In every failure case the user ends up signed out.
  Future<AppUser> logIn(String email, String password) async {
    final account = await _signInOrGeneric(email, password);

    if (!account.emailVerified) {
      await _safeSignOut();
      throw const AuthException(AuthFailure.emailNotVerified);
    }

    final AppUser? user;
    try {
      user = await _users.getProfile(account.uid);
    } catch (_) {
      await _safeSignOut();
      rethrow;
    }
    if (user == null) {
      await _safeSignOut();
      throw const AuthException(AuthFailure.profileMissing);
    }
    return user;
  }

  /// Sends a new verification email. Signing in is needed to send it, so the
  /// session is opened just long enough and always closed again.
  Future<ResendResult> resendVerification(String email, String password) async {
    final account = await _signInOrGeneric(email, password);
    try {
      if (account.emailVerified) return ResendResult.alreadyVerified;
      await _auth.sendVerificationEmail();
      return ResendResult.sent;
    } finally {
      await _safeSignOut();
    }
  }

  /// Sends a reset email. Unknown emails are silently ignored so the app never
  /// reveals which emails are registered; only network / rate-limit problems
  /// are reported.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
    } on AuthException catch (e) {
      if (e.failure == AuthFailure.network ||
          e.failure == AuthFailure.tooManyRequests) {
        rethrow;
      }
    }
  }

  /// The user to open on app launch, or null when there is no verified,
  /// signed-in user with a profile.
  Future<AppUser?> restoreSession() async {
    try {
      final account = await _auth.reloadCurrentAccount();
      if (account == null) return null;
      if (!account.emailVerified) {
        await _safeSignOut();
        return null;
      }
      final user = await _users.getProfile(account.uid);
      if (user == null) await _safeSignOut();
      return user;
    } on AuthException catch (e) {
      // Offline at launch: keep the session, just don't auto-open it.
      if (e.failure != AuthFailure.network) await _safeSignOut();
      return null;
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<AuthAccount> _signInOrGeneric(String email, String password) async {
    try {
      return await _auth.signIn(email, password);
    } on AuthException catch (e) {
      if (e.failure == AuthFailure.invalidEmail) {
        throw const AuthException(AuthFailure.invalidCredentials);
      }
      rethrow;
    }
  }

  Future<void> _rollbackAccount() async {
    try {
      await _auth.deleteCurrentAccount();
    } catch (_) {
      await _safeSignOut();
    }
  }

  Future<void> _safeSignOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Nothing more we can do; the caller is already handling a failure.
    }
  }
}
