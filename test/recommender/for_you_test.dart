import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/features/search/view_models/home_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/investment_ticket.dart';
import 'package:startsa/models/investor_profile.dart';
import 'package:startsa/models/investor_criteria.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/recommender/for_you.dart';

Features _f({
  Vec sector = const {},
  Vec stage = const {},
  Vec model = const {},
}) => Features({'sector': sector, 'stage': stage, 'model': model});

final _now = DateTime(2026, 11, 9);

Candidate<String> _c(String name, Features f, String? sector) =>
    Candidate(name, name, f, sector);

void main() {
  group('features', () {
    test('a startup: all sectors count the same, "Other" dropped', () {
      final s = PrototypeSeed.rafeeq.copyWith(
        sector: Sector.healthtech,
        otherSectors: ['Fintech', 'Other'],
        stage: StartupStage.seed,
        businessModel: BusinessModel.b2b,
      );
      final f = startupFeatures(s);
      expect(f.groups['sector'], {'healthtech': 1.0, 'fintech': 1.0});
      expect(f.groups['stage'], {'seed': 1.0});
      expect(f.groups['model'], {'b2b': 1.0});
    });

    test('investor answers become the same stored values', () {
      final f = criteriaFeatures(
        const InvestorCriteria(
          sectors: ['Fintech', 'HR Tech', 'Other'],
          stages: ['Seed'],
          commerceModels: ['Business-to-Business (B2B)'],
        ),
      );
      expect(f.groups['sector'], {'fintech': 1.0, 'hr_tech': 1.0});
      expect(f.groups['stage'], {'seed': 1.0});
      expect(f.groups['model'], {'b2b': 1.0});
    });

    test('similarity: same is 1, nothing in common is 0', () {
      final a = _f(sector: {'fintech': 1}, stage: {'seed': 1});
      expect(similarity(a, a), closeTo(1, 1e-9));
      expect(
        similarity(a, _f(sector: {'edtech': 1}, stage: {'series_a': 1})),
        0,
      );
    });

    test('similarity weights sector more than stage', () {
      final a = _f(sector: {'fintech': 1}, stage: {'seed': 1});
      final sameSector = _f(sector: {'fintech': 1}, stage: {'series_a': 1});
      final sameStage = _f(sector: {'edtech': 1}, stage: {'seed': 1});
      expect(similarity(a, sameSector), greaterThan(similarity(a, sameStage)));
    });
  });

  group('taste', () {
    final base = _f(sector: {'fintech': 1}, stage: {'seed': 1});
    final health = _f(sector: {'healthtech': 1}, stage: {'seed': 1});

    List<Signal> saved(int n, DateTime at) => [
      for (var i = 0; i < n; i++) Signal(health, at),
    ];

    test('no bookmarks: only the onboarding answers', () {
      final taste = Taste.build(base, const [], now: _now);
      expect(taste.learnedShare, 0);
      expect(taste.features.groups['sector'], {'fintech': 1.0});
    });

    test('bookmarks pull the taste toward them, a little more with each', () {
      final one = Taste.build(base, saved(1, _now), now: _now);
      final five = Taste.build(base, saved(5, _now), now: _now);
      expect(one.learnedShare, greaterThan(0));
      expect(five.learnedShare, greaterThan(one.learnedShare));
      expect(five.learnedShare, lessThan(maxLearnedShare));
      expect(
        five.features.groups['sector']!['healthtech']!,
        greaterThan(one.features.groups['sector']!['healthtech']!),
      );
      // The onboarding answer never disappears.
      expect(five.features.groups['sector']!['fintech'], greaterThan(0));
    });

    test('old bookmarks pull less than new ones, but they still count', () {
      final fresh = Taste.build(base, saved(3, _now), now: _now);
      final old = Taste.build(
        base,
        saved(3, _now.subtract(const Duration(days: 180))),
        now: _now,
      );
      final ancient = Taste.build(
        base,
        saved(3, _now.subtract(const Duration(days: 3000))),
        now: _now,
      );
      expect(old.learnedShare, lessThan(fresh.learnedShare));
      expect(ancient.learnedShare, greaterThan(0.15));
      expect(
        ancient.features.groups['sector']!['healthtech']!,
        greaterThan(0.2),
      );
    });

    test('with no onboarding answers the bookmarks alone are the taste', () {
      final taste = Taste.build(Features.empty, saved(1, _now), now: _now);
      expect(taste.isEmpty, isFalse);
      expect(taste.features.groups['sector'], {'healthtech': 1.0});
    });
  });

  group('recommend', () {
    final base = _f(sector: {'fintech': 1}, stage: {'seed': 1});
    final fintech = _f(sector: {'fintech': 1}, stage: {'seed': 1});
    final health = _f(sector: {'healthtech': 1}, stage: {'seed': 1});

    test('best fit first; ties by name; nothing in common is left out', () {
      final taste = Taste.build(base, const [], now: _now);
      final picks = recommend(taste, [
        _c('B', fintech, 'fintech'),
        _c('A', fintech, 'fintech'),
        _c('Health', health, 'healthtech'),
        _c(
          'Unrelated',
          _f(sector: {'sports': 1}, stage: {'series_c': 1}),
          'sports',
        ),
      ]);
      expect(picks.map((p) => p.item), ['A', 'B', 'Health']);
    });

    test('a bookmark moves a similar item up', () {
      final candidates = [
        _c('Fin', fintech, 'fintech'),
        _c('Health', health, 'healthtech'),
      ];
      final plain = recommend(
        Taste.build(base, const [], now: _now),
        candidates,
      );
      expect(plain.first.item, 'Fin');
      final adapted = recommend(
        Taste.build(Features.empty, [
          for (var i = 0; i < 4; i++) Signal(health, _now),
        ], now: _now),
        candidates,
      );
      expect(adapted.first.item, 'Health');
    });

    test('the last places go to a sector not already in the list', () {
      final taste = Taste.build(base, const [], now: _now);
      final candidates = [
        for (var i = 0; i < 6; i++) _c('Fin$i', fintech, 'fintech'),
        _c('Health', health, 'healthtech'),
      ];
      final picks = recommend(taste, candidates, limit: 4);
      expect(picks, hasLength(4));
      expect(picks.map((p) => p.item), contains('Health'));
    });

    test('an empty taste recommends nothing', () {
      final taste = Taste.build(Features.empty, const [], now: _now);
      expect(recommend(taste, [_c('Fin', fintech, 'fintech')]), isEmpty);
    });
  });

  group('recommendBest (a founder with several startups)', () {
    final healthTaste = Taste.build(
      _f(sector: {'healthtech': 1}, stage: {'seed': 1}),
      const [],
      now: _now,
    );
    final fintechTaste = Taste.build(
      _f(sector: {'fintech': 1}, stage: {'pre_seed': 1}),
      const [],
      now: _now,
    );
    final nora = _c(
      'Nora',
      _f(sector: {'healthtech': 1}, stage: {'seed': 1}),
      'healthtech',
    );
    final omar = _c(
      'Omar',
      _f(sector: {'fintech': 1}, stage: {'pre_seed': 1}),
      'fintech',
    );
    final sara = _c(
      'Sara',
      _f(sector: {'healthtech': 1}, stage: {'series_a': 1}),
      'healthtech',
    );

    test('each startup gets its own good picks; nothing is diluted', () {
      final picks = recommendBest(
        [healthTaste, fintechTaste],
        [sara, omar, nora],
      );
      expect(picks.map((p) => p.item), ['Nora', 'Omar', 'Sara']);
      expect(picks[0].score, closeTo(1, 1e-9));
      expect(picks[1].score, closeTo(1, 1e-9));
      expect(picks[2].score, lessThan(1));
    });

    test('equal best scores: the one that fits more startups goes first', () {
      final both = _c(
        'Zed',
        _f(
          sector: {'healthtech': 1, 'fintech': 1},
          stage: {'seed': 1, 'pre_seed': 1},
        ),
        'healthtech',
      );
      // A: fits only the health startup perfectly. Both: partly fits two.
      final onlyHealth = _c(
        'Amal',
        _f(sector: {'healthtech': 1}, stage: {'seed': 1}),
        'healthtech',
      );
      final tied = recommendBest(
        [healthTaste, healthTaste],
        [both, onlyHealth],
      );
      // Both tastes fit "Amal" perfectly: same best score, same fits, so the
      // name decides.
      expect(tied.first.item, 'Amal');

      // Same best score (1.0), but Twin fits both startups and Solo only one.
      final twin = _c(
        'Twin',
        _f(sector: {'healthtech': 1}, stage: {'seed': 1}),
        'healthtech',
      );
      final solo = _c(
        'Aaa',
        _f(sector: {'healthtech': 1}, stage: {'seed': 1}),
        'healthtech',
      );
      final sameTaste = Taste.build(
        _f(sector: {'healthtech': 1}, stage: {'seed': 1}),
        const [],
        now: _now,
      );
      final otherTaste = Taste.build(
        _f(sector: {'healthtech': 1}, stage: {'pre_seed': 1}),
        const [],
        now: _now,
      );
      final picks = recommendBest(
        [sameTaste, otherTaste],
        [solo, twin],
        allowed: (c, t) => c.name == 'Twin' || t == 0,
      );
      expect(picks.map((p) => p.item), ['Twin', 'Aaa']);
    });

    test('a startup the investor cannot take is not scored against', () {
      final picks = recommendBest(
        [healthTaste, fintechTaste],
        [nora, omar],
        allowed: (c, t) => !(c.name == 'Omar' && t == 1),
      );
      expect(picks.map((p) => p.item), ['Nora']);
    });

    test('no startups fit: nothing is recommended', () {
      expect(recommendBest([healthTaste], [omar]), isEmpty);
    });
  });

  group('ticket and round size', () {
    final raising = PrototypeSeed.rafeeq.copyWith(
      lookingFor: {LookingFor.funding},
      fundingRequirement: 500000,
    );

    test('a startup that is raising must fit the ticket', () {
      expect(sizesFit(raising, ticketBand: 'SAR 100K – 500K'), isTrue);
      expect(sizesFit(raising, ticketBand: 'SAR 1M – 5M'), isFalse);
    });

    test('and the round size', () {
      expect(sizesFit(raising, roundMin: 100000, roundMax: 1000000), isTrue);
      expect(sizesFit(raising, roundMin: 600000), isFalse);
      expect(sizesFit(raising, roundMax: 400000), isFalse);
    });

    test('nothing is checked when the answer or the ask is missing', () {
      expect(sizesFit(raising), isTrue);
      expect(sizesFit(raising, ticketBand: 'Other'), isTrue);
      final notRaising = raising.copyWith(lookingFor: {LookingFor.talent});
      expect(
        sizesFit(notRaising, ticketBand: 'SAR 1M – 5M', roundMin: 9000000),
        isTrue,
      );
    });
  });

  group('funding round and wallet tickets', () {
    final raising = PrototypeSeed.rafeeq.copyWith(
      sector: Sector.healthtech,
      otherSectors: const [],
      stage: StartupStage.seed,
      lookingFor: {LookingFor.funding},
      fundingRequirement: 500000,
    );

    InvestmentTicket ticket({
      List<String> sectors = const ['HealthTech'],
      List<String> stages = const ['Seed'],
      int min = 200000,
      int max = 1000000,
      String investor = 'inv',
      TicketStatus status = TicketStatus.open,
    }) => InvestmentTicket(
      id: '$investor-T1',
      investorId: investor,
      name: 'Ticket',
      sectors: sectors,
      stages: stages,
      amountMin: min,
      amountMax: max,
      status: status,
    );

    test('a ticket that takes the amount, sector and stage is a full fit', () {
      expect(ticketFits(raising, [ticket()]), isTrue);
      expect(ticketBonus(raising, [ticket()]), ticketFitBonus);
    });

    test('a ticket with no sector or stage chosen takes any', () {
      final open = ticket(sectors: const [], stages: const []);
      expect(ticketFits(raising, [open]), isTrue);
    });

    test('only the amount inside the range counts a little', () {
      final other = ticket(sectors: const ['Fintech']);
      expect(ticketFits(raising, [other]), isFalse);
      expect(ticketBonus(raising, [other]), ticketAmountBonus);
    });

    test('an amount outside every ticket adds nothing', () {
      final small = ticket(min: 1000, max: 100000);
      expect(ticketFits(raising, [small]), isFalse);
      expect(ticketBonus(raising, [small]), 0);
    });

    test('a startup that is not raising is not scored by tickets', () {
      final idle = raising.copyWith(lookingFor: {LookingFor.talent});
      expect(ticketFits(idle, [ticket()]), isFalse);
      expect(ticketBonus(idle, [ticket()]), 0);
    });

    test('an open ticket pulls the taste more than a bookmark', () {
      final base = _f(sector: {'fintech': 1}, stage: {'seed': 1});
      final health = _f(sector: {'healthtech': 1}, stage: {'seed': 1});
      final bookmark = Taste.build(base, [Signal(health, _now)], now: _now);
      final open = Taste.build(base, [
        Signal(health, _now, strength: ticketStrength),
      ], now: _now);
      expect(open.learnedShare, greaterThan(bookmark.learnedShare));
    });

    test('the bonus puts the better ticket fit first when scores tie', () {
      final taste = Taste.build(
        _f(sector: {'healthtech': 1}, stage: {'seed': 1}),
        const [],
        now: _now,
      );
      final f = _f(sector: {'healthtech': 1}, stage: {'seed': 1});
      final picks = recommendBest(
        [taste],
        [_c('A', f, 'healthtech'), _c('Z', f, 'healthtech')],
        bonus: (c, _) => c.name == 'Z' ? ticketFitBonus : 0,
      );
      expect(picks.map((p) => p.item), ['Z', 'A']);
    });

    Startup startup(String id, {int ask = 500000}) => raising.copyWith(
      id: id,
      name: id,
      isPublic: true,
      fundingRequirement: ask,
    );

    InvestorProfile investor(String id) => InvestorProfile(
      id: id,
      name: id,
      title: 'Angel',
      city: 'Riyadh',
      sectors: const ['HealthTech'],
      stages: const ['Seed'],
      ticketRange: '',
      locations: const [],
    );

    test('investor: an open ticket adds to the onboarding amount', () {
      const criteria = InvestorCriteria(
        sectors: ['HealthTech'],
        stages: ['Seed'],
        roundMin: 100000,
        roundMax: 1000000,
      );
      final big = startup('big', ask: 5000000);
      final small = startup('small', ask: 300000);
      List<String> ids(List<InvestmentTicket> tickets) =>
          DiscoveryRepository.sample(
                startups: [big, small],
                investors: const [],
                tickets: tickets,
              )
              .recommendedStartups(criteria: criteria, investorId: 'inv')
              .map((i) => i.id)
              .toList();

      expect(ids(const []), ['small']);
      expect(ids([ticket(min: 1000000, max: 10000000)]), ['big', 'small']);
    });

    test(
      'investor: with every ticket removed the onboarding amount is back',
      () {
        const criteria = InvestorCriteria(
          sectors: ['HealthTech'],
          stages: ['Seed'],
          roundMin: 100000,
          roundMax: 1000000,
        );
        final repo = DiscoveryRepository.sample(
          startups: [
            startup('big', ask: 5000000),
            startup('small', ask: 300000),
          ],
          investors: const [],
          tickets: [
            ticket(min: 1000000, max: 10000000, status: TicketStatus.closed),
          ],
        );
        final out = repo.recommendedStartups(
          criteria: criteria,
          investorId: 'inv',
        );
        expect(out.map((i) => i.id), ['small']);
      },
    );

    test('investor: only their own open tickets count', () {
      const criteria = InvestorCriteria(
        sectors: ['HealthTech'],
        stages: ['Seed'],
        roundMin: 100000,
        roundMax: 1000000,
      );
      final big = startup('big', ask: 5000000);
      final repo = DiscoveryRepository.sample(
        startups: [big, startup('small', ask: 300000)],
        investors: const [],
        tickets: [
          ticket(min: 1000000, max: 10000000, investor: 'someone-else'),
          ticket(min: 1000000, max: 10000000, status: TicketStatus.closed),
        ],
      );
      final out = repo.recommendedStartups(
        criteria: criteria,
        investorId: 'inv',
      );
      expect(out.map((i) => i.id), ['small']);
    });

    test('founder: the investor whose ticket takes the amount comes first', () {
      final repo = DiscoveryRepository.sample(
        startups: const [],
        investors: [investor('a'), investor('b')],
        tickets: [ticket(investor: 'b')],
      );
      final out = repo.recommendedInvestors(own: [raising]);
      expect(out.map((i) => i.id), ['b', 'a']);
    });

    test('founder: a ticket outside the amount does not help', () {
      final repo = DiscoveryRepository.sample(
        startups: const [],
        investors: [investor('a'), investor('b')],
        tickets: [ticket(investor: 'b', min: 5000000, max: 9000000)],
      );
      final out = repo.recommendedInvestors(own: [raising]);
      expect(out.map((i) => i.id), ['a', 'b']);
    });
  });

  group('For You in the app', () {
    late DiscoveryRepository discovery;
    const criteria = InvestorCriteria(
      sectors: ['Fintech'],
      stages: ['Pre-seed'],
      commerceModels: ['Business-to-Business (B2B)'],
    );

    setUp(() {
      discovery = DiscoveryRepository.sample();
      AppSession.instance.reset();
    });

    test('investor: criteria decide, bookmarked ones are left out', () {
      final plain = discovery.recommendedStartups(criteria: criteria);
      expect(plain, isNotEmpty);
      final first = plain.first;
      final marked = discovery.recommendedStartups(
        criteria: criteria,
        bookmarks: {'s-${first.id}': DateTime.now()},
      );
      expect(marked.any((i) => i.id == first.id), isFalse);
    });

    test('removing the bookmark brings the original order back', () {
      final plain = discovery.recommendedStartups(criteria: criteria);
      final withMark = discovery.recommendedStartups(
        criteria: criteria,
        bookmarks: {'s-${plain.last.id}': DateTime.now()},
      );
      final again = discovery.recommendedStartups(criteria: criteria);
      expect([for (final i in again) i.id], [for (final i in plain) i.id]);
      expect(withMark.length, lessThanOrEqualTo(plain.length));
    });

    test('no criteria and no bookmarks: the first three, as before', () {
      expect(discovery.recommendedStartups(), hasLength(3));
      expect(discovery.recommendedInvestors(), hasLength(3));
    });

    test('the cards carry no pill and no explanation', () {
      final item = discovery.recommendedStartups(criteria: criteria).first;
      expect(item.highlight, isNull);
      expect(item.highlightReason, isNull);
      expect(item.matchPercent, isNull);
    });

    final health = PrototypeSeed.rafeeq.copyWith(
      sector: Sector.healthtech,
      otherSectors: const [],
      lookingFor: {LookingFor.talent},
    );
    final fintech = PrototypeSeed.naql.copyWith(
      sector: Sector.fintech,
      otherSectors: const [],
      lookingFor: {LookingFor.talent},
    );

    test('founder: investors come from the startups', () {
      final out = discovery.recommendedInvestors(own: [health]);
      expect(out, isNotEmpty);
      expect(out.first.sectors, contains('HealthTech'));
      expect(out.every((i) => i.highlight == null), isTrue);
    });

    test('founder with two startups: the best picks of both are on top', () {
      String top(List<Startup> own) =>
          discovery.recommendedInvestors(own: own).first.id;
      final ids = [
        for (final i in discovery.recommendedInvestors(own: [health, fintech]))
          i.id,
      ];
      expect(ids, contains(top([health])));
      expect(ids, contains(top([fintech])));
    });

    test('founder with no startup and no bookmarks: the first three', () {
      expect(discovery.recommendedInvestors(), hasLength(3));
    });

    test('the list stays put on screen and updates on the next visit', () {
      final marks = BookmarkRepository();
      BookmarkRepository.instance = marks;
      DiscoveryRepository.instance = discovery;
      final vm = HomeViewModel(
        role: SessionRole.investor,
        user: const AppUser(
          uid: 'u1',
          role: AccountRole.investor,
          fullName: 'Layan Alsaab',
          email: 'layan@gmail.com',
          investorCriteria: criteria,
        ),
      );
      addTearDown(vm.dispose);
      vm.selectTab(HomeTab.explore);
      vm.selectExploreTab(0);
      final before = [for (final i in vm.recommended) i.id];
      marks.toggle('s-${before.first}');
      // Still on For You: nothing moves, the card stays.
      expect([for (final i in vm.recommended) i.id], before);
      // Leave and come back: the bookmarked one is gone from the list.
      vm.selectExploreTab(1);
      vm.selectExploreTab(0);
      expect(vm.recommended.any((i) => i.id == before.first), isFalse);
    });
  });
}
