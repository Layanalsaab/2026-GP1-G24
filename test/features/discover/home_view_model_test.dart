import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/features/search/view_models/home_filters.dart';
import 'package:startsa/features/search/view_models/home_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/home_item.dart';

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
          expect(m.forYouSwitch, want, reason: '$r For You');
          expect(m.trendingSwitch, want, reason: '$r Trending');
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

    test('a founder never sees their own startups', () {
      final id = PrototypeSeed.startups.first.id;
      final m = vm(SessionRole.founder, own: {id});
      m.setHubSwitch(0);
      expect(m.hubCards.any((i) => i.id == id), isFalse);
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
        'Sector': {'Fintech'},
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
        'Raising',
        'Commerce model',
        'City',
        'Sort by',
      ]);
      expect(HomeFilters.groups(HomeContext.explore).length, 4);
      expect(HomeFilters.groups(HomeContext.support).first.title, 'Type');
      expect(
        HomeFilters.groups(HomeContext.investors)[1].title,
        'Stages they invest in',
      );
    });
  });

  group('explore lists', () {
    test('trending has at most 30 and follows the range', () {
      final m = vm(SessionRole.investor);
      expect(m.trending.length, lessThanOrEqualTo(30));
      m.setRange(0);
      expect(m.range.label, 'Today');
      m.dispose();
    });

    test('new on Start.sa follows the For You switch', () {
      final m = vm(SessionRole.investor);
      expect(m.newItems.every((i) => i.kind == HomeItemKind.startup), isTrue);
      m.setForYouSwitch(1);
      expect(m.newItems.every((i) => i.kind == HomeItemKind.investor), isTrue);
      final f = vm(SessionRole.founder);
      expect(f.newItems.every((i) => i.kind == HomeItemKind.investor), isTrue);
      f.dispose();
      expect(m.recommended.length, 3);
      m.dispose();
    });
  });
}
