import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/repositories/matching_repository.dart';
import 'package:startsa/features/search/view_models/home_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
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
        (
          id: 'none',
          data: _startup({'sector': 'media', 'stage': 'series_b'}),
        ),
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

  test('founder: a long bio is cut on the card, whole on the profile', () async {
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
    expect(card.line.length, lessThanOrEqualTo(MatchingRepository.cardBioMax + 1));
    expect(card.line, endsWith('…'));
    // Cut after a full sentence still ends with "…"; a short bio is whole.
    expect(
      MatchingRepository.cardPreview('${'Word ' * 20}ends here. More text follows.'),
      endsWith('…'),
    );
    expect(MatchingRepository.cardPreview('Backs early teams.'), 'Backs early teams.');
    expect(repo.investorById('ANG-1')!.profileBio, long);
  });

  group('Explore -> Matches (HomeViewModel)', () {
    test('investor: loads in the background, then shows the cards', () async {
      final vm = HomeViewModel(
        role: SessionRole.investor,
        user: investorUser,
        matching: repo,
      );
      var notified = 0;
      vm.addListener(() => notified++);
      expect(vm.matches, isEmpty);
      expect(vm.matchesLoading, isTrue);
      await _settle();
      expect(vm.matchesLoading, isFalse);
      expect(vm.matches.map((i) => i.id), ['exact', 'close']);
      expect(notified, 1);
      expect(firestore.queries.length, 1); // reading again doesn't reload
      vm.dispose();
    });

    test('founder: follows the startup chosen in "Matches for"', () async {
      final a = Startup.fromMap('a', _startup({'founderId': 'u9'}))!;
      final b = Startup.fromMap(
        'b',
        _startup({'founderId': 'u9', 'sector': 'media', 'stage': 'series_b'}),
      )!;
      final vm = HomeViewModel(role: SessionRole.founder, matching: repo)
        ..setOwnStartups([a, b]);
      vm.matches;
      await _settle();
      expect(vm.matches.map((i) => i.id), ['ANG-1', 'ANG-2']);
      vm.setMatchFor(1);
      vm.matches;
      await _settle();
      expect(vm.matches.map((i) => i.id), ['ANG-3']);
      vm.dispose();
    });

    test('a failed load shows the error state', () async {
      final vm = HomeViewModel(
        role: SessionRole.investor,
        user: investorUser,
        matching: MatchingRepository(
          firestore: _FailingFirestore(),
          live: false,
        ),
      );
      vm.matches;
      await _settle();
      expect(vm.matchesFailed, isTrue);
      expect(vm.matches, isEmpty);
      vm.dispose();
    });
  });

  group('live updates (Firestore listeners)', () {
    late _LiveFirestore live;
    late MatchingRepository liveRepo;

    setUp(() {
      live = _LiveFirestore();
      liveRepo = MatchingRepository(firestore: live);
    });

    tearDown(() => liveRepo.clear());

    test('a founder edits a startup: the investor list updates by itself', () async {
      final vm = HomeViewModel(
        role: SessionRole.investor,
        user: investorUser,
        matching: liveRepo,
      );
      vm.matches;
      live.send('startups', [
        (id: 'a', data: _startup({'name': 'Alpha'})),
      ]);
      await _settle();
      expect(vm.matches.map((i) => i.id), ['a']);
      var notified = 0;
      vm.addListener(() => notified++);
      // Another founder makes their startup fit (no new query is made).
      live.send('startups', [
        (id: 'a', data: _startup({'name': 'Alpha'})),
        (id: 'b', data: _startup({'name': 'Beta'})),
      ]);
      await _settle();
      expect(vm.matches.map((i) => i.id), ['a', 'b']);
      expect(vm.matchesLoading, isFalse); // no spinner for an update
      expect(notified, greaterThan(0));
      expect(live.listens, ['startups']); // one listener, started once
      vm.dispose();
    });

    test('the founder edits their startup: Matches for it reloads', () async {
      final a = Startup.fromMap('a', _startup({'founderId': 'u9'}))!;
      final vm = HomeViewModel(role: SessionRole.founder, matching: liveRepo)
        ..setOwnStartups([a]);
      vm.matches;
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
      expect(vm.matches.map((i) => i.id), ['ANG-1']);
      // Saved as Media / Series B: the new copy gives other investors.
      vm.setOwnStartups([
        a.copyWith(
          sector: Sector.fromValue('media'),
          stage: StartupStage.seriesB,
        ),
      ]);
      vm.matches;
      await _settle();
      expect(vm.matches.map((i) => i.id), ['ANG-3']);
      vm.dispose();
    });

    test('an investor changes their preferences: the list follows', () async {
      final vm = HomeViewModel(
        role: SessionRole.investor,
        user: investorUser,
        matching: liveRepo,
      );
      vm.matches;
      live.send('startups', [
        (id: 'fin', data: _startup({'name': 'Fin'})),
        (
          id: 'med',
          data: _startup({
            'name': 'Med',
            'sector': 'media',
            'stage': 'series_b',
          }),
        ),
      ]);
      await _settle();
      expect(vm.matches.map((i) => i.id), ['fin']);
      vm.setUser(
        investorUser.copyWith(
          investorCriteria: const InvestorCriteria(
            dealsCount: '1–5',
            ticketBand: 'SAR 100K – 500K',
            sectors: ['Media'],
            stages: ['Series B'],
            commerceModels: ['Business-to-Business (B2B)'],
          ),
        ),
      );
      vm.matches;
      await _settle();
      expect(vm.matches.map((i) => i.id), ['med']);
      vm.dispose();
    });

    test('a listener error: the error state, and a new listener next time', () async {
      final vm = HomeViewModel(
        role: SessionRole.investor,
        user: investorUser,
        matching: liveRepo,
      );
      vm.matches;
      live.fail('startups');
      await _settle();
      expect(vm.matchesFailed, isTrue);
      final retry = vm.refreshMatches();
      live.send('startups', [
        (id: 'a', data: _startup({'name': 'Alpha'})),
      ]);
      await retry;
      expect(vm.matches.map((i) => i.id), ['a']);
      expect(live.listens, ['startups', 'startups']);
      vm.dispose();
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
