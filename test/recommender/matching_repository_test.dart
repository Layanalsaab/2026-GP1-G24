import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/repositories/matching_repository.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/models/investor_criteria.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';

/// Serves fixed documents instead of Firestore and counts the queries.
class _FakeFirestore extends FirestoreService {
  _FakeFirestore(this.collections);

  final Map<String, List<FirestoreDocument>> collections;
  final List<String> queries = [];

  @override
  Future<List<FirestoreDocument>> queryWhereEqual(
    String collection,
    String field,
    Object value, {
    int? limit,
  }) async {
    queries.add('$collection.$field');
    return [
      for (final d in collections[collection] ?? const <FirestoreDocument>[])
        if (d.data[field] == value) d,
    ];
  }
}

Map<String, dynamic> _startup(Map<String, dynamic> over) => {
  'founderId': 'crunchbase-dataset',
  'name': 'Acme',
  'description': 'Acme builds payments for shops. It is based in Riyadh.',
  'sector': 'fintech',
  'stage': 'seed',
  'businessModel': 'b2b',
  'location': 'riyadh',
  'lookingFor': ['funding'],
  'fundingRequirement': 2000000,
  'isPublic': true,
  ...over,
};

Map<String, dynamic> _investor(Map<String, dynamic> over) => {
  'role': 'investor',
  'fullName': 'Investor One',
  'title': 'Angel Investor',
  'city': 'Riyadh',
  'bio': 'Backs early fintech teams.',
  'preferredSectors': ['Fintech'],
  'preferredStages': ['Pre-seed', 'Seed'],
  'preferredCommerceModels': <String>[],
  'ticketSize': 'SAR 100K – 500K',
  'roundSizeMin': null,
  'roundSizeMax': null,
  'investmentsCount': '1–5',
  'crunchbaseRank': 10,
  'isDataset': true,
  ...over,
};

