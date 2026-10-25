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

/// The signed-in user (or the guest) for the running app, so screens deep in
/// the tree can read the role without it being passed through every
/// constructor.
///
/// Set by the auth flow ([signIn], [signInAsGuest]) and cleared by [signOut].
/// Profile edits call [updateUser] so the header and menu refresh.
class AppSession extends ChangeNotifier {
  AppSession();

  /// The app-wide instance. Tests replace it or call [reset].
  static AppSession instance = AppSession();

  AppUser? _user;
  bool _guest = false;
  Set<String> _ownStartupIds = const {};
  Set<String> _memberStartupIds = const {};
  Map<String, StartupRole> _memberRoles = const {};

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

  /// Ids of the startups the user belongs to as a co-founder or team member.
  Set<String> get memberStartupIds => _memberStartupIds;

  /// Every startup the user belongs to (founder, co-founder, team member):
  /// none of them is listed in the user's Hub or For You (Trending still
  /// shows them, and they are always reachable from My Startups).
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
    notifyListeners();
  }

  /// For tests.
  void reset() => signOut();
}
