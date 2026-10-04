import 'dart:io';

import 'package:startsa/data_access/firebase_services/auth_service.dart';
import 'package:startsa/data_access/repositories/app_settings_repository.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';
import 'package:startsa/models/startup.dart';

/// In-memory stand-in for [AuthService]. Set the fields to script behaviour,
/// and read [calls] to see what the code under test did.
class FakeAuthService implements AuthService {
  final List<String> calls = [];

  /// The account that is currently signed in, if any.
  AuthAccount? signedIn;

  /// What [createAccount] / [signIn] / [reloadCurrentAccount] return.
  AuthAccount account = const AuthAccount(
    uid: 'uid1',
    email: 'a@b.co',
    emailVerified: false,
  );

  AuthFailure? createFails;
  AuthFailure? signInFails;
  AuthFailure? reloadFails;
  AuthFailure? sendVerificationFails;
  AuthFailure? resetFails;
  bool deleteFails = false;

  @override
  AuthAccount? get currentAccount => signedIn;

  @override
  Future<AuthAccount> createAccount(String email, String password) async {
    calls.add('createAccount');
    if (createFails != null) throw AuthException(createFails!);
    signedIn = account;
    return account;
  }

  @override
  Future<AuthAccount> signIn(String email, String password) async {
    calls.add('signIn');
    if (signInFails != null) throw AuthException(signInFails!);
    signedIn = account;
    return account;
  }

  @override
  Future<AuthAccount?> reloadCurrentAccount() async {
    calls.add('reload');
    if (reloadFails != null) throw AuthException(reloadFails!);
    return signedIn;
  }

  @override
  Future<void> sendVerificationEmail() async {
    calls.add('sendVerification');
    if (sendVerificationFails != null) {
      throw AuthException(sendVerificationFails!);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('sendReset');
    if (resetFails != null) throw AuthException(resetFails!);
  }

  @override
  Future<void> deleteCurrentAccount() async {
    calls.add('delete');
    if (deleteFails) throw const AuthException(AuthFailure.unknown);
    signedIn = null;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    signedIn = null;
  }
}

/// In-memory stand-in for [UserRepository].
class FakeUserRepository implements UserRepository {
  final Map<String, AppUser> profiles = {};
  bool createFails = false;
  AuthFailure? getFails;

  @override
  Future<void> createProfile({
    required String uid,
    required AccountRole role,
    required String fullName,
    required String email,
  }) async {
    if (createFails) throw const AuthException(AuthFailure.unknown);
    profiles[uid] = AppUser(
      uid: uid,
      role: role,
      fullName: fullName,
      email: email,
    );
  }

  @override
  Future<AppUser?> getProfile(String uid) async {
    if (getFails != null) throw AuthException(getFails!);
    return profiles[uid];
  }

  int onboardingSaves = 0;
  AuthFailure? onboardingFails;
  Map<String, String>? savedOnboarding;

  @override
  Future<void> saveFounderOnboarding({
    required String uid,
    required String sector,
    required String stage,
    required String city,
  }) async {
    onboardingSaves++;
    if (onboardingFails != null) throw AuthException(onboardingFails!);
    savedOnboarding = {'sector': sector, 'stage': stage, 'city': city};
  }
}

/// Scriptable [AuthRepository] for view-model and widget tests.
class FakeAuthRepository implements AuthRepository {
  int signUpCalls = 0;
  int logInCalls = 0;
  int resendCalls = 0;
  int resetCalls = 0;
  int signOutCalls = 0;

  /// If set, the next call waits for this future (to test loading states).
  Future<void>? gate;

  AuthFailure? signUpFails;
  AuthFailure? logInFails;
  AuthFailure? resendFails;
  AuthFailure? resetFails;
  bool verificationEmailSent = true;
  ResendResult resendResult = ResendResult.sent;
  AppUser? sessionUser;
  AppUser loggedInUser = const AppUser(
    uid: 'uid1',
    role: AccountRole.founder,
    fullName: 'Mohammed Ahmed',
    email: 'a@b.co',
  );

  /// A founder who already finished onboarding.
  AppUser get onboardedFounder =>
      loggedInUser.copyWith(onboardingCompleted: true);

  @override
  Future<SignupResult> signUp({
    required String fullName,
    required String email,
    required String password,
    required AccountRole role,
  }) async {
    signUpCalls++;
    await gate;
    if (signUpFails != null) throw AuthException(signUpFails!);
    return SignupResult(verificationEmailSent: verificationEmailSent);
  }

  @override
  Future<AppUser> logIn(String email, String password) async {
    logInCalls++;
    await gate;
    if (logInFails != null) throw AuthException(logInFails!);
    return loggedInUser;
  }

  @override
  Future<ResendResult> resendVerification(String email, String password) async {
    resendCalls++;
    await gate;
    if (resendFails != null) throw AuthException(resendFails!);
    return resendResult;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    resetCalls++;
    await gate;
    if (resetFails != null) throw AuthException(resetFails!);
  }

  @override
  Future<AppUser?> restoreSession() async => sessionUser;

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

/// In-memory stand-in for [AppSettingsRepository].
class FakeAppSettingsRepository implements AppSettingsRepository {
  bool introSeen = false;

  @override
  Future<bool> hasSeenIntro() async => introSeen;

  @override
  Future<void> markIntroSeen() async => introSeen = true;
}

/// In-memory stand-in for [StartupRepository].
class FakeStartupRepository implements StartupRepository {
  final List<Startup> startups = [];
  AuthFailure? fetchFails;

  @override
  Future<List<Startup>> fetchMyStartups() async {
    if (fetchFails != null) throw AuthException(fetchFails!);
    return List.of(startups);
  }

  @override
  Future<Startup> create(Startup startup, {File? logo}) async {
    final saved = startup.copyWith(
      id: 'new${startups.length}',
      founderId: 'uid1',
    );
    startups.add(saved);
    return saved;
  }

  @override
  Future<Startup> update(
    Startup startup, {
    File? newLogo,
    bool removeLogo = false,
  }) async {
    startups[startups.indexWhere((s) => s.id == startup.id)] = startup;
    return startup;
  }

  @override
  Future<void> delete(Startup startup) async =>
      startups.removeWhere((s) => s.id == startup.id);
}