void main() {
  const criteria = InvestorCriteria(
    dealsCount: '1–5',
    ticketBand: 'SAR 100K – 500K',
    sectors: ['Fintech'],
    stages: ['Seed'],
    commerceModels: ['Business-to-Business (B2B)'],
  );
  const investorUser = AppUser(
    uid: 'u1',
    role: AccountRole.investor,
    fullName: 'Test Investor',
    email: 'test@example.com',
    city: 'Riyadh',
    investorCriteria: criteria,
  );

  late _FakeFirestore firestore;
  late MatchingRepository repo;

  setUp(() {
    firestore = _FakeFirestore({
      'startups': [
        (id: 'exact', data: _startup({'name': 'Exact'})),
        (id: 'close', data: _startup({'name': 'Close', 'stage': 'series_a'})),
        (id: 'none', data: _startup({'sector': 'media', 'stage': 'series_b'})),
        (id: 'private', data: _startup({'isPublic': false})),
        (id: 'broken', data: _startup({'sector': 'not-a-sector'})),
      ],
      'investors': [
        (id: 'ANG-1', data: _investor({})),
        (
          id: 'ANG-2',
          data: _investor({
            'fullName': 'Investor Two',
            'city': 'Jeddah',
            'preferredStages': ['Series A'],
          }),
        ),
        (
          id: 'ANG-3',
          data: _investor({
            'fullName': 'Investor Three',
            'preferredSectors': ['Media'],
            'preferredStages': ['Series B'],
          }),
        ),
      ],
    });
    // Read once (the live listeners have their own tests below).
    repo = MatchingRepository(firestore: firestore, live: false);
  });

  test('investor: public startups, exact before close, as cards', () async {
    final items = await repo.startupsForInvestor(investorUser);
    expect(items.map((i) => i.id), ['exact', 'close']);
    expect(items.every((i) => i.kind == HomeItemKind.startup), isTrue);
    expect(items[0].matchPercent, 100);
    expect(items[0].matchReason, 'Same sector & stage');
    expect(items[1].matchPercent, 67); // (0.41 + 0.18) / 0.88
    expect(items[1].matchReason, 'Close match · same sector');
    expect(firestore.queries, ['startups.isPublic']);
    // A tapped card opens the real startup.
    expect(repo.startupById('close')?.name, 'Close');
  });

  test('investor: the pool is kept; refresh reads again', () async {
    await repo.startupsForInvestor(investorUser);
    await repo.startupsForInvestor(investorUser);
    expect(firestore.queries.length, 1);
    await repo.startupsForInvestor(investorUser, refresh: true);
    expect(firestore.queries.length, 2);
  });

  test('investor without answers: no matches and no reads', () async {
    const blank = AppUser(
      uid: 'u2',
      role: AccountRole.investor,
      fullName: 'New Investor',
      email: 'new@example.com',
    );
    expect(await repo.startupsForInvestor(blank), isEmpty);
    expect(firestore.queries, isEmpty);
  });

  test('investor: only startups that are raising', () async {
    firestore.collections['startups']!.add((
      id: 'quiet',
      data: _startup({
        'name': 'Quiet',
        'lookingFor': ['mentorship'],
        'fundingRequirement': null,
      }),
    ));
    final items = await repo.startupsForInvestor(investorUser);
    expect(items.map((i) => i.id), ['exact', 'close']);
  });

  test('founder: investors for a private startup, as cards', () async {
    final mine = Startup.fromMap(
      'mine',
      _startup({'founderId': 'u9', 'name': 'Mine', 'isPublic': false}),
    )!;
    final items = await repo.investorsForStartup(mine);
    expect(items.map((i) => i.id), ['ANG-1', 'ANG-2']);
    expect(items.every((i) => i.kind == HomeItemKind.investor), isTrue);
    // ANG-1: (0.41 + 0.29 / sqrt 2) / 0.70 = 0.879 (no boosts)
    expect(items[0].matchPercent, 88);
    expect(items[0].matchReason, 'Same sector & stage');
    expect(items[0].line, 'Backs early fintech teams.');
    expect(items[0].stage, 'Pre-seed – Seed');
    expect(items[1].matchReason, 'Close match · same sector');
    expect(firestore.queries, ['investors.role']);
    final profile = repo.investorById('ANG-1')!;
    expect(profile.profileBio, 'Backs early fintech teams.');
    expect(profile.ticketRange, 'SAR 100K – 500K');
    expect(profile.title, 'Angel Investor');
  });

  test(
    'founder: a long bio is cut on the card, whole on the profile',
    () async {
      final long =
          'A seasoned entrepreneur with over 20 years of experience in the '
          'technology industry, with a passion for innovation and growth. '
          'I founded a savings platform and mentored more than 150 startups.';
      firestore.collections['investors']![0] = (
        id: 'ANG-1',
        data: _investor({'bio': long}),
      );
      final mine = Startup.fromMap('mine', _startup({'founderId': 'u9'}))!;
      final card = (await repo.investorsForStartup(mine)).first;
      expect(
        card.line.length,
        lessThanOrEqualTo(MatchingRepository.cardBioMax + 1),
      );
      expect(card.line, endsWith('…'));
      // Cut after a full sentence still ends with "…"; a short bio is whole.
      expect(
        MatchingRepository.cardPreview(
          '${'Word ' * 20}ends here. More text follows.',
        ),
        endsWith('…'),
      );
      expect(
        MatchingRepository.cardPreview('Backs early teams.'),
        'Backs early teams.',
      );
      expect(repo.investorById('ANG-1')!.profileBio, long);
    },
  );

  test('a read that fails throws (the screens show a calm message)', () async {
    final broken = MatchingRepository(firestore: _FailingFirestore(), live: false);
    await expectLater(broken.startupsForInvestor(investorUser), throwsA(anything));
    await expectLater(broken.publicStartups(), throwsA(anything));
  });

  test('publicStartups: every public startup that is not closed', () async {
    final all = await repo.publicStartups();
    expect(all, isNotEmpty);
    expect(all.every((s) => s.isPublic && !s.isClosed), isTrue);
  });

  group('live updates (Firestore listeners)', () {
    late _LiveFirestore live;
    late MatchingRepository liveRepo;

    setUp(() {
      live = _LiveFirestore();
      liveRepo = MatchingRepository(firestore: live);
    });

    tearDown(() => liveRepo.clear());

    test(
      'a founder edits a startup: the investor list follows the listener',
      () async {
        final first = liveRepo.startupsForInvestor(investorUser);
        live.send('startups', [
          (id: 'a', data: _startup({'name': 'Alpha'})),
        ]);
        expect((await first).map((i) => i.id), ['a']);
        var changed = 0;
        liveRepo.changes.addListener(() => changed++);
        // Another founder makes their startup fit (no new query is made).
        live.send('startups', [
          (id: 'a', data: _startup({'name': 'Alpha'})),
          (id: 'b', data: _startup({'name': 'Beta'})),
        ]);
        await _settle();
        expect(changed, greaterThan(0));
        final again = await liveRepo.startupsForInvestor(investorUser);
        expect(again.map((i) => i.id), ['a', 'b']);
        expect(live.listens, ['startups']); // one listener, started once
      },
    );

    test('the founder edits their startup: the investors follow', () async {
      final a = Startup.fromMap('a', _startup({'founderId': 'u9'}))!;
      final first = liveRepo.investorsForStartup(a);
      live.send('investors', [
        (id: 'ANG-1', data: _investor({})),
        (
          id: 'ANG-3',
          data: _investor({
            'fullName': 'Investor Three',
            'preferredSectors': ['Media'],
            'preferredStages': ['Series B'],
          }),
        ),
      ]);
      expect((await first).map((i) => i.id), ['ANG-1']);
      // Saved as Media / Series B: the new copy gives other investors.
      final edited = a.copyWith(
        sector: Sector.fromValue('media'),
        stage: StartupStage.seriesB,
      );
      expect(
        (await liveRepo.investorsForStartup(edited)).map((i) => i.id),
        ['ANG-3'],
      );
    });

    test('a listener error: it throws, and a new listener starts next time', () async {
      final failed = liveRepo.startupsForInvestor(investorUser);
      live.fail('startups');
      await expectLater(failed, throwsA(anything));
      final retry = liveRepo.startupsForInvestor(investorUser);
      live.send('startups', [
        (id: 'a', data: _startup({'name': 'Alpha'})),
      ]);
      expect((await retry).map((i) => i.id), ['a']);
      expect(live.listens, ['startups', 'startups']);
    });
  });
}

/// Lets the background load finish (the fakes answer without timers).
Future<void> _settle() => Future<void>.delayed(Duration.zero);

class _FailingFirestore extends FirestoreService {
  @override
  Future<List<FirestoreDocument>> queryWhereEqual(
    String collection,
    String field,
    Object value, {
    int? limit,
  }) async => throw Exception('offline');
}

/// Firestore listeners the test drives: [send] is a new snapshot.
class _LiveFirestore extends FirestoreService {
  final Map<String, StreamController<List<FirestoreDocument>>> _streams = {};
  final List<String> listens = [];

  @override
  Stream<List<FirestoreDocument>> watchWhereEqual(
    String collection,
    String field,
    Object value,
  ) {
    listens.add(collection);
    final c = StreamController<List<FirestoreDocument>>();
    _streams[collection] = c;
    return c.stream;
  }

  void send(String collection, List<FirestoreDocument> docs) =>
      _streams[collection]!.add(docs);

  void fail(String collection) =>
      _streams[collection]!.addError(Exception('offline'));
}
