import 'home_item.dart';
import 'startup.dart';

class SavedBookmark {
  const SavedBookmark({required this.item, required this.savedAt});

  final HomeItem item;
  final DateTime savedAt;
}

/// The user's role in one startup.
enum StartupRole {
  founder,

  /// A title only: the same rights as a team member (view only; can leave).
  coFounder,

  /// View only; can leave.
  member;

  /// True when the role can open Manage with full access: the founder only.
  bool get canManage => this == founder;

  static StartupRole? of(Startup startup, String? uid) {
    if (uid == null) return null;
    if (startup.founderId == uid) return StartupRole.founder;
    return switch (startup.memberRoles[uid]) {
      'coFounder' => StartupRole.coFounder,
      'member' => StartupRole.member,
      _ => null,
    };
  }

  /// The TITLE of uid in startup (what the capsules say).
  static StartupRole? titleOf(Startup startup, String? uid) => of(startup, uid);
}

/// One row of My Startups: a startup the user founded, co-founds or belongs to as a team member.
class MyStartupEntry {
  const MyStartupEntry({
    required this.startup,
    required this.role,
    required this.addedAt,
  });

  final Startup startup;

  /// The user's role in this startup.
  final StartupRole role;

  bool get isFounder => role == StartupRole.founder;

  /// When it was created (founder) or when the user joined it.
  final DateTime addedAt;
}
