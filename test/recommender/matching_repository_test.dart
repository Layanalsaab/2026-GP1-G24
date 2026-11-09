import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/repositories/matching_repository.dart';
import 'package:startsa/models/investment_ticket.dart';
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
  late _FakeFirestore firestore;
  late MatchingRepository repo;

  setUp(() {
    firestore = _FakeFirestore({
      'startups': [
        (id: 'exact', data: _startup({'name': 'Exact'})),
        (id: 'close', data: _startup({'name': 'Close', 'stage': 'series_a'})),
        (id: 'none', data: _startup({'sector': 'media', 'stage': 'series_b'})),
        (id: 'private', data: _startup({'isPublic': false})),
        (id: 'closed', data: _startup({'status': 'closed'})),
        (id: 'broken', data: _startup({'sector': 'not-a-sector'})),
      ],
      'tickets': [
        (
          id: 'ANG-3-T1',
          data: {
            'investorId': 'ANG-3',
            'name': 'Ticket 1',
            'sectors': ['Fintech'],
            'stages': ['Seed'],
            'amountMin': 100000,
            'amountMax': 500000,
            'status': 'open',
          },
        ),
        (
          id: 'ANG-2-T1',
          data: {
            'investorId': 'ANG-2',
            'name': 'Ticket 1',
            'sectors': ['Fintech'],
            'stages': ['Seed'],
            'amountMin': 100000,
            'amountMax': 500000,
            'status': 'used',
          },
        ),
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

  InvestmentTicket ticket([Map<String, dynamic> over = const {}]) =>
      InvestmentTicket.fromMap(over['id'] as String? ?? 'u1-T1', {
        'investorId': 'u1',
        'name': 'Ticket 1',
        'sectors': ['Fintech'],
        'stages': ['Seed'],
        'amountMin': 100000,
        'amountMax': 500000,
        'status': 'open',
        ...over,
      })!;

  test('publicStartups: public and not closed only', () async {
    final all = await repo.publicStartups();
    // A document the app can't show ('broken') is left out too.
    expect(all.map((s) => s.id), ['exact', 'close', 'none']);
    expect(all.every((s) => s.isPublic && !s.isClosed), isTrue);
    expect(firestore.queries, ['startups.isPublic']);
    // A tapped match opens the real startup.
    expect(repo.startupById('close')?.name, 'Close');
  });

  test('the pool is kept; refresh reads again', () async {
    await repo.publicStartups();
    await repo.publicStartups();
    expect(firestore.queries.length, 1);
    await repo.publicStartups(refresh: true);
    expect(firestore.queries.length, 2);
  });

  test('a ticket: exact before close, private and closed never', () async {
    final pool = await repo.publicStartups();
    final r = MatchingRepository.matchesForTicket(
      ticket(),
      criteria.commerceModels,
      pool,
    );
    expect(r.map((m) => m.id), ['exact', 'close']);
    // SAR 2M left, the ticket goes up to 500K: round fit 0.25.
    expect(r[0].percent, 91); // 0.41 + 0.29 + 0.18 + 0.12 * 0.25
    expect(r[1].percent, 62); // the stage differs: 0.41 + 0.18 + 0.03
    expect(r[1].close, isTrue);
    expect(r[0].remaining, 2000000);
  });

  test('a ticket matches only startups that are raising', () async {
    firestore.collections['startups']!.add((
      id: 'quiet',
      data: _startup({
        'name': 'Quiet',
        'lookingFor': ['mentorship'],
        'fundingRequirement': null,
      }),
    ));
    final pool = await repo.publicStartups();
    final r = MatchingRepository.matchesForTicket(ticket(), const [], pool);
    expect(r.map((m) => m.id), ['exact', 'close']);
  });

  test('founder: open tickets first, then profiles (private startup)', () async {
    final mine = Startup.fromMap(
      'mine',
      _startup({'founderId': 'u9', 'name': 'Mine', 'isPublic': false}),
    )!;
    final r = await repo.investorsForStartup(mine);
    // ANG-3's profile doesn't fit, but their open ticket does.
    expect(r.map((m) => m.id), ['ANG-3', 'ANG-1', 'ANG-2']);
    expect(r[0].ticketId, 'ANG-3-T1');
    // ANG-1: (0.41 + 0.29 / sqrt 2) / 0.70 = 0.879 (no commerce models)
    expect(r[1].percent, 88);
    expect(r[1].ticketId, isNull);
    expect(r[2].close, isTrue);
    expect(firestore.queries, ['investors.role', 'tickets.status']);
    final profile = repo.investorById('ANG-1')!;
    expect(profile.profileBio, 'Backs early fintech teams.');
    expect(profile.ticketRange, 'SAR 100K – 500K');
    expect(profile.title, 'Angel Investor');
  });

  test('founder: a closed startup gets no matches and reads nothing', () async {
    final closed = Startup.fromMap(
      'mine',
      _startup({'founderId': 'u9', 'status': 'closed'}),
    )!;
    expect(await repo.investorsForStartup(closed), isEmpty);
    expect(firestore.queries, isEmpty);
  });

  test('founder: a long bio is cut for cards, whole on the profile', () async {
    final long =
        'A seasoned entrepreneur with over 20 years of experience in the '
        'technology industry, with a passion for innovation and growth. '
        'I founded a savings platform and mentored more than 150 startups.';
    firestore.collections['investors']![0] = (
      id: 'ANG-1',
      data: _investor({'bio': long}),
    );
    final mine = Startup.fromMap('mine', _startup({'founderId': 'u9'}))!;
    await repo.investorsForStartup(mine);
    final about = repo.investorById('ANG-1')!.about!;
    expect(about.length, lessThanOrEqualTo(MatchingRepository.cardBioMax + 1));
    expect(about, endsWith('…'));
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
  });

  test('a read that fails throws (the screens show a calm message)', () async {
    final broken = MatchingRepository(firestore: _FailingFirestore(), live: false);
    await expectLater(broken.publicStartups(), throwsA(anything));
    final mine = Startup.fromMap('mine', _startup({'founderId': 'u9'}))!;
    await expectLater(broken.investorsForStartup(mine), throwsA(anything));
  });

  group('live updates (Firestore listeners)', () {
    late _LiveFirestore live;
    late MatchingRepository liveRepo;

    setUp(() {
      live = _LiveFirestore();
      liveRepo = MatchingRepository(firestore: live);
    });

    tearDown(() => liveRepo.clear());

    test('a startup opens a round: the pool follows the listener', () async {
      final first = liveRepo.publicStartups();
      live.send('startups', [
        (id: 'a', data: _startup({'name': 'Alpha'})),
      ]);
      expect((await first).map((s) => s.id), ['a']);
      var changed = 0;
      liveRepo.changes.addListener(() => changed++);
      // Another founder's startup arrives, and Alpha closes (no new query).
      live.send('startups', [
        (id: 'a', data: _startup({'name': 'Alpha', 'status': 'closed'})),
        (id: 'b', data: _startup({'name': 'Beta'})),
      ]);
      await _settle();
      expect(changed, greaterThan(0));
      expect((await liveRepo.publicStartups()).map((s) => s.id), ['b']);
      expect(live.listens, ['startups']); // one listener, started once
    });

    test('investors and open tickets are watched for a round', () async {
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
      await _settle();
      live.send('tickets', const []);
      expect((await first).map((m) => m.id), ['ANG-1']);
      // ANG-3 opens a ticket that fits: they come first (no new query).
      live.send('tickets', [
        (
          id: 'ANG-3-T1',
          data: {
            'investorId': 'ANG-3',
            'name': 'Ticket 1',
            'sectors': ['Fintech'],
            'stages': ['Seed'],
            'amountMin': 100000,
            'amountMax': 500000,
            'status': 'open',
          },
        ),
      ]);
      await _settle();
      expect(
        (await liveRepo.investorsForStartup(a)).map((m) => m.id),
        ['ANG-3', 'ANG-1'],
      );
      // Saved as Media / Series B: other investors.
      final edited = a.copyWith(
        sector: Sector.fromValue('media'),
        stage: StartupStage.seriesB,
      );
      expect(
        (await liveRepo.investorsForStartup(edited)).map((m) => m.id),
        ['ANG-3'],
      );
      expect(live.listens, ['investors', 'tickets']);
    });

    test('a listener error: it throws, and a new listener starts next time', () async {
      final failed = liveRepo.publicStartups();
      live.fail('startups');
      await expectLater(failed, throwsA(anything));
      final retry = liveRepo.publicStartups();
      live.send('startups', [
        (id: 'a', data: _startup({'name': 'Alpha'})),
      ]);
      expect((await retry).map((s) => s.id), ['a']);
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
