import '../models/app_user.dart';
import '../models/list_entries.dart';
import '../models/startup.dart';
import '../helpers/validators.dart';
import 'app_strings.dart';
import 'founder_tools_strings.dart';

/// User-facing text for the Account, Edit Account, Settings, Change Password,
/// Delete Account and Log Out screens, in one place.
class AccountStrings {
  AccountStrings._();

  // Account screen
  static const myAccount = 'My account';
  static const editAccount = 'Edit profile';
  static const settings = 'Settings';
  static const helpAndSupport = 'Help & Support';
  static const emailLabel = 'Email';
  static const cityLabel = 'City';
  static const bioLabel = 'Bio';
  static const notAddedYet = 'Not added yet';
  static const sectorsOfInterest = 'Sectors of interest';
  static const startupsStat = 'Startups';
  static const startupStat = 'Startup';
  static const associationsStat = 'Associations';
  static const associationStat = 'Association';

  static String startupsCount(int n) => n == 1 ? startupStat : startupsStat;
  static String associationsCount(int n) =>
      n == 1 ? associationStat : associationsStat;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December', //
  ];

  /// "Joined October 2026".
  static String joined(DateTime date) =>
      'Joined ${_months[date.month - 1]} ${date.year}';

  /// "55 123 4567" -> "+966 55 123 4567". Anything that isn't 9 digits is
  /// shown as it is, after the country code.
  static String formatPhone(String phone) {
    final p = phone.trim();
    final nine = RegExp(r'^\d{9}$').hasMatch(p);
    final shown = nine
        ? '${p.substring(0, 2)} ${p.substring(2, 5)} ${p.substring(5)}'
        : p;
    return '${AppStrings.phoneCountryCode} $shown';
  }

  /// What a startup-side account is called on its own profile and in the
  /// menu: its highest title among its startups. "Founder" when it created a
  /// startup it still owns, then "Owner" (a startup handed to it), then
  /// "Co-founder", then "Team member"; "Founder" before it has any.
  /// [owned]: the startups it owns; [joined]: its role in each startup it
  /// joined.
  static String startupTitle(
    String uid, {
    required Iterable<Startup> owned,
    required Iterable<StartupRole> joined,
  }) {
    if (owned.any((s) => s.originalFounderId == uid)) {
      return FounderToolsStrings.roleFounder;
    }
    if (owned.isNotEmpty) return FounderToolsStrings.roleOwner;
    if (joined.contains(StartupRole.coFounder)) {
      return FounderToolsStrings.roleCoFounder;
    }
    if (joined.isNotEmpty) return FounderToolsStrings.roleMember;
    return FounderToolsStrings.roleFounder;
  }

  /// "Founder · Riyadh", or just "Founder" when no city is saved.
  static String roleLine(AccountRole role, String? city) {
    final roleName = AppStrings.roleName(role);
    return city == null ? roleName : '$roleName · $city';
  }

  // Edit account
  static const editAccountTitle = 'Edit profile';
  static const bioMaxLength = Validators.maxBio;
  static const save = 'Save';
  static const closeEdit = 'Close';
  static const saveChanges = 'Save changes';
  static const changesSaved = 'Your changes have been saved.';
  static const saveFailed = "We couldn't save your changes. Please try again.";

  // Settings
  static const sectionDisplay = 'Display';
  static const sectionNotifications = 'Notifications';
  static const sectionAccount = 'Account';
  static const darkMode = 'Dark mode';
  static const darkModeHint = 'Use a dark theme across the app';
  static const changePassword = 'Change password';
  static const notificationSettings = 'Notification settings';
  static const notificationSettingsHint =
      'Choose which notifications you receive';
  static const deleteAccount = 'Delete account';
  static const deleteAccountHint = 'Permanently remove your account and data';

  // Change password
  static const changePasswordTitle = 'Change password';
  static const currentPasswordLabel = 'Current password';
  static const newPasswordLabel = 'New password';
  static const confirmNewPasswordLabel = 'Confirm new password';
  static const currentPasswordHint = 'Enter your current password';
  static const newPasswordHint = 'Enter a new password';
  static const confirmNewPasswordHint = 'Re-enter the new password';
  static const passwordRulesTitle = 'Your new password must have:';
  static const ruleLength = 'At least 8 characters';
  static const ruleUpperLower = 'An uppercase and a lowercase letter';
  static const ruleNumber = 'At least one number';
  static const updatePassword = 'Update password';
  static const passwordUpdated = 'Your password has been updated.';
  static const currentPasswordRequired = 'Please enter your current password.';
  static const currentPasswordIncorrect = 'The current password is incorrect.';
  static const samePassword =
      'Choose a new password that is different from your current one.';

  // Delete account dialog
  static const deleteTitle = 'Delete your account?';
  static const deleteWarningFounder =
      'Your account and personal information will be permanently deleted, '
      'and your name will be removed from every startup team. A startup with '
      'a team is closed, and its team keeps it as a closed startup; one with '
      'nobody else on it is permanently deleted.';

  /// The first line of the founder's delete confirmation (docs: Closing a
  /// Startup, Leaving and Deleting an Account); one line per startup follows.
  static const deleteWarningFounderBase =
      'Your account and personal information will be permanently deleted, '
      'and your name will be removed from every startup team.';
  static String deleteDeletes(String startup) =>
      '$startup will be permanently deleted.';
  static String deleteCloses(String startup) =>
      '$startup will be closed, and its team will keep it as a closed '
      'startup. To keep $startup active, choose a new owner before deleting '
      'your account.';
  static String deleteStaysClosed(String startup) =>
      '$startup will remain closed for its team.';
  static String deleteLeaves(String startup) =>
      'You will be removed from $startup’s team.';
  static const deleteWarningInvestor =
      'Your account and personal information will be permanently deleted. '
      'Your requests and Investment Associations will also be removed, and '
      "you will no longer appear on any startup's profile.";
  static const cannotBeUndone = 'This cannot be undone.';
  static const deletePasswordLabel = 'Enter your password to confirm';
  static const deletePasswordHint = 'Password';
  static const passwordRequired = 'Please enter your password.';
  static const passwordIncorrect = 'The password is incorrect.';

  // Log out dialog
  static const logOutTitle = 'Log out of Start.sa?';

  // Profile photo
  static const addPhoto = 'Add profile photo';
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

  static const cancel = 'Cancel';
}
