import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/list_entries.dart';

/// Who is using the app right now.
enum SessionRole {
  founder,
  investor,

  /// A startup seeker browsing without an account ("Continue as guest").
  guest,
}

class AppSession extends ChangeNotifier {
  AppSession();

  /// The app-wide instance.
  static AppSession instance = AppSession();

  AppUser? _user;
  bool _guest = false;
  Set<String> _ownStartupIds = const {};
  Set<String> _memberStartupIds = const {};
  Map<String, StartupRole> _memberRoles = const {};
  String? _startupTitle;

  /// The signed-in account; null for a guest or when signed out.
  AppUser? get user => _user;

  bool get isGuest => _guest;
  bool get isSignedIn => _user != null;

  SessionRole get role {
    if (_guest || _user == null) return SessionRole.guest;
    return _user!.role == AccountRole.founder
        ? SessionRole.founder
        : SessionRole.investor;
  }

  bool get isFounder => role == SessionRole.founder;
  bool get isInvestor => role == SessionRole.investor;

  /// Guests can never bookmark anything.
  bool get canBookmark => !isGuest;

  /// Ids of the founder's own startups, so Hub and Explore never list them.
  Set<String> get ownStartupIds => _ownStartupIds;

  Set<String> get memberStartupIds => _memberStartupIds;

  Set<String> get belongingStartupIds => {
    ..._ownStartupIds,
    ..._memberStartupIds,
  };

  void signIn(AppUser user) {
    _user = user;
    _guest = false;
    notifyListeners();
  }

  void signInAsGuest() {
    _user = null;
    _guest = true;
    _ownStartupIds = const {};
    _memberStartupIds = const {};
    _memberRoles = const {};
    _startupTitle = null;
    notifyListeners();
  }

  /// The profile was edited (name, photo, ...).
  void updateUser(AppUser user) {
    if (_user == null || _user!.uid != user.uid) return;
    _user = user;
    notifyListeners();
  }

  void setOwnStartupIds(Iterable<String> ids) {
    _ownStartupIds = Set.unmodifiable(ids);
    notifyListeners();
  }

  /// My role (co-founder / team member) in each startup I belong to.
  StartupRole? memberRoleOf(String startupId) => _memberRoles[startupId];

  void setMemberRoles(Map<String, StartupRole> roles) {
    _memberRoles = Map.unmodifiable(roles);
  }

  String? get startupTitle => _startupTitle;

  void setStartupTitle(String? title) => _startupTitle = title;

  void setMemberStartupIds(Iterable<String> ids) {
    _memberStartupIds = Set.unmodifiable(ids);
    notifyListeners();
  }

  void signOut() {
    _user = null;
    _guest = false;
    _ownStartupIds = const {};
    _memberStartupIds = const {};
    _memberRoles = const {};
    _startupTitle = null;
    notifyListeners();
  }

  /// For tests.
  void reset() => signOut();
}
