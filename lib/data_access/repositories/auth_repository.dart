import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';
import '../../models/auth_failure.dart';
import '../firebase_services/auth_service.dart';
import 'startup_repository.dart';
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
    String? phone,
    String? city,
    String? bio,
    List<String> sectorsOfInterest = const [],
    String? sectorsOther,
    String? linkedin,
    String? gain,
    String? valueOffered,
    File? photo,
    bool emailPublic = false,
    bool phonePublic = false,
  }) async {
    final account = await _auth.createAccount(email, password);

    try {
      await _users.createProfile(
        uid: account.uid,
        role: role,
        fullName: fullName,
        email: email,
        phone: phone,
        city: city,
        bio: bio,
        sectorsOfInterest: sectorsOfInterest,
        sectorsOther: sectorsOther,
        linkedin: linkedin,
        gain: gain,
        valueOffered: valueOffered,
        emailPublic: emailPublic,
        phonePublic: phonePublic,
      );
    } catch (e) {
      debugPrint('Saving the profile failed, removing the new account: $e');
      await _rollbackAccount();
      throw const AuthException(AuthFailure.profileSaveFailed);
    }

    // The photo is optional: a failed upload never fails the sign-up.
    if (photo != null) {
      try {
        await _users
            .uploadProfilePhoto(account.uid, photo)
            .timeout(const Duration(seconds: 30));
      } catch (e) {
        debugPrint('Uploading the profile photo failed: $e');
      }
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

  /// Sign-up step 2 when the user went back and changed the email: signs in
  /// with the old, still unverified credentials and deletes that account and
  /// its profile, so a new one can be created. A verified account is never
  /// deleted (it throws [AuthFailure.unknown] instead).
  Future<void> discardUnverifiedAccount(String email, String password) async {
    final account = await _signInOrGeneric(email, password);
    if (account.emailVerified) {
      await _safeSignOut();
      throw const AuthException(AuthFailure.unknown);
    }
    try {
      await _users.deleteProfile(account.uid);
    } catch (e) {
      debugPrint('Deleting the unverified profile failed: $e');
    }
    await _auth.deleteCurrentAccount();
    await _safeSignOut();
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

  /// Changes the signed-in user's password. The current password is checked
  /// first; a wrong one fails with [AuthFailure.invalidCredentials] and nothing
  /// changes.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final account = _auth.currentAccount;
    if (account == null) throw const AuthException(AuthFailure.unknown);
    await _auth.reauthenticate(account.email, currentPassword);
    await _auth.updatePassword(newPassword);
  }

  /// Permanently deletes the signed-in user: checks the password, deletes the
  /// `users` profile, then the Auth account, and signs out.
  ///
  /// The profile is deleted first because the security rules only let a
  /// signed-in user delete their own document. If any step fails, the steps
  /// after it don't run, so a wrong password deletes nothing.
  // TODO(Sprint 2+): also delete the founder's startups, requests and
  // Investment Associations once those collections exist (PBI 13).
  ///
  /// Without a [password] the account is deleted straight away when the user
  /// signed in a moment ago; otherwise it throws
  /// [AuthFailure.requiresRecentLogin] before anything is removed, and the
  /// caller asks for the password once and calls again with it.
  Future<void> deleteAccount({String? password}) async {
    final account = _auth.currentAccount;
    if (account == null) throw const AuthException(AuthFailure.unknown);
    if (password != null) {
      await _auth.reauthenticate(account.email, password);
    } else if (!_auth.signedInRecently) {
      throw const AuthException(AuthFailure.requiresRecentLogin);
    }
    // A founder's startups go with the account, so none stay public.
    try {
      await StartupRepository.instance.deleteAllMine();
    } catch (_) {
      // Carry on: the account itself must still be removed.
    }
    await _users.deleteProfile(account.uid);
    await _auth.deleteCurrentAccount();
    await _safeSignOut();
  }

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
