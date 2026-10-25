/// A registered account found by e-mail: what a team member is linked to.
class TeamAccount {
  const TeamAccount({required this.uid, required this.name});

  final String uid;
  final String name;
}

/// Finds a registered Start.sa account by e-mail (case-insensitive) when a
/// founder adds a team member.
///
/// For now it finds nobody (there are no sample accounts any more), so every
/// e-mail a founder adds is treated as "not on Start.sa yet" and gets the
/// invitation. The real version will search the users collection (needs a
/// rule and an index on the email: see the notes for the backend).
class TeamLookup {
  const TeamLookup();

  /// The app-wide instance. Tests replace it.
  static TeamLookup instance = const TeamLookup();

  Future<TeamAccount?> findByEmail(String email) async {
    return null;
  }
}
