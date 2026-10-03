import 'package:firebase_auth/firebase_auth.dart';

import '../../models/auth_failure.dart';

/// The signed-in Firebase account, without leaking Firebase types.
class AuthAccount {
  const AuthAccount({
    required this.uid,
    required this.email,
    required this.emailVerified,
  });

  final String uid;
  final String email;
  final bool emailVerified;
}

/// Firebase Authentication. The only code that talks to `FirebaseAuth`.
/// Every Firebase error is translated into an [AuthException].
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  AuthAccount? get currentAccount => _toAccount(_auth.currentUser);

  Future<AuthAccount> createAccount(String email, String password) => _guard(
        () async {
          final credential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          return _toAccount(credential.user)!;
        },
      );

  /// Signs in and returns fresh account data (including `emailVerified`).
  Future<AuthAccount> signIn(String email, String password) => _guard(() async {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = credential.user!;
        await user.reload();
        return _toAccount(_auth.currentUser ?? user)!;
      });

  /// Refreshes the signed-in user from the server. Null when nobody is signed in.
  Future<AuthAccount?> reloadCurrentAccount() => _guard(() async {
        final user = _auth.currentUser;
        if (user == null) return null;
        await user.reload();
        return _toAccount(_auth.currentUser);
      });

  Future<void> sendVerificationEmail() => _guard(() async {
        final user = _auth.currentUser;
        if (user == null) throw const AuthException(AuthFailure.unknown);
        await user.sendEmailVerification();
      });

  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));

  Future<void> deleteCurrentAccount() => _guard(() async {
        await _auth.currentUser?.delete();
      });

  Future<void> signOut() => _guard(_auth.signOut);

  AuthAccount? _toAccount(User? user) {
    if (user == null) return null;
    return AuthAccount(
      uid: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_failureFor(e.code));
    }
  }

  AuthFailure _failureFor(String code) {
    switch (code) {
      case 'email-already-in-use':
        return AuthFailure.emailInUse;
      case 'weak-password':
        return AuthFailure.weakPassword;
      case 'invalid-email':
        return AuthFailure.invalidEmail;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'user-disabled':
        return AuthFailure.invalidCredentials;
      case 'too-many-requests':
        return AuthFailure.tooManyRequests;
      case 'network-request-failed':
        return AuthFailure.network;
      default:
        return AuthFailure.unknown;
    }
  }
}
