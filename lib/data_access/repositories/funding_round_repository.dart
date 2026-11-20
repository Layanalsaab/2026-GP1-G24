import '../../app_constants/firestore_collections.dart';
import '../../models/funding_round.dart';
import '../../models/startup.dart';
import '../../models/startup_enums.dart';
import '../firebase_services/firestore_service.dart';
import '../mock_data/prototype_seed.dart';

class FundingRoundRepository {
  FundingRoundRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService(),
      sample = false;

  /// Tests: every startup has the sample rounds, nothing is read or saved.
  FundingRoundRepository.sample() : _firestore = null, sample = true;

  /// The app-wide instance.
  static FundingRoundRepository instance = FundingRoundRepository();

  final FirestoreService? _firestore;
  final bool sample;

  /// More rounds than any startup has.
  static const _limit = 50;

  /// The rounds to show for startupId, oldest first, numbered 1, 2, 3...
  Future<List<FundingRound>> roundsOf(String startupId) async {
    if (sample) return List.of(PrototypeSeed.sampleRounds);
    final stored = await _load(startupId);
    return [
      for (var i = 0; i < stored.length; i++) stored[i].copyWith(number: i + 1),
    ];
  }

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

  Future<List<FirestoreWrite>> deletesFor(String startupId) async {
    final db = _firestore;
    if (sample || db == null) return const [];
    final collection = FundingRoundFields.collectionOf(startupId);
    final docs = await db.listCollection(collection, limit: _limit);
    return [for (final d in docs) FirestoreWrite.delete(collection, d.id)];
  }

  static StartupStage _roundType(StartupStage stage) =>
      StartupStage.picks.contains(stage) ? stage : StartupStage.preSeed;
}
