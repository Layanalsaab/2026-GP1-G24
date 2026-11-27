import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/features/search/view_models/home_filters.dart';
import 'package:startsa/features/search/view_models/home_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/models/latest_range.dart';
import 'package:startsa/shared_ui/widgets/headers/home_header.dart';

void main() {
  setUp(() {
    DiscoveryRepository.instance = DiscoveryRepository.sample();
  });

  HomeViewModel vm(SessionRole role, {Set<String> own = const {}}) =>
      HomeViewModel(role: role, ownStartupIds: own);

  group('defaults', () {
    test(
      'a founder opens on Investors; an investor and a guest on Startups',
      () {
        for (final r in SessionRole.values) {
          final want = r == SessionRole.founder ? 1 : 0;
          final m = vm(r);
          expect(m.hubSwitch, want, reason: '$r Hub');
          expect(m.resultsSwitch, want, reason: '$r Explore results');
          expect(m.latestSwitch, want, reason: '$r Latest');
          m.dispose();
        }
        expect(vm(SessionRole.founder).tab, HomeTab.hub);
      },
    );

    test('hub cards follow the switch', () {
      final m = vm(SessionRole.founder);
      expect(m.hubCards.every((i) => i.kind == HomeItemKind.investor), isTrue);
      m.setHubSwitch(0);
      expect(m.hubCards.every((i) => i.kind == HomeItemKind.startup), isTrue);
      m.dispose();
    });

    test('a founder sees their own startups in the Hub', () {
      final id = PrototypeSeed.startups.first.id;
      final m = vm(SessionRole.founder, own: {id});
      m.setHubSwitch(0);
      expect(m.hubCards.any((i) => i.id == id), isTrue);
      m.dispose();
    });

    test('guests only have Trending', () {
      final m = vm(SessionRole.guest);
      expect(m.effectiveExploreTab, 1);
      m.dispose();
    });
  });

  group('search and filters', () {
    test('typing filters and changing tab clears the search text', () {
      final m = vm(SessionRole.founder)..setHubSwitch(0);
      final all = m.hubCards.length;
      m.setQuery('zzzz-no-such-thing');
      expect(m.hubCards, isEmpty);
      expect(m.filtering, isTrue);
      expect(m.chips.single.isQuery, isTrue);
      m.selectTab(HomeTab.explore);
      expect(m.query, '');
      m.selectTab(HomeTab.hub);
      expect(m.hubCards.length, all);
      m.dispose();
    });

    test('sector filter, badge count, chips and removal', () {
      final m = vm(SessionRole.founder)..setHubSwitch(0);
      m.applySelection({
        'Sector': {'HealthTech'},
        'Sort by': {'Name A–Z'},
      });
      expect(m.selectionCount, 1);
      expect(m.hubCards.every((i) => i.sectors.contains('HealthTech')), isTrue);
      final names = [for (final i in m.hubCards) i.name.toLowerCase()];
      expect([...names]..sort(), names);
      expect(m.chips.map((c) => c.label), ['HealthTech']);
      m.chips.first.onRemove();
      expect(m.selectionCount, 0);
      m.dispose();
    });

    test('selections are remembered per context', () {
      final m = vm(SessionRole.founder);
      m.applySelection({
        'Sectors': {'Fintech'},
      });
      m.setHubSwitch(0);
      expect(m.selectionCount, 0);
      m.setHubSwitch(1);
      expect(m.selectionCount, 1);
      m.dispose();
    });

    test('clearAll resets filters and text', () {
      final m = vm(SessionRole.investor);
      m.applySelection({
        'City': {'Riyadh'},
      });
      m.setQuery('a');
      m.clearAll();
      expect(m.filtering, isFalse);
      m.dispose();
    });

    test('the Investors search: no Investor type, counts and chips work', () {
      expect(HomeFilters.groups(HomeContext.investors).map((g) => g.title), [
        'Sectors',
        'Stages',
        'Commerce models',
        'Investment size',
        'City',
      ]);
      final m = vm(SessionRole.founder)..setHubSwitch(1);
      m.applySelection({
        'Sectors': {'HealthTech'},
        'Stages': {'Seed'},
        'Investment size': {'SAR 100K – 500K'},
        'City': {'Riyadh'},
        'Sort by': {'Name A–Z'},
      });
      // Sort by is not counted: four filters.
      expect(m.selectionCount, 4);
      expect(m.chips.length, 4);
      m.chips.first.onRemove();
      expect(m.selectionCount, 3);
      expect(m.chips.length, 3);
      m.clearAll();
      expect(m.selectionCount, 0);
      // The sort is not a filter: it stays.
      expect(m.sortChoice, 'Name A–Z');
      m.dispose();
    });

    test('countFor counts a draft without the search text', () {
      final m = vm(SessionRole.founder)..setHubSwitch(0);
      final n = m.countFor({
        'Sector': {'HealthTech'},
      });
      expect(n, greaterThan(0));
      m.dispose();
    });

    test('Explore results view', () {
      final m = vm(SessionRole.investor)..selectTab(HomeTab.explore);
      expect(m.filtering, isFalse);
      m.setQuery('a');
      expect(m.filtering, isTrue);
      expect(m.exploreResults, isNotEmpty);
      m.dispose();
    });
  });

  group('groups', () {
    test('every context has the prototype groups', () {
      expect(HomeFilters.groups(HomeContext.startups).map((g) => g.title), [
        'Sector',
        'Stage',
        'Looking for',
        'Partner types',
        'Support types',
        'Raising',
        'Commerce model',
        'Headquarters',
        'Status',
      ]);
      expect(HomeFilters.groups(HomeContext.explore).length, 3);
      expect(HomeFilters.groups(HomeContext.support).first.title, 'Type');
      expect(HomeFilters.groups(HomeContext.investors)[1].title, 'Stages');
    });
  });

  group('explore lists', () {
    test('the tabs are Latest, Trending, For You and open on Latest', () {
      expect(
        [for (final t in ExploreTab.defaults) t.label],
        ['Latest', 'Trending', 'For You'],
      );
      expect(ExploreTab.forRole(founder: true), ExploreTab.defaults);
      expect(ExploreTab.forRole(founder: false), ExploreTab.defaults);
      final m = vm(SessionRole.investor);
      expect(m.effectiveExploreTab, 0);
      m.selectExploreTab(2);
      expect(m.effectiveExploreTab, 2);
      m.selectExploreTab(9);
      expect(m.effectiveExploreTab, 2);
      m.dispose();
    });

    test(
      'For You has no switch: an investor gets startups, a founder investors',
      () {
        final i = vm(SessionRole.investor);
        expect(i.recommended, isNotEmpty);
        expect(
          i.recommended.every((x) => x.kind == HomeItemKind.startup),
          isTrue,
        );
        expect(i.recommendedTitle, 'Recommended startups for you');
        expect(
          i.recommendedInfo,
          'Based on your sectors, stages, commerce models, how much you invest, your open tickets and what startups are raising. The more startups you bookmark, the more it follows your taste.',
        );
        final f = vm(SessionRole.founder);
        expect(
          f.recommended.every((x) => x.kind == HomeItemKind.investor),
          isTrue,
        );
        expect(f.recommendedTitle, 'Recommended investors for you');
        expect(
          f.recommendedInfo,
          'Based on your startup’s sector, stage, commerce model, what you are raising and investors’ open tickets. The more investors you bookmark, the more it follows your taste.',
        );
        i.dispose();
        f.dispose();
      },
    );

    test('For You keeps the startups the founder belongs to out', () {
      final id = PrototypeSeed.startups.first.id;
      final m = vm(SessionRole.investor, own: {id});
      expect(m.recommended.any((x) => x.id == id), isFalse);
      m.dispose();
    });
  });

  group('Latest', () {
    final now = DateTime.now();
    DateTime ago(int days) => now.subtract(Duration(days: days));

    Future<HomeViewModel> loaded(
      Map<String, DateTime> startups, {
      Map<String, DateTime> investors = const {},
      Set<String> own = const {},
      SessionRole role = SessionRole.investor,
    }) async {
      final base = PrototypeSeed.rafeeq;
      final repo = DiscoveryRepository(
        firestore: _Docs(
          {
            for (final e in startups.entries)
              e.key: {
                ...base.toMap(),
                'name': 'S ${e.key}',
                'isPublic': true,
                'createdAt': e.value,
              },
          },
          investors: {
            for (final e in investors.entries)
              e.key: {'fullName': 'I ${e.key}', 'createdAt': e.value},
          },
        ),
      );
      await repo.refresh();
      DiscoveryRepository.instance = repo;
      return HomeViewModel(role: role, ownStartupIds: own);
    }

    test(
      'newest first, with a "Joined … ago" line, the last 6 months by default',
      () async {
        final m = await loaded({
          'a': ago(2),
          'b': ago(20),
          'c': ago(0),
          'd': ago(200),
        });
        expect(m.latestRange.label, 'Last 6 months');
        expect([for (final i in m.latest) i.id], ['c', 'a', 'b']);
        expect(m.latest.first.highlight, 'Joined today');
        expect(m.latest[1].highlight, 'Joined 2 days ago');
        m.dispose();
      },
    );

    test(
      'the dropdown ranges: week, month, 3 months, 6 months, year',
      () async {
        final m = await loaded({
          'a': ago(2),
          'b': ago(20),
          'c': ago(100),
          'd': ago(200),
          'e': ago(400),
        });
        expect(
          [for (final r in LatestRange.values) r.label],
          [
            'Last week',
            'Last month',
            'Last 3 months',
            'Last 6 months',
            'Last year',
          ],
        );
        expect(LatestRange.month.days, 30);
        m.setLatestRange(0); // Last week
        expect([for (final i in m.latest) i.id], ['a']);
        m.setLatestRange(1); // Last month
        expect([for (final i in m.latest) i.id], ['a', 'b']);
        m.setLatestRange(2); // Last 3 months
        expect([for (final i in m.latest) i.id], ['a', 'b']);
        m.setLatestRange(3); // Last 6 months
        expect([for (final i in m.latest) i.id], ['a', 'b', 'c']);
        m.setLatestRange(4); // Last year
        expect([for (final i in m.latest) i.id], ['a', 'b', 'c', 'd']);
        m.dispose();
      },
    );

    test('a founder sees their own new startups too', () async {
      final m = await loaded(
        {'a': ago(1), 'b': ago(2)},
        own: {'a'},
        role: SessionRole.founder,
      );
      m.setLatestSwitch(0);
      expect([for (final i in m.latest) i.id], ['a', 'b']);
      m.dispose();
    });

    test('a Hub-style switch; each role starts on the other side', () async {
      final investor = await loaded({'s': ago(1)}, investors: {'i': ago(1)});
      expect(investor.latestSwitch, 0);
      expect([for (final i in investor.latest) i.id], ['s']);
      investor.dispose();
      final founder = await loaded(
        {'s': ago(1)},
        investors: {'i': ago(1)},
        role: SessionRole.founder,
      );
      expect(founder.latestSwitch, 1);
      expect([for (final i in founder.latest) i.id], ['i']);
      founder.dispose();
    });

    test('the Investors side lists new investors, yourself included', () async {
      final m = await loaded(
        const {},
        investors: {'me': ago(0), 'old': ago(40), 'other': ago(3)},
      );
      m.setLatestSwitch(1);
      expect([for (final i in m.latest) i.id], ['me', 'other', 'old']);
      expect(m.latest.first.highlight, 'Joined today');
      m.setLatestRange(1);
      expect([for (final i in m.latest) i.id], ['me', 'other']);
      m.dispose();
    });

    test('the joined lines', () {
      final today = DateTime(2026, 11, 7, 12);
      String at(DateTime d) => DiscoveryRepository.joinedAgo(d, now: today);
      expect(at(DateTime(2026, 11, 7)), 'Joined today');
      expect(at(DateTime(2026, 11, 6)), 'Joined yesterday');
      expect(at(DateTime(2026, 11, 5)), 'Joined 2 days ago');
      expect(at(DateTime(2026, 10, 31)), 'Joined 1 week ago');
      expect(at(DateTime(2026, 10, 17)), 'Joined 3 weeks ago');
      expect(at(DateTime(2026, 8, 7)), 'Joined 3 months ago');
      expect(at(DateTime(2025, 1, 1)), 'Joined over a year ago');
    });

    test('empty when nothing joined in the range', () async {
      final m = await loaded({'a': ago(300)});
      expect(m.latest, isEmpty);
      m.dispose();
    });
  });
}

/// Startups served as documents (the isPublic == true query).
class _Docs extends FirestoreService {
  _Docs(this.startups, {this.investors = const {}});

  final Map<String, Map<String, Object?>> startups;
  final Map<String, Map<String, Object?>> investors;

  @override
  Future<List<FirestoreDocument>> queryWhereEqual(
    String collection,
    String field,
    Object value, {
    int? limit,
  }) async => collection == 'startups'
      ? [
          for (final e in startups.entries)
            (id: e.key, data: Map<String, dynamic>.from(e.value)),
        ]
      : const [];

  @override
  Future<List<FirestoreDocument>> listCollection(
    String collection, {
    int limit = 100,
  }) async => collection == 'investors'
      ? [
          for (final e in investors.entries)
            (id: e.key, data: Map<String, dynamic>.from(e.value)),
        ]
      : const [];
}
