import '../../app_constants/firestore_collections.dart';
import '../../models/funding_round.dart';
import '../../models/startup.dart';
import '../../models/startup_enums.dart';
import '../firebase_services/firestore_service.dart';
import '../mock_data/prototype_seed.dart';

/// Reads a startup's funding rounds (`startups/{id}/fundingRounds`) and works
/// out the round writes that go with a startup save.
///
/// THE RULE: a startup asks for Funding exactly while it has an OPEN round,
/// and its `fundingRequirement` is that round's amount. [writesFor] keeps it
/// true; StartupRepository sends those writes in the same batch as the
/// startup, so the two documents never disagree.
///
/// Every method throws AuthException on failure (network, permission, ...).
class FundingRoundRepository {
  FundingRoundRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService(),
      sample = false;

  /// Tests: every startup has the sample rounds, nothing is read or saved.
  FundingRoundRepository.sample() : _firestore = null, sample = true;

  /// The app-wide instance. Tests replace it.
  static FundingRoundRepository instance = FundingRoundRepository();

  final FirestoreService? _firestore;
  final bool sample;

  /// More rounds than any startup has.
  static const _limit = 50;

  /// The rounds to show for [startupId], oldest first, numbered 1, 2, 3...
  /// Rounds without an amount (undisclosed dataset rounds) are left out and
  /// the others are numbered without a gap.
  Future<List<FundingRound>> roundsOf(String startupId) async {
    if (sample) return List.of(PrototypeSeed.sampleRounds);
    final stored = await _load(startupId);
    return [
      for (var i = 0; i < stored.length; i++) stored[i].copyWith(number: i + 1),
    ];
  }

  /// The shown rounds in date order (open round last), with their stored
  /// numbers.
  Future<List<FundingRound>> _load(String startupId) async {
    final docs = await _firestore!.listCollection(
      FundingRoundFields.collectionOf(startupId),
      limit: _limit,
    );
    final rounds = [for (final d in docs) ?FundingRound.fromMap(d.id, d.data)];
    rounds.sort((a, b) {
      if (a.isOpen != b.isOpen) return a.isOpen ? 1 : -1;
      final byDate = a.start.compareTo(b.start);
      return byDate != 0 ? byDate : a.number.compareTo(b.number);
    });
    return rounds;
  }

  /// The writes that make [startupId]'s rounds agree with [startup] as it is
  /// about to be saved. [isNew]: the startup has no rounds yet (skips the
  /// read).
  ///
  /// | Funding ticked? | Open round? | Writes                                 |
  /// | yes             | no          | a new open round                       |
  /// | yes             | yes         | the open round updated (when changed)  |
  /// | no              | yes         | the open round closed (raised kept)    |
  /// | no              | no          | nothing                                |
  Future<List<FirestoreWrite>> writesFor(
    String startupId,
    Startup startup, {
    bool isNew = false,
    DateTime? now,
  }) async {
    final db = _firestore;
    if (sample || db == null) return const [];
    final when = now ?? DateTime.now();
    final rounds = isNew ? <FundingRound>[] : await _load(startupId);
    FundingRound? open;
    for (final r in rounds) {
      if (r.isOpen) open = r;
    }
    final collection = FundingRoundFields.collectionOf(startupId);
    final amount = startup.fundingRequirement ?? 0;
    final raising = startup.seeksFunding && amount > 0;
    final stamp = db.serverTimestamp();

    if (raising && open == null) {
      final round = FundingRound(
        number: rounds.length + 1,
        type: _roundType(startup.stage),
        amount: amount,
        raised: startup.raisedInRound ?? 0,
        start: when,
        wantsLeadInvestor: startup.wantsLeadInvestor,
      );
      return [
        FirestoreWrite.set(collection, db.newDocumentId(collection), {
          ...round.toMap(startupId),
          FundingRoundFields.createdAt: stamp,
          FundingRoundFields.updatedAt: stamp,
        }),
      ];
    }
    if (raising && open != null) {
      final type = _roundType(startup.stage);
      final raised = startup.raisedInRound ?? open.raised;
      final changes = <String, Object?>{
        if (open.amount != amount) FundingRoundFields.amount: amount,
        if (open.raised != raised) FundingRoundFields.raised: raised,
        if (open.type != type) ...{
          FundingRoundFields.stage: type.value,
          FundingRoundFields.stageOther: null,
        },
        if (open.wantsLeadInvestor != startup.wantsLeadInvestor)
          FundingRoundFields.wantsLeadInvestor: startup.wantsLeadInvestor,
      };
      if (changes.isEmpty) return const [];
      return [
        FirestoreWrite.update(collection, open.id, {
          ...changes,
          FundingRoundFields.updatedAt: stamp,
        }),
      ];
    }
    if (!raising && open != null) {
      // Raised stays what the round actually raised.
      return [
        FirestoreWrite.update(collection, open.id, {
          FundingRoundFields.status: FundingRoundFields.completed,
          FundingRoundFields.endDate: when,
          FundingRoundFields.updatedAt: stamp,
        }),
      ];
    }
    return const [];
  }

  /// The writes that delete every round of [startupId] (before the startup
  /// itself is deleted: the rules check the startup's founder).
  Future<List<FirestoreWrite>> deletesFor(String startupId) async {
    final db = _firestore;
    if (sample || db == null) return const [];
    final collection = FundingRoundFields.collectionOf(startupId);
    final docs = await db.listCollection(collection, limit: _limit);
    return [for (final d in docs) FirestoreWrite.delete(collection, d.id)];
  }

  /// A round is one of the stages a founder can pick; an old startup stage
  /// that is no longer offered counts as Pre-seed.
  static StartupStage _roundType(StartupStage stage) =>
      StartupStage.picks.contains(stage) ? stage : StartupStage.preSeed;
}
