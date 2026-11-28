import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/features/search/view_models/home_view_model.dart';
import 'package:startsa/helpers/app_session.dart';

void main() {
  HomeViewModel open(SessionRole role, HomeTab tab) {
    final vm = HomeViewModel(role: role)..selectTab(tab);
    addTearDown(vm.dispose);
    vm.searchController.text = 'Rafeeq';
    vm.setQuery('Rafeeq');
    return vm;
  }

  test('a guest can type in Explore, but nothing comes up', () {
    final vm = open(SessionRole.guest, HomeTab.explore);
    expect(vm.searchController.text, 'Rafeeq');
    expect(vm.searchOff, isTrue);
    expect(vm.filtering, isFalse);
  });

  test('a guest still searches Support and the Hub', () {
    for (final tab in [HomeTab.support, HomeTab.hub]) {
      final vm = open(SessionRole.guest, tab);
      expect(vm.searchOff, isFalse);
      expect(vm.filtering, isTrue);
    }
  });

  test('nobody can filter or sort Support, but everyone can search it', () {
    for (final role in SessionRole.values) {
      final vm = open(role, HomeTab.support);
      expect(vm.filterOff, isTrue);
      expect(vm.searchOff, isFalse);
      expect(vm.filtering, isTrue);
    }
  });

  test('filter and sort still work on the Hub', () {
    for (final role in SessionRole.values) {
      expect(open(role, HomeTab.hub).filterOff, isFalse);
    }
  });

  test('a founder or an investor still searches Explore', () {
    for (final role in [SessionRole.founder, SessionRole.investor]) {
      final vm = open(role, HomeTab.explore);
      expect(vm.searchOff, isFalse);
      expect(vm.filtering, isTrue);
    }
  });
}
