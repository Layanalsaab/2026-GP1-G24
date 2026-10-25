import '../mock_data/prototype_seed.dart';

/// A registered account found by e-mail: what a team member is linked to.
class TeamAccount {
  const TeamAccount({required this.uid, required this.name});

  final String uid;
  final String name;
}

/// Finds a registered Start.sa account by e-mail (case-insensitive) when a
/// founder adds a team member.
///
/// INTERFACE ONLY for now: it looks in the sample accounts of
/// [PrototypeSeed.sampleAccounts]. The real version will search the users
/// collection (needs a rule and an index on the email: see the notes for the
/// backend).
class TeamLookup {
  const TeamLookup();

  /// The app-wide instance. Tests replace it.
  static TeamLookup instance = const TeamLookup();

  Future<TeamAccount?> findByEmail(String email) async {
    final key = email.trim().toLowerCase();
    final hit = PrototypeSeed.sampleAccounts[key];
    return hit == null ? null : TeamAccount(uid: hit.$1, name: hit.$2);
  }
}
