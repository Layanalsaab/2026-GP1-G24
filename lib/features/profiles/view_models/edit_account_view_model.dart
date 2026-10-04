import 'package:flutter/foundation.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';

/// Logic for the Edit Account screen (PBIs 10 and 12): validates the form and
/// saves the name, city and bio. The email can't be changed here.
class EditAccountViewModel extends ChangeNotifier with SafeNotifier {
  EditAccountViewModel({required this.user, UserRepository? userRepository})
      : _users = userRepository ?? UserRepository.instance,
        city = user.city;

  /// The profile as it was when the screen opened.
  final AppUser user;
  final UserRepository _users;

  /// The selected city chip. Starts as the saved city (may be null).
  String? city;

  bool isLoading = false;
  String? fullNameError;

  /// Shown above the Save button when saving fails.
  String? formError;

  void selectCity(String value) {
    if (isLoading) return;
    city = value;
    formError = null;
    notifyListeners();
  }

  /// Saves the changes. Returns the updated user, or null when the form is
  /// invalid or saving failed (see [fullNameError] / [formError]).
  Future<AppUser?> submit({
    required String fullName,
    required String bio,
  }) async {
    if (isLoading) return null;

    final name = fullName.trim();
    final about = bio.trim();
    fullNameError = Validators.fullName(name);
    formError = null;
    if (fullNameError != null) {
      notifyListeners();
      return null;
    }

    isLoading = true;
    notifyListeners();
    try {
      await _users.updateProfile(
        uid: user.uid,
        fullName: name,
        bio: about,
        city: city,
      );
      return user.copyWith(fullName: name, bio: about, city: city);
    } on AuthException catch (e) {
      formError = e.failure == AuthFailure.network
          ? AppStrings.networkError
          : AccountStrings.saveFailed;
    } catch (_) {
      formError = AccountStrings.saveFailed;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }
}
