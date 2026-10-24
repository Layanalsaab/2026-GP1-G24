import 'home_item.dart';
import 'startup.dart';

/// One saved item on the Bookmarks screen: the card to show and when it was
/// saved ("Newest first" / "Oldest first" sort by [savedAt]).
///
/// Built from the user's saved bookmarks by `BookmarkRepository.savedItems`.
class SavedBookmark {
  const SavedBookmark({required this.item, required this.savedAt});

  final HomeItem item;
  final DateTime savedAt;
}

/// One row of My Startups: a startup the user founded or one they were added
/// to as a team member (view only).
///
/// INTERFACE ONLY: the founder rows come from the existing startup loading;
/// the team-member rows come from `PrototypeSeed.sampleTeamStartups` until
/// the backend provides the real ones.
class MyStartupEntry {
  const MyStartupEntry({
    required this.startup,
    required this.isFounder,
    required this.addedAt,
  });

  final Startup startup;

  /// True: the user owns it (card opens Manage). False: team member (card
  /// opens the public profile, no editing).
  final bool isFounder;

  /// When it was created (founder) or when the user joined it (member).
  final DateTime addedAt;
}
