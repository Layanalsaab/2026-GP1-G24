import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/repositories/public_profile_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/models/public_profile.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/team_member.dart';

import '../support/fakes.dart';

/// A startup of [founder] with the given team cards and member roles.
Startup _startup(
  String id, {
  String founder = 'f1',
  List<TeamMember> team = const [],
  Map<String, String> roles = const {},
}) => PrototypeSeed.rafeeq.copyWith(
  id: id,
  name: 'S $id',
  founderId: founder,
  team: team,
  memberRoles: roles,
);

PublicProfile _person(List<String> startupIds) => PublicProfile(
  id: 'p1',
  fullName: 'Mona Alharbi',
  startups: [
    for (final id in startupIds)
      ProfileStartupRef(id: id, name: id, role: 'member'),
  ],
);

void main() {
  late FakeStartupRepository startups;
  late StartupRepository previous;

  setUp(() {
    previous = StartupRepository.instance;
    startups = FakeStartupRepository();
    StartupRepository.instance = startups;
  });
  tearDown(() => StartupRepository.instance = previous);

  final repo = PublicProfileRepository();

  group('startups on a person\'s profile', () {
    test('a member and a co-founder are listed with their role', () async {
      startups.startups
        ..add(_startup('a', roles: {'p1': 'member'}))
        ..add(_startup('b', roles: {'p1': 'coFounder'}));
      final list = await repo.startupsOf(_person(['a', 'b']));
      expect({for (final r in list) r.id: r.role}, {
        'a': 'member',
        'b': 'coFounder',
      });
      expect(list.every((r) => r.startup != null), isTrue);
    });

    test('the founder is listed as Founder', () async {
      startups.startups.add(_startup('a', founder: 'p1'));
      final list = await repo.startupsOf(_person(['a']));
      expect(list.single.role, 'founder');
    });

    test('a person who is no longer on the team is not listed', () async {
      startups.startups.add(_startup('a')); // stale id: not a member any more
      expect(await repo.startupsOf(_person(['a'])), isEmpty);
    });

    test('an invited (not joined) card is not a membership', () async {
      startups.startups.add(
        _startup(
          'a',
          team: const [
            TeamMember(
              name: 'Mona',
              role: 'CTO',
              contribution: '',
              invited: true,
              uid: 'p1',
            ),
          ],
        ),
      );
      expect(await repo.startupsOf(_person(['a'])), isEmpty);
    });

    test('a person on the team list (sample data) is a member', () async {
      startups.startups.add(
        _startup(
          'a',
          founder: 'crunchbase-dataset',
          team: const [
            TeamMember(name: 'Mona', role: 'CTO', contribution: '', uid: 'p1'),
          ],
        ),
      );
      final list = await repo.startupsOf(_person(['a']));
      expect(list.single.role, 'member');
    });

    test('a startup that is gone or unreadable is skipped', () async {
      startups.startups.add(_startup('a', roles: {'p1': 'member'}));
      final list = await repo.startupsOf(_person(['a', 'missing']));
      expect(list.map((r) => r.id), ['a']);
    });

    test('the startup the profile was opened from is checked too', () async {
      startups.startups.add(_startup('a', roles: {'p1': 'member'}));
      final list = await repo.startupsOf(_person([]), alsoCheck: 'a');
      expect(list.single.id, 'a');
    });
  });
}
