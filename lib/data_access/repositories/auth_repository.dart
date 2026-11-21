import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';
import '../../models/auth_failure.dart';
import '../firebase_services/auth_service.dart';
import 'bookmark_repository.dart';
import 'not_interested_repository.dart';
import 'invitation_repository.dart';
import 'notice_repository.dart';
import 'startup_repository.dart';
import 'ticket_repository.dart';
import 'team_lookup.dart';
import 'user_repository.dart';

class SignupResult {
  const SignupResult({required this.verificationEmailSent});

  final bool verificationEmailSent;
}

enum ResendResult { sent, alreadyVerified }

/// All sign-up / log-in / log-out rules live here.
class AuthRepository {
  AuthRepository({AuthService? authService, UserRepository? userRepository})
    : _auth = authService ?? AuthService(),
      _users = userRepository ?? UserRepository();

  /// The app-wide instance.
  static AuthRepository instance = AuthRepository();

  final AuthService _auth;
  final UserRepository _users;

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

  /// Logs in and returns the user's profile.
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

  Future<void> discardUnverifiedAccount(String email, String password) async {
    final account = await _signInOrGeneric(email, password);
    if (account.emailVerified) {
      await _safeSignOut();
      throw const AuthException(AuthFailure.unknown);
    }
    try {
    try {
      await TicketRepository.instance.removeAllFor(account.uid);
    } catch (_) {
      // Carry on: the account itself must still be removed.
    }
    await _users.deleteProfile(account.uid);
    } catch (e) {
      debugPrint('Deleting the unverified profile failed: $e');
    }
    await _auth.deleteCurrentAccount();
    await _safeSignOut();
  }

  Future<void> updateUnverifiedProfile({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? city,
    String? bio,
    List<String> sectorsOfInterest = const [],
    String? sectorsOther,
    String? linkedin,
    String? gain,
    String? valueOffered,
    File? photo,
    bool removePhoto = false,
    bool emailPublic = false,
    bool phonePublic = false,
  }) async {
    final account = await _signInOrGeneric(email, password);
    try {
      await _users.updateProfile(
        uid: account.uid,
        fullName: fullName,
        bio: bio ?? '',
        phone: phone ?? '',
        sectorsOfInterest: sectorsOfInterest,
        city: city,
        sectorsOther: sectorsOther,
        linkedin: linkedin,
        gain: gain,
        valueOffered: valueOffered,
        emailPublic: emailPublic,
        phonePublic: phonePublic,
      );
      try {
        if (photo != null) {
          await _users
              .uploadProfilePhoto(account.uid, photo)
              .timeout(const Duration(seconds: 30));
        } else if (removePhoto) {
          // The photo is saved inside the public profile (no Storage).
          await _users.removeProfilePhoto(account.uid);
        }
      } catch (e) {
        debugPrint('Updating the profile photo failed: $e');
      }
    } finally {
      await _safeSignOut();
    }
  }

  /// Sends a new verification email.
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

  /// Sends a reset email.
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
      if (e.failure != AuthFailure.network) await _safeSignOut();
      return null;
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Changes the signed-in user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final account = _auth.currentAccount;
    if (account == null) throw const AuthException(AuthFailure.unknown);
    await _auth.reauthenticate(account.email, currentPassword);
    await _auth.updatePassword(newPassword);
  }

  // TODO(Sprint 2+): also delete the founder's requests and Investment
  // Associations once those collections exist (PBI 13).
  Future<void> deleteAccount({
    String? password,
    Map<String, StartupFate> fates = const {},
  }) async {
    final account = _auth.currentAccount;
    if (account == null) throw const AuthException(AuthFailure.unknown);
    if (password != null) {
      await _auth.reauthenticate(account.email, password);
    } else if (!_auth.signedInRecently) {
      throw const AuthException(AuthFailure.requiresRecentLogin);
    }
    await StartupRepository.instance.settleMineBeforeDeletion(fates);
    try {
      final invitations = InvitationRepository.instance;
      for (final i in await invitations.pendingForMe()) {
        await invitations.decline(i);
      }
    } catch (_) {
      // Carry on: they simply stay unanswered.
    }
    // Nobody can find or open a person who no longer exists.
    await TeamLookup.instance.remove(uid: account.uid, email: account.email);
    try {
      await BookmarkRepository.instance.deleteAll(account.uid);
      await NotInterestedRepository.instance.deleteAll(account.uid);
    } catch (_) {
      // Carry on: the account itself must still be removed.
    }
    // The notice inbox lives under the user document too.
    await NoticeRepository.instance.clearMine();
    await _users.deleteProfile(account.uid);
    await _auth.deleteCurrentAccount();
    await _safeSignOut();
  }

  Future<void> verifyPassword(String password) async {
    final account = _auth.currentAccount;
    if (account == null) throw const AuthException(AuthFailure.unknown);
    await _auth.reauthenticate(account.email, password);
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
    }
  }
}
