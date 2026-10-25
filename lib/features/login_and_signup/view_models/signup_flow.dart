import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/app_user.dart';
import 'signup_view_model.dart';

/// In-memory state of one sign-up (docs/08 section 1): the credentials typed
/// in step 1, kept only in memory (never stored) so step 2 can compare the
/// email, resend the verification link and sign in.
class SignupFlow {
  SignupFlow({required this.role});

  /// The sign-up in progress, so another area (the founder onboarding's
  /// Back arrow) can return to the Verify step. Null when none is running.
  static SignupFlow? current;

  /// The role being signed up (follows Choose role).
  AccountRole role;

  /// The role the Auth account was created with, once [accountCreated].
  AccountRole? createdRole;

  /// The email and password the account was created with.
  String email = '';
  String password = '';

  /// False when the account was created but the first email could not be sent.
  bool emailSent = true;

  /// When the next verification email may be requested (the 60 s cooldown).
  /// Kept here, as a point in time, so the countdown stays correct when the
  /// Verify step is rebuilt or the app goes to the background.
  DateTime? nextResendAt;

  /// True once step 1 created the Auth account in this flow.
  bool accountCreated = false;

  /// The step-1 form, kept so Back from the Verify step keeps its answers.
  SignupViewModel? form;

  /// "STEP n OF total": 7 for a founder, 4 for an investor.
  int get totalSteps => role == AccountRole.founder
      ? 2 + FounderToolsStrings.stepTitles.length
      : 4;
}
