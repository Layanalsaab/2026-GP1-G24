import 'package:flutter/foundation.dart';

import '../../../data_access/repositories/user_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/app_user.dart';

/// Logic for the Account screen (PBIs 9 and 11): holds the profile shown on
/// screen and keeps it up to date.
class AccountViewModel extends ChangeNotifier with SafeNotifier {
  AccountViewModel({required this._user, UserRepository? userRepository})
      : _users = userRepository ?? UserRepository.instance;

  final UserRepository _users;
  AppUser _user;

  AppUser get user => _user;

  /// The user passed in may be older than what's saved (for example, after an
  /// edit made earlier in this session), so fetch the latest profile. If that
  /// fails (e.g. offline), keep showing what we already have.
  Future<void> reload() async {
    try {
      final latest = await _users.getProfile(_user.uid);
      if (latest == null) return;
      _user = latest;
      notifyListeners();
    } catch (_) {
      // Keep the details we already have.
    }
  }

  /// Shows the details saved on the Edit Account screen.
  void updateUser(AppUser updated) {
    _user = updated;
    notifyListeners();
  }
}
