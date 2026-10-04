import '../models/app_user.dart';
import 'app_strings.dart';

/// User-facing text for the Account, Edit Account, Settings, Change Password,
/// Delete Account and Log Out screens, in one place.
class AccountStrings {
  AccountStrings._();

  // Account screen
  static const myAccount = 'My account';
  static const editAccount = 'Edit account';
  static const settings = 'Settings';
  static const helpAndSupport = 'Help & Support';
  static const helpComingSoon = 'Help & Support is coming soon.';
  static const emailLabel = 'Email';
  static const cityLabel = 'City';
  static const bioLabel = 'Bio';
  static const notAddedYet = 'Not added yet';

  /// "Founder · Riyadh", or just "Founder" when no city is saved.
  static String roleLine(AccountRole role, String? city) {
    final roleName = AppStrings.roleName(role);
    return city == null ? roleName : '$roleName · $city';
  }

  // Edit account
  static const editAccountTitle = 'Edit account';
  static const bioFieldLabel = 'Bio (optional)';
  static const bioHint = 'Tell others a little about yourself';
  static const bioMaxLength = 150;
  static const saveChanges = 'Save changes';
  static const changesSaved = 'Your changes have been saved.';
  static const saveFailed = "We couldn't save your changes. Please try again.";

  // Settings
  static const sectionAccount = 'ACCOUNT';
  static const sectionPreferences = 'PREFERENCES';
  static const sectionRemoval = 'ACCOUNT REMOVAL';
  static const changePassword = 'Change password';
  static const changePasswordHint = 'Update the password you use to log in';
  static const notificationPreferences = 'Notification preferences';
  static const notificationPreferencesHint = 'Choose which updates you receive';
  static const notificationsComingSoon =
      'Notification preferences are coming soon.';
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
      'Your account and personal information will be permanently deleted. '
      'Your startups, requests and Investment Associations will also be '
      'removed, and your startups will no longer appear anywhere on Start.sa.';
  static const deleteWarningInvestor =
      'Your account and personal information will be permanently deleted. '
      'Your requests and Investment Associations will also be removed, and '
      "you will no longer appear on any startup's profile.";
  static const cannotBeUndone = "This can't be undone.";
  static const deletePasswordLabel = 'Enter your password to confirm';
  static const deletePasswordHint = 'Password';
  static const passwordRequired = 'Please enter your password.';
  static const passwordIncorrect = 'The password is incorrect.';

  // Log out dialog
  static const logOutTitle = 'Log out of Start.sa?';

  static const cancel = 'Cancel';
}
