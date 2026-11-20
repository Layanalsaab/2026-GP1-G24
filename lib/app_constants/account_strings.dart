import '../models/list_entries.dart';
import '../models/startup.dart';
import 'app_strings.dart';
import 'founder_tools_strings.dart';

class AccountStrings {
  AccountStrings._();

  static const investorTitle = 'Angel Investor';

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];

  /// "Joined October 2026".
  static String joined(DateTime date) =>
      'Joined ${_months[date.month - 1]} ${date.year}';

  /// "55 123 4567" -> "+966 55 123 4567".
  static String formatPhone(String phone) {
    final p = phone.trim();
    final nine = RegExp(r'^\d{9}$').hasMatch(p);
    final shown = nine
        ? '${p.substring(0, 2)} ${p.substring(2, 5)} ${p.substring(5)}'
        : p;
    return '${AppStrings.phoneCountryCode} $shown';
  }

  static String startupTitle(
    String uid, {
    required Iterable<Startup> owned,
    required Iterable<StartupRole> joined,
  }) {
    if (owned.isNotEmpty) return FounderToolsStrings.roleFounder;
    if (joined.contains(StartupRole.coFounder)) {
      return FounderToolsStrings.roleCoFounder;
    }
    if (joined.isNotEmpty) return FounderToolsStrings.roleMember;
    return FounderToolsStrings.roleFounder;
  }

  static const save = 'Save';
  static const saveFailed = "We couldn't save your changes. Please try again.";

  static const currentPasswordRequired = 'Please enter your current password.';
  static const currentPasswordIncorrect = 'The current password is incorrect.';
  static const samePassword =
      'Choose a new password that is different from your current one.';

  /// Someone who only joined teams (no startup of their own).
  static const deleteWarningMember =
      'Your account and personal information will be permanently deleted. '
      'You will leave every startup you joined, and your details will be '
      'removed from their teams.';

  /// A founder account with no startup at all.
  static const deleteWarningNoStartup =
      'Your account and personal information will be permanently deleted.';
  static const deleteWarningInvestor =
      'Your account and personal information will be permanently deleted. '
      'Your requests and Investment Associations will also be removed, and '
      "you will no longer appear on any startup's profile.";
  static const cannotBeUndone = 'This cannot be undone.';

  /// The password step: only this line (the warning came before).
  static const deletePasswordText =
      'Enter your password to delete your account.';
  static const deletePasswordLabel = 'Password';
  static const deletePasswordHint = 'Enter your password';
  static const passwordRequired = 'Please enter your password.';
  static const passwordIncorrect = 'The password is incorrect.';

  // The founder's choice for each startup he holds
  static const fatesTitle = 'Before you delete your account';
  static String fatesText(int joined) {
    final leave = switch (joined) {
      0 => '',
      1 => ' You will also leave the startup you joined.',
      _ => ' You will also leave the $joined startups you joined.',
    };
    return 'Choose what happens to each startup you founded.$leave';
  }

  static String fatesChosen(int chosen, int total) =>
      chosen >= total ? 'All $total chosen' : '$chosen of $total chosen';
  static String fatesLeft(int left) => '$left left';
  static String fatesStillToChoose(int left) => left == 1
      ? 'Choose for 1 more startup'
      : 'Choose for $left more startups';
  static const fateClose = 'Close';
  static const fateKeepClosed = 'Keep closed';
  static const fateDelete = 'Delete';
  static const fateMissing = 'Choose Close or Delete';
  static const fateOnlyYou = 'Only you';
  static String fateWithTeam(int n) =>
      n == 1 ? 'You and 1 team member' : 'You and $n team members';
  static const nextFounderLabel = 'Next founder';
  static const nextFounderHint =
      'They will decide whether it appears in the Hub.';
  static const fatesContinue = 'Continue';

  static const optional = '(optional)';
  static const changePhoto = 'Change photo';
  static const removePhoto = 'Remove photo';
  static const cropPhotoTitle = 'Crop photo';
  static const photoTooLarge = 'This photo is too large. Try another one.';
  static const photoFailed =
      "We couldn't use that photo. Please try another one.";
  static const photoSaveFailed =
      "Your changes were saved, but the photo couldn't be updated. "
      "Please try again.";
}
