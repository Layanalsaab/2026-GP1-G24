import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/app_user.dart';
import 'signup_view_model.dart';

class SignupFlow {
  SignupFlow({required this.role});

  static SignupFlow? current;

  /// The role being signed up (follows Choose role).
  AccountRole role;

  /// The role the Auth account was created with, once accountCreated.
  AccountRole? createdRole;

  /// The email and password the account was created with.
  String email = '';
  String password = '';

  bool emailSent = true;

  /// When the next verification email may be requested (the 60 s cooldown).
  DateTime? nextResendAt;

  /// True once step 1 created the Auth account in this flow.
  bool accountCreated = false;

  String? savedDetails;

  /// The photo the account was last saved with.
  String? savedPhotoPath;

  /// The step-1 form, kept so Back from the Verify step keeps its answers.
  SignupViewModel? form;

  bool fromInvite = false;

  int get totalSteps => fromInvite
      ? 2
      : role == AccountRole.founder
      ? 2 + FounderToolsStrings.stepTitles.length
      : 4;
}
