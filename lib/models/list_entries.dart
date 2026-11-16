import 'home_item.dart';
import 'startup.dart';

/// One saved item on the Bookmarks screen: the card to show and when it was
/// saved ("Newest" / "Oldest" sort by [savedAt]).
///
/// Built from the user's saved bookmarks by `BookmarkRepository.savedItems`.
class SavedBookmark {
  const SavedBookmark({required this.item, required this.savedAt});

  final HomeItem item;
  final DateTime savedAt;
}

/// The user's role in one startup.
enum StartupRole {
  /// The startup's founder (`founderId`): the only one who edits it,
  /// invites, changes its visibility, closes, deletes or hands it over.
  founder,

  /// A title only: the same rights as a team member (view only; can leave).
  coFounder,

  /// View only; can leave.
  member;

  /// True when the role can open Manage with full access: the founder only.
  bool get canManage => this == founder;

  /// The signed-in user's role in [startup], read from the startup itself:
  /// the founder is `founderId`; co-founders and team members are in
  /// `memberRoles`. Null when [uid] has no role in it.
  static StartupRole? of(Startup startup, String? uid) {
    if (uid == null) return null;
    if (startup.founderId == uid) return StartupRole.founder;
    return switch (startup.memberRoles[uid]) {
      'coFounder' => StartupRole.coFounder,
      'member' => StartupRole.member,
      _ => null,
    };
  }

  /// The TITLE of [uid] in [startup] (what the capsules say). The title
  /// follows control: whoever holds the startup now is its "Founder" (also
  /// after a handover), so it is the same as [of]. Null when [uid] has no
  /// role there.
  static StartupRole? titleOf(Startup startup, String? uid) => of(startup, uid);
}

/// One row of My Startups: a startup the user founded, co-founds or belongs
/// to as a team member.
///
/// INTERFACE ONLY: the founder rows come from the existing startup loading;
/// the co-founder and team-member rows come from
/// `PrototypeSeed.sampleTeamStartups` until the backend provides the real
/// memberships.
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
